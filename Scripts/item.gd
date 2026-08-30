class_name Item
extends Resource

enum Slot { MAIN_HAND, OFF_HAND, RANGED, NONE }
enum Kind { WEAPON, ARMOR, CONSUMABLE, MISC }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum Hands { ONE_HANDED, TWO_HANDED }

const RARITY_COLORS := {
	Rarity.COMMON: Color(0.75, 0.75, 0.72),
	Rarity.UNCOMMON: Color(0.35, 0.8, 0.4),
	Rarity.RARE: Color(0.3, 0.6, 0.95),
	Rarity.EPIC: Color(0.7, 0.4, 0.9),
	Rarity.LEGENDARY: Color(0.95, 0.7, 0.2),
}

@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var kind: Kind = Kind.MISC
@export var slot: Slot = Slot.NONE
@export var rarity: Rarity = Rarity.COMMON
@export var value: int = 0

@export_group("Weapon")
@export var hands: Hands = Hands.ONE_HANDED
@export var damage_min: int = 0
@export var damage_max: int = 0
@export var reach: int = 1          ## hexes; 1 = must be adjacent

@export_group("Armor")
@export var armor_bonus: int = 0


func is_weapon() -> bool:
	return kind == Kind.WEAPON


## One damage roll from this weapon, before the wielder's strength.
func roll_damage() -> int:
	if damage_max <= damage_min:
		return damage_min
	return randi_range(damage_min, damage_max)


func rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, RARITY_COLORS[Rarity.COMMON])


func tooltip() -> String:
	var lines: Array = [display_name]
	if is_weapon():
		lines.append("%d–%d damage, reach %d" % [damage_min, damage_max, reach])
	if armor_bonus > 0:
		lines.append("+%d armor" % armor_bonus)
	lines.append("%d gold" % value)
	return "\n".join(lines)
