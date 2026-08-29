extends CharacterBody3D

signal interacted(npc)
signal health_changed(current: int, maximum: int)
signal died
signal gold_changed(amount: int)
signal xp_changed(amount: int)
signal armor_changed(value: int)

@export var speed: float = 5.0
@export var interaction_range: float = 2.0
@export var stats: Stats
@export var display_name: String = "Hero"
@export var gold: int = 0
@export var xp: int = 0
@export var level: int = 1
@export var base_armor: int = 0
@export var inventory: Inventory

var target_position: Vector3
var interaction_target = null
var dialogue_open: bool = false
var current_health: int = 0
var _waypoints: Array = []


func _ready() -> void:
	stats = stats.duplicate() if stats != null else Stats.new()
	stats.changed_stat.connect(_on_stat_raised)
	inventory = inventory.duplicate(true) if inventory != null else Inventory.new()
	current_health = max_health()
	target_position = global_position


func teleport_to(where: Vector3) -> void:
	global_position = where
	target_position = where
	interaction_target = null
	_waypoints.clear()
	velocity = Vector3.ZERO


func _physics_process(delta: float) -> void:
	if not is_alive():
		return
	var to_target: Vector3 = target_position - global_position
	to_target.y = 0.0

	if to_target.length() > 0.15:
		var dir: Vector3 = to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(global_position + dir, Vector3.UP)
	elif not _waypoints.is_empty():
		target_position = _waypoints.pop_front()
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	_check_arrival()


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_open:
		return
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from: Vector3 = cam.project_ray_origin(event.position)
	var to: Vector3 = from + cam.project_ray_normal(event.position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.has("position"):
		return

	var actor = _active_actor()
	if actor == null:
		return

	var collider = hit.get("collider")
	if collider != null and collider.has_method("get_faction"):
		var world := Game.current_world
		if world != null and world.has_method("request_attack"):
			world.request_attack(actor, collider)
		elif actor == self:
			_approach(collider)
		return

	var path = _request_path(actor, hit["position"])
	if path != null and not path.is_empty():
		actor.walk_path(path)


## In battle, clicks command whoever's turn it is. Outside battle, us.
func _active_actor():
	var world := Game.current_world
	if world != null and world.has_method("get_controlled_unit"):
		return world.get_controlled_unit()
	return self


func _request_path(actor, point: Vector3):
	var world := Game.current_world
	if world != null and world.has_method("request_move"):
		return world.request_move(actor, point)
	return [point]


func walk_path(points: Array) -> void:
	_begin_path(points)


func _begin_path(path) -> bool:
	if path == null or path.is_empty():
		return false
	_waypoints = path.duplicate()
	target_position = _waypoints.pop_front()
	return true


func _approach(npc) -> void:
	var away: Vector3 = global_position - npc.global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.FORWARD
	var stand_at: Vector3 = npc.global_position + away.normalized() * (interaction_range * 0.85)

	if _begin_path(_request_path(self, stand_at)):
		interaction_target = npc


func _check_arrival() -> void:
	if interaction_target == null:
		return
	if not is_instance_valid(interaction_target):
		interaction_target = null
		return

	var a: Vector3 = global_position
	var b: Vector3 = interaction_target.global_position
	var flat_distance: float = Vector2(a.x - b.x, a.z - b.z).length()
	if flat_distance > interaction_range:
		return

	var npc = interaction_target
	interaction_target = null
	target_position = global_position
	_face(b)

	dialogue_open = true
	interacted.emit(npc)


func _face(point: Vector3) -> void:
	var flat := Vector3(point.x, global_position.y, point.z)
	if flat.distance_to(global_position) > 0.01:
		look_at(flat, Vector3.UP)

func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)
	gold_changed.emit(gold)


func add_xp(amount: int) -> void:
	xp = maxi(0, xp + amount)
	xp_changed.emit(xp)

func _on_stat_raised(stat_name: String) -> void:
	if stat_name == "health":
		current_health += 1
		health_changed.emit(current_health, max_health())

func save_state() -> Dictionary:
	return {
		"stats": stats,
		"health": current_health,
		"gold": gold,
		"xp": xp,
		"level": level,
		"base_armor": base_armor,
		"inventory": inventory,
	}

func load_state(data: Dictionary) -> void:
	if data.get("stats") != null:
		stats = data["stats"]
		if not stats.changed_stat.is_connected(_on_stat_raised):
			stats.changed_stat.connect(_on_stat_raised)
	if data.get("inventory") != null:
		inventory = data["inventory"]
	current_health = data.get("health", max_health())
	gold = data.get("gold", 0)
	xp = data.get("xp", 0)
	level = data.get("level", 1)
	base_armor = data.get("base_armor", 0)
	health_changed.emit(current_health, max_health())
	gold_changed.emit(gold)
	xp_changed.emit(xp)
	armor_changed.emit(armor())

## Total armor: innate plus whatever equipment adds.
func armor() -> int:
	return base_armor + equipment_armor()


func equipment_armor() -> int:
	return inventory.total_armor() if inventory != null else 0


func add_armor(amount: int) -> void:
	base_armor = maxi(0, base_armor + amount)
	armor_changed.emit(armor())

# ---------------------------------------------------------------- health

func max_health() -> int:
	return stats.health if stats != null else 1

func take_damage(amount: int) -> void:
	if current_health <= 0:
		return
	current_health = maxi(0, current_health - amount)
	health_changed.emit(current_health, max_health())
	if current_health == 0:
		_die()

func _die() -> void:
	velocity = Vector3.ZERO
	rotation.x = deg_to_rad(-90.0)
	set_collision_layer_value(2, false)
	set_collision_mask_value(2, false)
	$CollisionShape3D.set_deferred("disabled", true)
	died.emit()

func heal(amount: int) -> void:
	current_health = mini(max_health(), current_health + amount)
	health_changed.emit(current_health, max_health())

func is_alive() -> bool:
	return current_health > 0
