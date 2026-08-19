extends Node3D

@export_file("*.tscn") var starting_world: String = "res://scenes/worlds/overworld_village.tscn"


func _ready() -> void:
	Game.register_world_root($WorldRoot)
	Game.load_world(starting_world)
