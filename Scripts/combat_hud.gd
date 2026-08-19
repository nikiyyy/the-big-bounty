extends Control

@onready var turn_label: Label = $Panel/Margin/HBox/TurnLabel
@onready var move_label: Label = $Panel/Margin/HBox/MoveLabel
@onready var end_turn_button: Button = $Panel/Margin/HBox/EndTurnButton
@onready var flee_button: Button = $Panel/Margin/HBox/FleeButton

var combat: Combat = null


func _ready() -> void:
	hide()
	end_turn_button.pressed.connect(_on_end_turn_pressed)
	flee_button.pressed.connect(_on_flee_pressed)

func bind(new_combat: Combat) -> void:
	combat = new_combat
	combat.turn_changed.connect(_on_turn_changed)
	combat.movement_changed.connect(_on_movement_changed)
	_on_turn_changed(combat.turn_number, combat.is_player_turn)
	_on_movement_changed(combat.movement_left, combat.movement_per_turn)
	show()


func _on_turn_changed(turn_number: int, is_player_turn: bool) -> void:
	turn_label.text = "Turn %d — %s" % [turn_number, "You" if is_player_turn else "Enemy"]
	end_turn_button.disabled = not is_player_turn


func _on_movement_changed(remaining: int, maximum: int) -> void:
	move_label.text = "Movement: %d / %d" % [remaining, maximum]


func _on_end_turn_pressed() -> void:
	if combat != null:
		combat.end_player_turn()
		
func _on_flee_pressed() -> void:
	Game.end_battle.call_deferred()
