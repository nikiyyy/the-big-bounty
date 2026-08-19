extends Camera3D

@export var follow_speed: float = 5.0

@export_group("Framing")
@export var start_yaw_degrees: float = 45.0
@export var start_pitch_degrees: float = 45.0
@export var start_distance: float = 18.0

@export_group("Zoom")
@export var zoom_step: float = 2.0
@export var zoom_speed: float = 8.0
@export var min_distance: float = 6.0
@export var max_distance: float = 40.0

@export_group("Rotation")
@export var rotate_sensitivity: float = 0.006
@export var min_pitch_degrees: float = 12.0
@export var max_pitch_degrees: float = 82.0
@export var invert_x: bool = false
@export var invert_y: bool = false

var target: Node3D = null
var yaw: float
var pitch: float
var distance: float
var desired_distance: float
var is_rotating: bool = false


func _ready() -> void:
	yaw = deg_to_rad(start_yaw_degrees)
	pitch = deg_to_rad(start_pitch_degrees)
	distance = start_distance
	desired_distance = start_distance
	Game.player_spawned.connect(_on_player_spawned)


func _on_player_spawned(new_player: Node) -> void:
	target = new_player as Node3D
	current = true
	snap_to_target()


func snap_to_target() -> void:
	if target == null or not is_instance_valid(target):
		return
	global_position = target.global_position + _orbit_direction() * distance
	look_at(target.global_position, Vector3.UP)


func _orbit_direction() -> Vector3:
	return Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))


func _unhandled_input(event: InputEvent) -> void:
	if not current:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			desired_distance = clampf(desired_distance - zoom_step, min_distance, max_distance)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			desired_distance = clampf(desired_distance + zoom_step, min_distance, max_distance)

	elif event is InputEventMouseMotion and is_rotating:
		var motion: Vector2 = event.relative

		var horizontal: float = motion.x * rotate_sensitivity
		yaw += -horizontal if invert_x else horizontal

		var vertical: float = motion.y * rotate_sensitivity
		pitch += vertical if invert_y else -vertical
		pitch = clampf(pitch, deg_to_rad(min_pitch_degrees), deg_to_rad(max_pitch_degrees))


func _physics_process(delta: float) -> void:
	if not current:
		return
		
	if target == null or not is_instance_valid(target):
		return
	distance = lerp(distance, desired_distance, zoom_speed * delta)
	var desired_pos: Vector3 = target.global_position + _orbit_direction() * distance
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	look_at(target.global_position, Vector3.UP)
