class_name SelectionRing
extends MeshInstance3D
## A flat disc under the selected unit. Pulses gently so it reads as active.

const COLOR := Color(1.0, 0.85, 0.35, 0.55)
const RADIUS := 0.85
const Y_OFFSET := 0.06

var _time: float = 0.0


static func attach(unit: Node3D) -> void:
	if unit == null or unit.has_node("SelectionRing"):
		return
	var ring := SelectionRing.new()
	ring.name = "SelectionRing"
	unit.add_child(ring)


static func clear(unit: Node3D) -> void:
	if unit == null or not is_instance_valid(unit):
		return
	var ring = unit.get_node_or_null("SelectionRing")
	if ring:
		ring.queue_free()


func _ready() -> void:
	var disc := TorusMesh.new()
	disc.inner_radius = RADIUS - 0.12
	disc.outer_radius = RADIUS
	disc.rings = 24
	disc.ring_segments = 8
	mesh = disc

	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat

	position.y = Y_OFFSET
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	_time += delta
	var pulse: float = 0.4 + 0.25 * sin(_time * 3.0)
	material_override.albedo_color = Color(COLOR.r, COLOR.g, COLOR.b, pulse)
