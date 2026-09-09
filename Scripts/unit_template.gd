class_name UnitTemplate
extends Resource

@export var display_name: String = "Soldier"
@export_range(1, 12) var count: int = 1
@export var stats: Stats
@export var ai: CombatAI
@export var character_class: CharacterClass
@export var level: int = 1
@export var base_armor: int = 0
