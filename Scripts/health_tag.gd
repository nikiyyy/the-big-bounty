class_name HealthTag
extends Label3D
## Camera-facing health number in a small box, hanging under a unit.

const Y_OFFSET := 0.1

const COLOR_ALLY := Color(0.55, 0.95, 0.62)
const COLOR_ENEMY := Color(1.0, 0.55, 0.55)
const COLOR_NEUTRAL := Color(0.98, 0.9, 0.55)

var _unit: Node = null


static func attach(unit: Node3D) -> void:
	if unit == null or unit.has_node("HealthTag"):
		return
	var tag := HealthTag.new()
	tag.name = "HealthTag"
	unit.add_child(tag)
	tag.bind(unit)


func _ready() -> void:
	position.y = Y_OFFSET
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fixed_size = true          # same pixel size regardless of zoom
	pixel_size = 0.0003
	font_size = 96
	outline_size = 26
	outline_modulate = Color(0.04, 0.04, 0.06, 0.92)
	no_depth_test = true
	shaded = false
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func bind(unit: Node) -> void:
	_unit = unit
	if unit.has_signal("health_changed"):
		unit.health_changed.connect(_on_health_changed)

	if unit.has_method("is_enemy") and unit.is_enemy():
		modulate = COLOR_ENEMY
	elif unit.has_method("is_ally") and unit.is_ally():
		modulate = COLOR_ALLY
	elif unit.has_method("get_faction"):
		modulate = COLOR_NEUTRAL
	else:
		modulate = COLOR_ALLY          # the player has no faction method

	var maximum: int = unit.max_health() if unit.has_method("max_health") else 1
	var current: int = unit.current_health if "current_health" in unit else maximum
	_on_health_changed(current, maximum)


func _on_health_changed(current: int, maximum: int) -> void:
	text = "%d / %d" % [current, maximum]
