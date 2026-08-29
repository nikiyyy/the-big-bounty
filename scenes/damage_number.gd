class_name DamageNumber
extends Label3D
## Floating combat text. Spawns above a unit, drifts up, fades, frees itself.

const RISE := 1.1          # metres travelled over its lifetime
const LIFETIME := 0.9
const DRIFT := 0.35        # sideways scatter so stacked hits stay readable

const COLOR_DAMAGE := Color(1.0, 0.45, 0.4)
const COLOR_HEAL := Color(0.5, 0.95, 0.55)
const COLOR_BLOCKED := Color(0.75, 0.75, 0.8)


static func spawn(unit: Node3D, amount: int, kind: String = "damage") -> void:
	if unit == null or not is_instance_valid(unit):
		return

	var label := DamageNumber.new()
	label.text = "+%d" % amount if kind == "heal" else str(amount)

	match kind:
		"heal":
			label.modulate = COLOR_HEAL
		"blocked":
			label.modulate = COLOR_BLOCKED
		_:
			label.modulate = COLOR_DAMAGE

	# parented to the world, not the unit — otherwise it rides along if the
	# unit walks away, or vanishes early when the unit is freed
	unit.get_parent().add_child(label)
	label.global_position = unit.global_position + Vector3(
		randf_range(-DRIFT, DRIFT), 1.6, randf_range(-DRIFT, DRIFT)
	)
	label.animate()


func _init() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fixed_size = true
	pixel_size = 0.0006
	font_size = 96
	outline_size = 22
	outline_modulate = Color(0.03, 0.03, 0.05, 0.9)
	no_depth_test = true
	shaded = false
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func animate() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position:y", global_position.y + RISE, LIFETIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
