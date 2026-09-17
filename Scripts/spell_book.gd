extends CanvasLayer
## Spell list for the active unit. B toggles it; clicking a spell starts targeting.

signal spell_chosen(index: int)

var _root: Control
var _panel: PanelContainer
var _title: Label
var _list: VBoxContainer
var _caster = null
var _spells: Array = []


func _ready() -> void:
	layer = 45
	add_to_group("spell_book")
	_build()
	_root.hide()


func is_open() -> bool:
	return _root.visible


## Show the spells this unit knows. Pass an empty array to close.
func show_for(caster, spells: Array) -> void:
	_caster = caster
	_spells = spells
	_rebuild()
	_root.show()


func close() -> void:
	_root.hide()


func toggle(caster, spells: Array) -> void:
	if _root.visible:
		close()
	else:
		show_for(caster, spells)


# ------------------------------------------------------------------ layout

func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_panel.offset_left = 24
	_panel.offset_right = 24

	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.08, 0.10, 0.95)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(14)
	box.border_color = Color(1, 1, 1, 0.18)
	box.set_border_width_all(1)
	_panel.add_theme_stylebox_override("panel", box)
	_root.add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_panel.add_child(column)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 15)
	_title.modulate = Color(1, 0.85, 0.5)
	column.add_child(_title)
	column.add_child(HSeparator.new())

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 6)
	column.add_child(_list)

	var hint := Label.new()
	hint.text = "B to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.modulate = Color(1, 1, 1, 0.45)
	column.add_child(hint)


func _rebuild() -> void:
	for child in _list.get_children():
		child.queue_free()

	var who: String = "Spells"
	if _caster != null and "display_name" in _caster:
		who = "%s — spells" % _caster.display_name
	_title.text = who

	if _spells.is_empty():
		var none := Label.new()
		none.text = "Nothing known."
		none.add_theme_font_size_override("font_size", 12)
		none.modulate = Color(1, 1, 1, 0.5)
		_list.add_child(none)
		return

	var mana: int = _caster.current_mana if _caster != null and "current_mana" in _caster else 0

	for i in _spells.size():
		var spell: Spell = _spells[i]
		var button := Button.new()
		button.custom_minimum_size = Vector2(240, 44)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = "%s     %d mana" % [spell.display_name, spell.mana_cost]
		button.disabled = mana < spell.mana_cost
		button.tooltip_text = _describe(spell)
		button.pressed.connect(func(): spell_chosen.emit(i))
		_list.add_child(button)


func _describe(spell: Spell) -> String:
	var lines: Array = [spell.display_name]
	if not spell.description.is_empty():
		lines.append(spell.description)
	if spell.deals_damage():
		lines.append("%d–%d damage" % [spell.damage_min, spell.damage_max])
	if spell.effect != null:
		lines.append("%s for %d turns" % [spell.effect.display_name, spell.effect.duration])
	lines.append("Range %d, radius %d" % [spell.cast_range, spell.radius])
	return "\n".join(lines)
