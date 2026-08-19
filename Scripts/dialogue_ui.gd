extends CanvasLayer

signal closed

@export_file("*.tscn") var battle_scene_path: String = "res://scenes/worlds/battle_field.tscn"

@onready var name_label: Label = $Panel/Margin/VBox/NameLabel
@onready var text_label: Label = $Panel/Margin/VBox/TextLabel
@onready var options: VBoxContainer = $Panel/Margin/VBox/Options

var player: Node = null
var current_npc = null

func _ready() -> void:
	hide_dialogue()
	Game.player_spawned.connect(_on_player_spawned)
	if Game.player != null:
		_on_player_spawned(Game.player)


func _on_player_spawned(new_player: Node) -> void:
	player = new_player
	if not player.interacted.is_connected(open):
		player.interacted.connect(open)
	current_npc = null
	hide_dialogue()

func open(npc) -> void:
	current_npc = npc
	name_label.text = npc.display_name
	text_label.text = npc.greeting
	_refresh(true)
	$Panel.show()

func hide_dialogue() -> void:
	$Panel.hide()

func _refresh(include_greeting: bool) -> void:
	var list: Array = []

	if include_greeting:
		list.append({"label": "Hi", "action": _on_hi})

	if current_npc != null and current_npc.is_ally():
		if current_npc.is_following():
			list.append({"label": "Wait here", "action": _on_stop_follow})
		else:
			list.append({"label": "Follow me", "action": _on_follow})

	if current_npc != null and current_npc.is_enemy() and not Game.in_battle():
		list.append({"label": "Fight!", "action": _on_fight})

	if Game.in_battle():
		list.append({"label": "Flee the battle", "action": _on_flee})

	list.append({"label": "Exit", "action": _on_exit})
	_build_options(list)
func _build_options(list: Array) -> void:
	for child in options.get_children():
		child.queue_free()
	var number: int = 1
	for entry in list:
		var button := Button.new()
		button.text = "%d. %s" % [number, entry["label"]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(entry["action"])
		options.add_child(button)
		number += 1

func _on_hi() -> void:
	text_label.text = current_npc.response
	_refresh(false)

func _on_follow() -> void:
	current_npc.start_following(player)
	text_label.text = "Lead the way."
	_refresh(false)

func _on_stop_follow() -> void:
	current_npc.stop_following()
	text_label.text = "I'll wait right here."
	_refresh(false)

func _on_fight() -> void:
	var npc = current_npc
	_on_exit()
	Game.start_battle(battle_scene_path, npc)

func _on_flee() -> void:
	_on_exit()
	Game.end_battle.call_deferred()

func _on_exit() -> void:
	current_npc = null
	hide_dialogue()
	if player:
		player.dialogue_open = false
	closed.emit()
