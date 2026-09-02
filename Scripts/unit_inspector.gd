extends CanvasLayer
## Right-click and hold on a unit to see its full stat block.

const OFFSET := Vector2(18, 18)

var _panel: PanelContainer
var _title: Label
var _grid: GridContainer
var _unit = null


func _ready() -> void:
	layer = 50
	add_to_group("unit_inspector")
	Game.battle_ended.connect(hide_card)
	Game.world_loaded.connect(func(_w): hide_card())
	_build()
	_panel.hide()


func show_for(unit) -> void:
	if unit == null or not is_instance_valid(unit):
		hide_card()
		return
	_unit = unit
	_populate()
	_panel.show()
	_follow_mouse()


func hide_card() -> void:
	_unit = null
	_panel.hide()


func _process(_delta: float) -> void:
	if _panel.visible:
		_follow_mouse()


## Flip the card to the other side of the cursor when it would run off-screen.
func _follow_mouse() -> void:
	var mouse: Vector2 = _panel.get_viewport().get_mouse_position()
	var screen: Vector2 = _panel.get_viewport_rect().size
	var size: Vector2 = _panel.size

	var pos: Vector2 = mouse + OFFSET
	if pos.x + size.x > screen.x:
		pos.x = mouse.x - size.x - OFFSET.x
	if pos.y + size.y > screen.y:
		pos.y = mouse.y - size.y - OFFSET.y
	_panel.position = pos


# ------------------------------------------------------------------- layout

func _build() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.07, 0.07, 0.09, 0.95)
	box.set_corner_radius_all(6)
	box.set_content_margin_all(12)
	box.border_color = Color(1, 1, 1, 0.2)
	box.set_border_width_all(1)
	_panel.add_theme_stylebox_override("panel", box)
	add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	_panel.add_child(column)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 15)
	column.add_child(_title)
	column.add_child(HSeparator.new())

	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 3)
	column.add_child(_grid)


func _populate() -> void:
	for child in _grid.get_children():
		child.queue_free()

	var name: String = _unit.display_name if "display_name" in _unit else "Unit"
	var level: int = _unit.level if "level" in _unit else 1
	var hp: int = _unit.current_health if "current_health" in _unit else 0
	var hp_max: int = _unit.max_health() if _unit.has_method("max_health") else 0
	var armor: int = _unit.armor() if _unit.has_method("armor") else 0

	_title.text = "%s   lvl %d" % [name, level]

	_add_pair("Health", "%d / %d" % [hp, hp_max])
	_add_pair("Armor", str(armor))

	var weapon: Item = null
	if "inventory" in _unit and _unit.inventory != null:
		weapon = _unit.inventory.get_equipped(Item.Slot.MAIN_HAND)
	_add_pair("Weapon", weapon.display_name if weapon != null else "Unarmed")

	var damage: String = "—"
	if weapon != null and weapon.is_weapon():
		damage = "%d–%d" % [weapon.damage_min, weapon.damage_max]
	_add_pair("Damage", damage)

	var stats: Stats = _unit.stats if "stats" in _unit else null
	if stats == null:
		return
	for stat_name in Stats.NAMES:
		_add_pair(Stats.LABELS[stat_name], str(stats.get(stat_name)))


func _add_pair(label: String, value: String) -> void:
	var name_label := Label.new()
	name_label.text = label
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.modulate = Color(1, 1, 1, 0.6)
	name_label.custom_minimum_size = Vector2(90, 0)
	_grid.add_child(name_label)

	var value_label := Label.new()
	value_label.text = value
	value_label.add_theme_font_size_override("font_size", 12)
	value_label.custom_minimum_size = Vector2(55, 0)
	_grid.add_child(value_label)
