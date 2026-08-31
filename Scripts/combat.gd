class_name Combat
extends Node
## Turn order over a list of combatants. Knows nothing about the grid — the
## battle map supplies budgets and runs AI turns through two callables.

signal turn_changed(unit, round_number: int, player_controlled: bool)
signal movement_changed(remaining: int, maximum: int)
signal order_changed(order: Array)
signal actions_changed(remaining: int)

var initiative: Dictionary = {}      # unit -> rolled score
var order: Array = []
var index: int = -1
var round_number: int = 1
var active = null
var movement_left: int = 0
var movement_max: int = 0
var actions_left: int = 0

## Set by the battle map.
var budget_for: Callable = Callable()
var ai_phase: Callable = Callable()
var is_player_side: Callable = Callable()


func setup(units: Array) -> void:
	order = units.duplicate()
	roll_initiative()

## Everyone rolls d20 + haste. Rerolled at the top of each round.
func roll_initiative() -> void:
	initiative.clear()
	for unit in order:
		if not is_instance_valid(unit):
			continue
		var haste: int = 0
		if "stats" in unit and unit.stats != null:
			haste = unit.stats.haste
		var roll: int = randi_range(1, 20)
		# fractional tiebreak so equal totals still get a stable, random order
		initiative[unit] = float(roll + haste) + randf() * 0.001

	order.sort_custom(func(a, b): return initiative.get(a, 0.0) > initiative.get(b, 0.0))
	order_changed.emit(order)

func begin() -> void:
	index = -1
	round_number = 1
	_print_order()
	_advance()

func _print_order() -> void:
	print("--- Initiative, round %d ---" % round_number)
	for unit in order:
		if is_instance_valid(unit) and (not unit.has_method("is_alive") or unit.is_alive()):
			print("  %s: %d" % [_label(unit), int(initiative.get(unit, 0.0))])
			
func player_controlled() -> bool:
	if active == null or not is_player_side.is_valid():
		return false
	return is_player_side.call(active)


func can_afford(cost: int) -> bool:
	return player_controlled() and cost <= movement_left


func spend(cost: int) -> void:
	movement_left = maxi(0, movement_left - cost)
	movement_changed.emit(movement_left, movement_max)


func end_turn() -> void:
	_advance()


func _advance() -> void:
	_prune()
	if order.is_empty():
		return

	var attempts: int = 0
	while attempts <= order.size():
		index += 1
		if index >= order.size():
			index = 0
			round_number += 1
		if _is_alive(order[index]):
			break
		attempts += 1
	if attempts > order.size():
		return          # everyone's down

	active = order[index]
	movement_max = int(budget_for.call(active)) if budget_for.is_valid() else 0
	movement_left = movement_max

	actions_left = 1
	actions_changed.emit(actions_left)

	print("--- Round %d: %s (%d hexes) ---" % [round_number, _label(active), movement_max])
	turn_changed.emit(active, round_number, player_controlled())
	movement_changed.emit(movement_left, movement_max)

	if not player_controlled() and ai_phase.is_valid():
		await ai_phase.call(active)
		if active == order[index]:
			_advance()


func _prune() -> void:
	var kept: Array = []
	for u in order:
		if is_instance_valid(u):
			kept.append(u)
	if kept.size() != order.size():
		order = kept
		order_changed.emit(order)


func _label(unit) -> String:
	if unit != null and "display_name" in unit:
		return unit.display_name
	return "Player"
	
func can_act() -> bool:
	return player_controlled() and actions_left > 0

func spend_action() -> void:
	actions_left = maxi(0, actions_left - 1)
	actions_changed.emit(actions_left)

func _is_alive(unit) -> bool:
	if not is_instance_valid(unit):
		return false
	if unit.has_method("is_alive"):
		return unit.is_alive()
	return true
