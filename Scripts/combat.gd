class_name Combat
extends Node
## Owns turn state for one battle. Created by the battle map, dies with it.

signal turn_changed(turn_number: int, is_player_turn: bool)
signal movement_changed(remaining: int, maximum: int)

var movement_per_turn: int = 5
var turn_number: int = 1
var is_player_turn: bool = true
var movement_left: int = 5
var enemy_phase: Callable = Callable()

func begin() -> void:
	turn_number = 1
	is_player_turn = true
	movement_left = movement_per_turn
	print("--- Turn %d: your move (%d hexes) ---" % [turn_number, movement_left])
	turn_changed.emit(turn_number, true)
	movement_changed.emit(movement_left, movement_per_turn)


func can_afford(cost: int) -> bool:
	return is_player_turn and cost <= movement_left


func spend(cost: int) -> void:
	movement_left = maxi(0, movement_left - cost)
	print("Moved %d hex(es) — %d/%d left" % [cost, movement_left, movement_per_turn])
	movement_changed.emit(movement_left, movement_per_turn)


func end_player_turn() -> void:
	if not is_player_turn:
		return
	is_player_turn = false
	turn_changed.emit(turn_number, false)

	if enemy_phase.is_valid():
		await enemy_phase.call()
	else:
		await get_tree().create_timer(0.6).timeout

	turn_number += 1
	is_player_turn = true
	movement_left = movement_per_turn
	print("--- Turn %d: your move (%d hexes) ---" % [turn_number, movement_left])
	turn_changed.emit(turn_number, true)
	movement_changed.emit(movement_left, movement_per_turn)
