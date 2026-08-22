extends Node3D
const HUD_SCENE_PATH := "res://scenes/combat_hud.tscn"
const COMBAT_CAMERA_PATH := "res://scenes/combat_camera.tscn"

@export var columns: int = 30
@export var rows: int = 40
@export var hex_size: float = 1.0
@export var hex_gap: float = 0.06
@export var tile_height: float = 0.15
@export var deploy_rows: int = 3
@export var movement_per_turn: int = 5

## Toggle this if tiles don't interlock. One of the two will be correct.
@export var flat_top: bool = false:
	set(value):
		flat_top = value
		if is_node_ready():
			_rebuild()

var _enemy: Node = null
var _grid: MultiMeshInstance3D
var _ground: StaticBody3D
var combat: Combat = null
var _player: Node = null
var _player_hex: Vector2i
var _enemy_hex: Vector2i
var _hud: Control = null
var _reachable: Dictionary = {}
var _camera: Camera3D = null

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if _grid:
		_grid.queue_free()
		_grid = null
	if _ground:
		_ground.queue_free()
		_ground = null
	_build_ground()
	_build_grid()

# ------------------------------------------------------------- hex geometry
# Pointy-top: neighbours are left/right, rows stagger by half a tile.
# Flat-top:   neighbours are up/down, columns stagger by half a tile.

func _grid_local(col: int, row: int) -> Vector3:
	if flat_top:
		var fx: float = hex_size * 1.5 * col
		var fz: float = hex_size * sqrt(3.0) * (row + 0.5 * (col & 1))
		return Vector3(fx, 0.0, fz)
	var x: float = hex_size * sqrt(3.0) * (col + 0.5 * (row & 1))
	var z: float = hex_size * 1.5 * row
	return Vector3(x, 0.0, z)

func _span() -> Vector2:
	if flat_top:
		return Vector2(columns * hex_size * 1.5, rows * hex_size * sqrt(3.0))
	return Vector2(columns * hex_size * sqrt(3.0), rows * hex_size * 1.5)

func _origin_offset() -> Vector3:
	var s: Vector2 = _span()
	return Vector3(-s.x * 0.5, 0.0, -s.y * 0.5)

func hex_to_local(col: int, row: int) -> Vector3:
	return _grid_local(col, row) + _origin_offset()

func hex_to_world(col: int, row: int) -> Vector3:
	return to_global(hex_to_local(col, row) + Vector3(0.0, tile_height * 0.5, 0.0))

func world_to_hex(world_pos: Vector3) -> Vector2i:
	var local: Vector3 = to_local(world_pos) - _origin_offset()
	var q: float
	var r: float
	if flat_top:
		q = (2.0 / 3.0 * local.x) / hex_size
		r = (-1.0 / 3.0 * local.x + sqrt(3.0) / 3.0 * local.z) / hex_size
	else:
		q = (sqrt(3.0) / 3.0 * local.x - 1.0 / 3.0 * local.z) / hex_size
		r = (2.0 / 3.0 * local.z) / hex_size

	var axial: Vector2 = _axial_round(Vector2(q, r))
	var col: int
	var row: int
	if flat_top:
		col = int(axial.x)
		row = int(axial.y) + int((col - (col & 1)) / 2.0)
	else:
		row = int(axial.y)
		col = int(axial.x) + int((row - (row & 1)) / 2.0)

	return Vector2i(clampi(col, 0, columns - 1), clampi(row, 0, rows - 1))


func snap_to_hex(world_pos: Vector3) -> Vector3:
	var h: Vector2i = world_to_hex(world_pos)
	return hex_to_world(h.x, h.y)


## Offset coords are convenient for storage; cube coords are what distance
## math actually needs. This converts between them.
func _offset_to_axial(h: Vector2i) -> Vector2i:
	if flat_top:
		return Vector2i(h.x, h.y - int((h.x - (h.x & 1)) / 2.0))
	return Vector2i(h.x - int((h.y - (h.y & 1)) / 2.0), h.y)


func hex_distance(a: Vector2i, b: Vector2i) -> int:
	var aa: Vector2i = _offset_to_axial(a)
	var bb: Vector2i = _offset_to_axial(b)
	var dq: int = aa.x - bb.x
	var dr: int = aa.y - bb.y
	return int((absi(dq) + absi(dq + dr) + absi(dr)) / 2.0)

func _axial_round(a: Vector2) -> Vector2:
	var x: float = a.x
	var z: float = a.y
	var y: float = -x - z
	var rx: float = roundf(x)
	var ry: float = roundf(y)
	var rz: float = roundf(z)
	var dx: float = absf(rx - x)
	var dy: float = absf(ry - y)
	var dz: float = absf(rz - z)
	if dx > dy and dx > dz:
		rx = -ry - rz
	elif dy > dz:
		ry = -rx - rz
	else:
		rz = -rx - ry
	return Vector2(rx, rz)

