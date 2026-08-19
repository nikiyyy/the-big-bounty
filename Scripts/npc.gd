@tool
class_name NPC
extends CharacterBody3D

enum Faction { ALLY, ENEMY, NEUTRAL }

const FACTION_COLORS := {
	Faction.ALLY: Color(0.25, 0.8, 0.35),
	Faction.ENEMY: Color(0.85, 0.2, 0.2),
	Faction.NEUTRAL: Color(0.9, 0.8, 0.2),
}

@export var faction: Faction = Faction.NEUTRAL:
	set(value):
		faction = value
		_apply_color()

@export var display_name: String = "NPC"
@export_multiline var greeting: String = "Hello there, traveller."
@export_multiline var response: String = "Nice weather we're having."

@export_group("Follow")
@export var move_speed: float = 5.5
@export var follow_distance: float = 3.0
@export var stop_buffer: float = 0.8

var follow_target: Node3D = null
var _walking: bool = false

func _ready() -> void:
	_apply_color()

func _apply_color() -> void:
	if not is_node_ready():
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FACTION_COLORS[faction]
	$MeshInstance3D.material_override = mat

func get_faction() -> Faction:
	return faction

func is_ally() -> bool:
	return faction == Faction.ALLY

func is_enemy() -> bool:
	return faction == Faction.ENEMY
# ------------------------------------------------------------------ follow

func start_following(who: Node3D) -> void:
	follow_target = who

func stop_following() -> void:
	follow_target = null
	_walking = false
	velocity = Vector3.ZERO

func is_following() -> bool:
	return follow_target != null and is_instance_valid(follow_target)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if not is_following():
		follow_target = null
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var to_target: Vector3 = follow_target.global_position - global_position
		to_target.y = 0.0
		var dist: float = to_target.length()

		# hysteresis: start walking past follow_distance, stop once well inside
		if dist > follow_distance:
			_walking = true
		elif dist < follow_distance - stop_buffer:
			_walking = false

		if _walking and dist > 0.01:
			var dir: Vector3 = to_target.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			look_at(global_position + dir, Vector3.UP)
		else:
			velocity.x = 0.0
			velocity.z = 0.0

	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	
func to_battle_data() -> Dictionary:
	return {
		"display_name": display_name,
		"faction": faction,
	}

func save_state() -> Dictionary:
	return {
		"position": global_position,
		"rotation_y": rotation.y,
		"following": is_following(),
	}

func load_state(data: Dictionary) -> void:
	global_position = data.get("position", global_position)
	rotation.y = data.get("rotation_y", rotation.y)
	if data.get("following", false) and Game.player != null:
		start_following(Game.player)
