class_name Effect
extends Resource
## A timed buff or curse. Duration counts down at the start of the owner's turn.

enum Mode { ADD, SET, MULTIPLY }

@export var display_name: String = "Effect"
@export_multiline var description: String = ""
@export var duration: int = 3          ## the owner's turns
@export var is_curse: bool = false     ## purely cosmetic for now
@export var color: Color = Color(0.5, 0.85, 1.0)

## stat name -> amount. Names must match Stats.NAMES.
@export var modifiers: Dictionary = {}
@export var mode: Mode = Mode.ADD


## Apply this effect's contribution to a stat's running value.
func apply_to(stat_name: String, value: int) -> int:
	print("apply_to ", stat_name, " keys=", modifiers.keys(), " has=", modifiers.has(stat_name))
	if not modifiers.has(stat_name):
		return value
	var amount = modifiers[stat_name]
	match mode:
		Mode.SET:
			return int(amount)
		Mode.MULTIPLY:
			return int(value * float(amount))
		_:
			return value + int(amount)
