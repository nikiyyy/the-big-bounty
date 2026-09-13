class_name Damage
extends RefCounted
## Central damage maths. Everything that deals damage routes through here.

## Tuned so 100 armor = 75% reduction. Raise it to make armor weaker.
const ARMOR_CONSTANT := 33.333333


## Fraction of incoming damage that gets through, 0.25 at 100 armor.
static func multiplier(armor: int) -> float:
	if armor <= 0:
		return 1.0
	return ARMOR_CONSTANT / (ARMOR_CONSTANT + float(armor))


## Damage after armor, rounded up, never below 1 for a hit that connected.
static func apply_armor(raw: int, armor: int) -> int:
	if raw <= 0:
		return 0
	return maxi(1, int(ceil(raw * multiplier(armor))))


static func armor_of(unit) -> int:
	return unit.armor() if unit != null and unit.has_method("armor") else 0
