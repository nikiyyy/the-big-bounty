class_name DamageType
extends RefCounted
## The damage taxonomy. Physical types are reduced by armor; elemental types
## are reduced by their matching resistance.

enum Kind {
	SLASHING,
	PIERCING,
	BLUNT,
	FIRE,
	FROST,
	NATURE,
	LIGHTNING,
}

const LABELS := {
	Kind.SLASHING: "Slashing",
	Kind.PIERCING: "Piercing",
	Kind.BLUNT: "Blunt",
	Kind.FIRE: "Fire",
	Kind.FROST: "Frost",
	Kind.NATURE: "Nature",
	Kind.LIGHTNING: "Lightning",
}

const COLORS := {
	Kind.SLASHING: Color(0.85, 0.85, 0.88),
	Kind.PIERCING: Color(0.75, 0.80, 0.88),
	Kind.BLUNT: Color(0.72, 0.68, 0.62),
	Kind.FIRE: Color(1.00, 0.45, 0.20),
	Kind.FROST: Color(0.45, 0.80, 1.00),
	Kind.NATURE: Color(0.45, 0.85, 0.40),
	Kind.LIGHTNING: Color(0.95, 0.85, 0.35),
}

## The four elements, in the order resistances are displayed.
const ELEMENTS := [Kind.FIRE, Kind.FROST, Kind.NATURE, Kind.LIGHTNING]

const PHYSICAL := [Kind.SLASHING, Kind.PIERCING, Kind.BLUNT]


static func label(kind: int) -> String:
	return LABELS.get(kind, "Unknown")


static func color(kind: int) -> Color:
	return COLORS.get(kind, Color.WHITE)


static func is_physical(kind: int) -> bool:
	return PHYSICAL.has(kind)


static func is_elemental(kind: int) -> bool:
	return ELEMENTS.has(kind)
