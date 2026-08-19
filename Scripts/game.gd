extends Node

signal world_loaded(world: Node)
signal player_spawned(player: Node)
signal battle_started(battle: Node)
signal battle_ended

const PLAYER_SCENE_PATH := "res://scenes/player.tscn"

var world_root: Node = null
var current_world: Node = null
var player: Node = null
var _in_battle: bool = false
var _return_world_path: String = ""
var _return_position: Vector3 = Vector3.ZERO
var _world_states: Dictionary = {}

func register_world_root(node: Node) -> void:
	world_root = node


func load_world(scene_path: String) -> void:
	if world_root == null:
		push_error("Game: world_root not registered — did main.gd run?")
		return

	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_error("Game: could not load world at %s" % scene_path)
		return

	_free_current_world()

	current_world = packed.instantiate()
	world_root.add_child(current_world)

	# give the new world one frame to finish its own _ready()
	await get_tree().process_frame

	_spawn_player(current_world)
	_restore_state(current_world)
	world_loaded.emit(current_world)


func _free_current_world() -> void:
	player = null
	if current_world == null:
		return

	# snapshot before it disappears
	_world_states[current_world.scene_file_path] = _capture_state(current_world)

	world_root.remove_child(current_world)
	current_world.queue_free()
	current_world = null
	
func _spawn_player(world: Node) -> void:
	var packed: PackedScene = load(PLAYER_SCENE_PATH)
	if packed == null:
		push_error("Game: no player scene at %s" % PLAYER_SCENE_PATH)
		return

	player = packed.instantiate()
	world.add_child(player)
	player.global_position = _find_spawn(world)
	if player.has_method("teleport_to"):
		player.teleport_to(player.global_position)
	player_spawned.emit(player)

func _find_spawn(world: Node) -> Vector3:
	# worlds that generate themselves compute spawns in code
	if world.has_method("get_spawn_position"):
		return world.get_spawn_position("PlayerSpawn")
	var marker := world.get_node_or_null("PlayerSpawn")
	if marker is Node3D:
		return marker.global_position
	push_warning("No PlayerSpawn in %s — using origin" % world.name)
	return Vector3.ZERO

func in_battle() -> bool:
	return _in_battle


func start_battle(battle_scene_path: String, enemy_source: Node) -> void:
	if _in_battle or current_world == null:
		return

	# remember how to get back
	_return_world_path = current_world.scene_file_path
	_return_position = player.global_position

	var enemy_data: Dictionary = {}
	if enemy_source and enemy_source.has_method("to_battle_data"):
		enemy_data = enemy_source.to_battle_data()

	_in_battle = true
	await load_world(battle_scene_path)

	if current_world.has_method("setup_battle"):
		current_world.setup_battle(player, enemy_data)
	battle_started.emit(current_world)


func end_battle() -> void:
	if not _in_battle:
		return
	_in_battle = false

	await load_world(_return_world_path)
	player.global_position = _return_position
	if player.has_method("teleport_to"):
		player.teleport_to(_return_position)

	battle_ended.emit()
	
func _capture_state(world: Node) -> Dictionary:
	var data: Dictionary = {}
	_walk_save(world, world, data)
	return data


func _walk_save(world: Node, node: Node, data: Dictionary) -> void:
	for child in node.get_children():
		if child.has_method("save_state"):
			data[String(world.get_path_to(child))] = child.save_state()
		_walk_save(world, child, data)


func _restore_state(world: Node) -> void:
	var data: Dictionary = _world_states.get(world.scene_file_path, {})
	for path in data.keys():
		var node := world.get_node_or_null(NodePath(path))
		if node and node.has_method("load_state"):
			node.load_state(data[path])
