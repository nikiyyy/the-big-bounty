class_name Inventory
extends Resource
## Backpack plus three equipment slots. Owned by any unit that can carry things.

signal inventory_changed

const SLOT_LABELS := {
	Item.Slot.MAIN_HAND: "Main hand",
	Item.Slot.OFF_HAND: "Off hand",
	Item.Slot.RANGED: "Ranged",
}

const SLOT_ORDER := [Item.Slot.MAIN_HAND, Item.Slot.OFF_HAND, Item.Slot.RANGED]

@export var capacity: int = 18
@export var items: Array[Item] = []
@export var equipped: Dictionary = {}      # Item.Slot -> Item


func is_full() -> bool:
	return items.size() >= capacity


func add(item: Item) -> bool:
	if item == null or is_full():
		return false
	items.append(item)
	changed.emit()
	return true


func remove(item: Item) -> bool:
	var i: int = items.find(item)
	if i < 0:
		return false
	items.remove_at(i)
	changed.emit()
	return true


func equip(item: Item) -> bool:
	if item == null or item.slot == Item.Slot.NONE:
		return false
	unequip(item.slot)
	items.erase(item)
	equipped[item.slot] = item
	changed.emit()
	return true


func unequip(slot: int) -> bool:
	var current = equipped.get(slot)
	if current == null:
		return false
	equipped.erase(slot)
	if not is_full():
		items.append(current)
	changed.emit()
	return true


func get_equipped(slot: int) -> Item:
	return equipped.get(slot)


func total_armor() -> int:
	var total: int = 0
	for item in equipped.values():
		total += item.armor_bonus
	return total


func total_damage_bonus() -> int:
	var total: int = 0
	for item in equipped.values():
		total += item.damage_bonus
	return total
