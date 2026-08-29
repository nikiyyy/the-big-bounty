class_name Item
extends Resource

enum Slot { MAIN_HAND, OFF_HAND, RANGED, NONE }

@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export var slot: Slot = Slot.NONE
@export var armor_bonus: int = 0
@export var damage_bonus: int = 0
@export var value: int = 0
@export var stack_size: int = 1
