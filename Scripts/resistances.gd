class_name Resistances
extends Resource
## Elemental resistance, one value per element. Behaves like armor — it comes
## from gear and innate toughness, not from spending stat points.

@export var fire: int = 0
@export var frost: int = 0
@export var nature: int = 0
@export var lightning: int = 0


func get_for(kind: int) -> int:
	match kind:
		DamageType.Kind.FIRE:
			return fire
		DamageType.Kind.FROST:
			return frost
		DamageType.Kind.NATURE:
			return nature
		DamageType.Kind.LIGHTNING:
			return lightning
		_:
			return 0


func add_for(kind: int, amount: int) -> void:
	match kind:
		DamageType.Kind.FIRE:
			fire += amount
		DamageType.Kind.FROST:
			frost += amount
		DamageType.Kind.NATURE:
			nature += amount
		DamageType.Kind.LIGHTNING:
			lightning += amount


## A copy of this plus another set, for summing gear onto innate values.
func combined(other: Resistances) -> Resistances:
	var out := Resistances.new()
	out.fire = fire + (other.fire if other != null else 0)
	out.frost = frost + (other.frost if other != null else 0)
	out.nature = nature + (other.nature if other != null else 0)
	out.lightning = lightning + (other.lightning if other != null else 0)
	return out
