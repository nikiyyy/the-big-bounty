extends CharacterBody3D

signal interacted(npc)

@export var speed: float = 5.0
@export var interaction_range: float = 2.0
@export var stats: Stats

var target_position: Vector3
var interaction_target = null
var dialogue_open: bool = false

func _ready() -> void:
	stats = stats.duplicate() if stats != null else Stats.new()
	target_position = global_position

func teleport_to(where: Vector3) -> void:
	global_position = where
	target_position = where
	interaction_target = null
	velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	var to_target: Vector3 = target_position - global_position
	to_target.y = 0.0

	if to_target.length() > 0.15:
		var dir: Vector3 = to_target.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(global_position + dir, Vector3.UP)
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
	var from: Vector3 = cam.project_ray_origin(event.position)
	var to: Vector3 = from + cam.project_ray_normal(event.position) * 1000.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.has("position"):
		return

	var collider = hit.get("collider")
	if collider != null and collider.has_method("get_faction"):
		_approach(collider)
	else:
		interaction_target = null
		var dest = _request_destination(hit["position"])
		if dest != null:
			target_position = dest

func _approach(npc) -> void:
	var away: Vector3 = global_position - npc.global_position
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3.FORWARD
	var stand_at: Vector3 = npc.global_position + away.normalized() * (interaction_range * 0.85)

	var dest = _request_destination(stand_at)
	if dest == null:
		return
	interaction_target = npc
	target_position = dest

func _check_arrival() -> void:
	if interaction_target == null:
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
		
func _request_destination(point: Vector3):
	var world := Game.current_world
	if world != null and world.has_method("request_move"):
		return world.request_move(global_position, point)
	return point
