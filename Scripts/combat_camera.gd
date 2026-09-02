extends Camera3D
## Free RTS-style camera. Orbits a focus point in space, not a character.

@export_group("Framing")
@export var start_yaw_degrees: float = 45.0
@export var start_pitch_degrees: float = 50.0
@export var start_distance: float = 22.0

@export_group("Pan")
@export var pan_speed: float = 26.0
@export var edge_margin: float = 28.0
@export var edge_scroll_enabled: bool = true

@export_group("Zoom")
@export var zoom_step: float = 2.5
@export var zoom_speed: float = 8.0
@export var min_distance: float = 8.0
@export var max_distance: float = 55.0

@export_group("Rotation")
@export var rotate_sensitivity: float = 0.006
@export var min_pitch_degrees: float = 15.0
@export var max_pitch_degrees: float = 80.0
@export var invert_x: bool = false
@export var invert_y: bool = false

var focus: Vector3 = Vector3.ZERO
var yaw: float
var pitch: float
var distance: float
var desired_distance: float
var is_rotating: bool = false

var _bounds_min := Vector2(-INF, -INF)
var _bounds_max := Vector2(INF, INF)


func _ready() -> void:
	yaw = deg_to_rad(start_yaw_degrees)
	pitch = deg_to_rad(start_pitch_degrees)
	distance = start_distance
	desired_distance = start_distance
	current = true
	_apply_transform()


## Called by the battle map so panning can't leave the grid behind.
func set_bounds(min_xz: Vector2, max_xz: Vector2) -> void:
	_bounds_min = min_xz
	_bounds_max = max_xz


func focus_on(point: Vector3) -> void:
	focus = point
	_clamp_focus()
	_apply_transform()


func _orbit_direction() -> Vector3:
	return Vector3(cos(pitch) * sin(yaw), sin(pitch), cos(pitch) * cos(yaw))


func _apply_transform() -> void:
	global_position = focus + _orbit_direction() * distance
	look_at(focus, Vector3.UP)


func _clamp_focus() -> void:
	focus.x = clampf(focus.x, _bounds_min.x, _bounds_max.x)
	focus.z = clampf(focus.z, _bounds_min.y, _bounds_max.y)


func _unhandled_input(event: InputEvent) -> void:
	if not current:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_rotating = event.pressed
			Input.mouse_mode = Input.MOUSE_MODE_CONFINED if event.pressed else Input.MOUSE_MODE_VISIBLE
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


func _process(delta: float) -> void:
	if not current:
		return

	var input := _pan_input()
	if input != Vector2.ZERO:
		# pan relative to where the camera is looking, flattened onto the ground
		var forward := -global_transform.basis.z
		forward.y = 0.0
		forward = forward.normalized()
		var right := global_transform.basis.x
		right.y = 0.0
		right = right.normalized()

		focus += (right * input.x + forward * -input.y) * pan_speed * delta
		_clamp_focus()

	distance = lerp(distance, desired_distance, zoom_speed * delta)
	_apply_transform()


func _pan_input() -> Vector2:
	var input := Vector2.ZERO

	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input.x += 1.0

	# edge scrolling is meaningless while the cursor is captured for orbiting
	if edge_scroll_enabled and not is_rotating:
		var vp := get_viewport()
		var size: Vector2 = vp.get_visible_rect().size
		var mouse: Vector2 = vp.get_mouse_position()

		if mouse.x >= 0.0 and mouse.y >= 0.0 and mouse.x <= size.x and mouse.y <= size.y:
			if mouse.x < edge_margin:
				input.x -= 1.0
			elif mouse.x > size.x - edge_margin:
				input.x += 1.0
			if mouse.y < edge_margin:
				input.y -= 1.0
			elif mouse.y > size.y - edge_margin:
				input.y += 1.0

	return input.limit_length(1.0)