# ---------------------------------------------------------------- building

func _build_ground() -> void:
	var s: Vector2 = _span()
	_ground = StaticBody3D.new()
	_ground.collision_layer = 1
	_ground.collision_mask = 0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(s.x + 6.0, 1.0, s.y + 6.0)
	shape.shape = box
	shape.position = Vector3(0.0, -0.5, 0.0)
	_ground.add_child(shape)
	add_child(_ground)

func _build_grid() -> void:
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 6
	mesh.rings = 1
	mesh.height = tile_height
	mesh.top_radius = hex_size - hex_gap
	mesh.bottom_radius = hex_size - hex_gap

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.95
	mesh.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = columns * rows

	# CylinderMesh starts its first vertex at +Z, giving a pointy-top hex.
	# Flat-top needs that turned by half a segment (60/2 = 30 degrees).
	var basis := Basis(Vector3.UP, deg_to_rad(30.0)) if flat_top else Basis()

	var i: int = 0
	for row in rows:
		for col in columns:
			mm.set_instance_transform(i, Transform3D(basis, hex_to_local(col, row)))
			mm.set_instance_color(i, _tile_color(col, row))
			i += 1

	_grid = MultiMeshInstance3D.new()
	_grid.multimesh = mm
	add_child(_grid)

func _tile_color(col: int, row: int) -> Color:
	if row < deploy_rows:
		return Color(0.24, 0.42, 0.30)
	if row >= rows - deploy_rows:
		return Color(0.44, 0.24, 0.24)
	return Color(0.34, 0.34, 0.38) if (col + row) % 2 == 0 else Color(0.29, 0.29, 0.33)

# ------------------------------------------------------------ world interface

func get_spawn_position(spawn_name: String) -> Vector3:
	var mid: int = int(columns / 2)
	if spawn_name == "EnemySpawn":
		return hex_to_world(mid, rows - 2)
	return hex_to_world(mid, 1)

func setup_battle(player: Node, enemy_data: Dictionary) -> void:
	_player = player
	_player_hex = world_to_hex(player.global_position)

	var packed: PackedScene = load("res://scenes/npc.tscn")
	if packed == null:
		push_error("BattleMap: no npc.tscn at res://scenes/npc.tscn")
		return
	_enemy = packed.instantiate()
	add_child(_enemy)
	_enemy.global_position = get_spawn_position("EnemySpawn")
	_enemy.display_name = enemy_data.get("display_name", "Enemy")
	_enemy.faction = enemy_data.get("faction", NPC.Faction.ENEMY)
	_enemy_hex = world_to_hex(_enemy.global_position)
	HealthTag.attach(player)
	HealthTag.attach(_enemy)
	
	combat = Combat.new()
	combat.name = "Combat"
	combat.movement_per_turn = _movement_for(player)
	add_child(combat)
	combat.begin()
	combat.enemy_phase = _run_enemy_phase
	
	var hud_packed: PackedScene = load(HUD_SCENE_PATH)
	if hud_packed:
		_hud = hud_packed.instantiate()
		add_child(_hud)
		_hud.bind(combat)

	var cam_packed: PackedScene = load(COMBAT_CAMERA_PATH)
	if cam_packed:
		_camera = cam_packed.instantiate()
		add_child(_camera)
		var s: Vector2 = _span()
		_camera.set_bounds(
			Vector2(global_position.x - s.x * 0.5, global_position.z - s.y * 0.5),
			Vector2(global_position.x + s.x * 0.5, global_position.z + s.y * 0.5)
		)
		_camera.focus_on(player.global_position)

	combat.movement_changed.connect(_on_movement_changed)
	combat.turn_changed.connect(_on_turn_changed)
	_refresh_reachable()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			Game.end_battle()
		elif event.keycode == KEY_H and _enemy != null:
			_enemy.take_damage(3)
		
## Returns an Array of world positions to walk through, or null if refused.
func request_move(_from: Vector3, to: Vector3):
	if combat == null:
		return [snap_to_hex(to)]

	if not combat.is_player_turn:
		print("Not your turn.")
		return null

	var to_hex: Vector2i = world_to_hex(to)
	if to_hex == _player_hex:
		return null
	if is_occupied(to_hex):
		print("That hex is occupied.")
		return null

	var path: Array = find_path(_player_hex, to_hex)
	if path.is_empty():
		print("No path there.")
		return null

	var cost: int = path.size()
	if not combat.can_afford(cost):
		print("Too far — %d hexes needed, %d left." % [cost, combat.movement_left])
		return null

	_player_hex = to_hex
	combat.spend(cost)

	var waypoints: Array = []
	for h in path:
		waypoints.append(hex_to_world(h.x, h.y))
	return waypoints

const REACHABLE_TINT := Color(0.62, 0.72, 0.55)


