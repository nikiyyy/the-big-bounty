class_name Spell
extends Resource
## A targeted spell. Radius 0 hits one hex; radius 1 hits a hex and its six
## neighbours, and so on.

@export var display_name: String = "Spell"
@export_multiline var description: String = ""
@export var mana_cost: int = 3
@export var cast_range: int = 6        ## hexes from the caster
@export var radius: int = 1            ## blast size around the target hex
@export var damage_min: int = 2
@export var damage_max: int = 5
@export var hits_allies: bool = true   ## Heroes 3 style — friendly fire is real


func roll_damage() -> int:
	if damage_max <= damage_min:
		return damage_min
	return randi_range(damage_min, damage_max)