func _on_movement_changed(_remaining: int, _maximum: int) -> void:
	_refresh_reachable()


func _on_turn_changed(_turn_number: int, _is_player_turn: bool) -> void:
	_refresh_reachable()


## Recolour every tile that changed state since the last refresh.
func _refresh_reachable() -> void:
	if _grid == null or combat == null:
		return

	var next: Dictionary = {}
	if combat.is_player_turn and combat.movement_left > 0:
		next = reachable_hexes(_player_hex, combat.movement_left)

	var mm: MultiMesh = _grid.multimesh

	# clear tiles that are no longer reachable
	for h in _reachable.keys():
		if not next.has(h):
			mm.set_instance_color(h.y * columns + h.x, _tile_color(h.x, h.y))

	# tint the new ones
	for h in next.keys():
		if not _reachable.has(h):
			mm.set_instance_color(h.y * columns + h.x, _tile_color(h.x, h.y) * REACHABLE_TINT)

	_reachable = next

func _movement_for(unit: Node) -> int:
	if unit != null and "stats" in unit and unit.stats != null:
		return unit.stats.movement_per_turn()
	return movement_per_turn

func _axial_to_offset(a: Vector2i) -> Vector2i:
	if flat_top:
		return Vector2i(a.x, a.y + int((a.x - (a.x & 1)) / 2.0))
	return Vector2i(a.x + int((a.y - (a.y & 1)) / 2.0), a.y)


## The six adjacent hexes, clipped to the grid.
func hex_neighbors(h: Vector2i) -> Array:
	const DIRS := [
		Vector2i(1, 0), Vector2i(1, -1), Vector2i(0, -1),
		Vector2i(-1, 0), Vector2i(-1, 1), Vector2i(0, 1),
	]
	var axial: Vector2i = _offset_to_axial(h)
	var out: Array = []
	for d in DIRS:
		var n: Vector2i = _axial_to_offset(axial + d)
		if n.x >= 0 and n.x < columns and n.y >= 0 and n.y < rows:
			out.append(n)
	return out


func is_occupied(h: Vector2i) -> bool:
	return h == _player_hex or h == _enemy_hex

func _run_enemy_phase() -> void:
	if _enemy == null or not is_instance_valid(_enemy) or not _enemy.is_alive_in_battle():
		await get_tree().create_timer(0.3).timeout
		return

	await get_tree().create_timer(0.35).timeout

	var brain: CombatAI = _enemy.ai if _enemy.ai != null else CombatAI.new()
	var budget: int = _movement_for(_enemy)
	var destination: Vector2i = brain.plan_move(self, _enemy_hex, _player_hex, budget)

	if destination != _enemy_hex:
		var cost: int = hex_distance(_enemy_hex, destination)
		print("%s moves %d hex(es)" % [_enemy.display_name, cost])
		_enemy_hex = destination
		_enemy.walk_to(hex_to_world(destination.x, destination.y))
		await _enemy.walk_finished

	await get_tree().create_timer(0.35).timeout

func find_path(from: Vector2i, to: Vector2i) -> Array:
	if from == to or is_occupied(to):
		return []

	var frontier: Array = [from]
	var came_from: Dictionary = {from: from}
	var cost_so_far: Dictionary = {from: 0}

	while not frontier.is_empty():
		# cheapest open node by (steps so far + estimate remaining)
		var best_i: int = 0
		var best_score: int = cost_so_far[frontier[0]] + hex_distance(frontier[0], to)
		for i in range(1, frontier.size()):
			var score: int = cost_so_far[frontier[i]] + hex_distance(frontier[i], to)
			if score < best_score:
				best_score = score
				best_i = i

		var current: Vector2i = frontier[best_i]
		frontier.remove_at(best_i)
		if current == to:
			break

		for n in hex_neighbors(current):
			if is_occupied(n):
				continue
			var next_cost: int = cost_so_far[current] + 1
			if not cost_so_far.has(n) or next_cost < cost_so_far[n]:
				cost_so_far[n] = next_cost
				came_from[n] = current
				frontier.append(n)

	if not came_from.has(to):
		return []

	var path: Array = []
	var node: Vector2i = to
	while node != from:
		path.push_front(node)
		node = came_from[node]
	return path


## Flood fill — every hex actually walkable within budget, obstacles respected.
func reachable_hexes(from: Vector2i, budget: int) -> Dictionary:
	var dist: Dictionary = {from: 0}
	var queue: Array = [from]
	var head: int = 0

	while head < queue.size():
		var current: Vector2i = queue[head]
		head += 1
		var d: int = dist[current]
		if d >= budget:
			continue
		for n in hex_neighbors(current):
			if is_occupied(n) or dist.has(n):
				continue
			dist[n] = d + 1
			queue.append(n)

	dist.erase(from)
	return dist
