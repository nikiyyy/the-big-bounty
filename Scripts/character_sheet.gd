extends Control
## Press Tab to open. Builds its own layout so adding a stat to Stats.NAMES
## is the only change needed to show it here.


const INVENTORY_CELLS := 18
var player: Node = null
var _slot_buttons: Dictionary = {}
var _item_buttons: Array = []
var _panel: PanelContainer
var _header: Label
var _points_label: Label
var _rows: Dictionary = {}      # stat name -> { value: Label, button: Button }


func _ready() -> void:
	Game.battle_started.connect(func(_b): hide())
	_build()
	hide()
	Game.player_spawned.connect(_on_player_spawned)
	if Game.player != null:
		_on_player_spawned(Game.player)


func _on_player_spawned(new_player: Node) -> void:
	player = new_player
	if player.has_signal("gold_changed"):
		player.gold_changed.connect(func(_g): _refresh())
	if player.has_signal("xp_changed"):
		player.xp_changed.connect(func(_x): _refresh())
	if visible:
		_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	if event.keycode == KEY_TAB:
		if Game.in_battle() and not visible:
			return
		_toggle()
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_ESCAPE and visible:
		hide()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	if visible:
		hide()
	else:
		_refresh()
		show()


# ------------------------------------------------------------------ layout

func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.08, 0.10, 0.96)
	box.set_corner_radius_all(8)
	box.set_content_margin_all(20)
	box.border_color = Color(1, 1, 1, 0.18)
	box.set_border_width_all(1)
	_panel.add_theme_stylebox_override("panel", box)
	center.add_child(_panel)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 12)
	_panel.add_child(outer)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 20)
	outer.add_child(_header)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 22)
	outer.add_child(columns)

	columns.add_child(_build_stats_panel())
	columns.add_child(_build_equipment_panel())
	columns.add_child(_build_inventory_panel())

	var hint := Label.new()
	hint.text = "Tab or Esc to close"
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(1, 1, 1, 0.5)
	outer.add_child(hint)


func _build_stats_panel() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(280, 0)

	column.add_child(_section_title("Stats"))

	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 14)
	column.add_child(_points_label)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 5)
	column.add_child(grid)

	for stat_name in Stats.NAMES:
		var name_label := Label.new()
		name_label.text = Stats.LABELS[stat_name]
		name_label.custom_minimum_size = Vector2(140, 0)
		grid.add_child(name_label)

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(36, 0)
		grid.add_child(value_label)

		var button := Button.new()
		button.text = "+"
		button.custom_minimum_size = Vector2(32, 0)
		button.pressed.connect(_on_raise.bind(stat_name))
		grid.add_child(button)

		_rows[stat_name] = {"value": value_label, "button": button}

	return column


func _build_equipment_panel() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(210, 0)

	column.add_child(_section_title("Equipment"))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	column.add_child(row)

	for slot in Inventory.SLOT_ORDER:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 4)

		var button := _make_slot_button(Vector2(58, 58), "equipment", slot)
		button.pressed.connect(_on_slot_pressed.bind(slot))
		cell.add_child(button)

		var caption := Label.new()
		caption.text = Inventory.SLOT_LABELS[slot]
		caption.add_theme_font_size_override("font_size", 11)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.modulate = Color(1, 1, 1, 0.6)
		cell.add_child(caption)

		row.add_child(cell)
		_slot_buttons[slot] = button

	return column


func _build_inventory_panel() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)

	column.add_child(_section_title("Inventory"))

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)

	for i in INVENTORY_CELLS:
		var button := _make_slot_button(Vector2(58, 58), "inventory", i)
		button.pressed.connect(_on_item_pressed.bind(i))
		grid.add_child(button)
		_item_buttons.append(button)

	return column


func _section_title(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 15)
	label.modulate = Color(1, 0.85, 0.5)
	return label


func _make_slot_button(size: Vector2, kind: String, key) -> Button:
	var button := Button.new()
	button.custom_minimum_size = size
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 10)

	var icon := ColorRect.new()
	icon.name = "Icon"
	icon.color = Color(0.55, 0.35, 0.85)
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 6
	icon.offset_top = 6
	icon.offset_right = -6
	icon.offset_bottom = -6
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.visible = false
	button.add_child(icon)

	button.set_drag_forwarding(
		_drag_from.bind(kind, key),
		_can_drop_here.bind(kind, key),
		_drop_here.bind(kind, key)
	)
	return button


# ------------------------------------------------------------------- data

func _refresh() -> void:
	if player == null or not is_instance_valid(player) or player.stats == null:
		return

	var stats: Stats = player.stats
	var who: String = player.display_name if "display_name" in player else "Hero"
	var gold: int = player.gold if "gold" in player else 0
	var xp: int = player.xp if "xp" in player else 0
	var level: int = player.level if "level" in player else 1
	var armor: int = player.armor() if player.has_method("armor") else 0

	_header.text = "%s   lvl %d   armor %d   %d gold   %d xp" % [who, level, armor, gold, xp]
	_points_label.text = "Points to spend: %d" % stats.available_points

	for stat_name in Stats.NAMES:
		_rows[stat_name]["value"].text = str(stats.get(stat_name))
		_rows[stat_name]["button"].disabled = not stats.can_raise()

	var inv: Inventory = player.inventory if "inventory" in player else null

	for slot in Inventory.SLOT_ORDER:
		_paint_cell(_slot_buttons[slot], inv.get_equipped(slot) if inv != null else null)

	for i in _item_buttons.size():
		var carried: Item = null
		if inv != null and i < inv.items.size():
			carried = inv.items[i]
		_paint_cell(_item_buttons[i], carried)

func _on_slot_pressed(slot: int) -> void:
	var inv: Inventory = player.inventory if "inventory" in player else null
	if inv != null and inv.unequip(slot):
		_refresh()


func _on_item_pressed(index: int) -> void:
	var inv: Inventory = player.inventory if "inventory" in player else null
	if inv == null or index >= inv.items.size():
		return
	if inv.equip(inv.items[index]):
		_refresh()

func _on_raise(stat_name: String) -> void:
	if player == null or player.stats == null:
		return
	if player.stats.raise(stat_name):
		_refresh()

func _paint_cell(button: Button, item: Item) -> void:
	var icon: ColorRect = button.get_node("Icon")
	icon.visible = item != null
	if item != null:
		icon.color = Color(0.55, 0.35, 0.85)
		button.tooltip_text = item.tooltip()
		button.modulate = item.rarity_color()
	else:
		button.tooltip_text = ""
		button.modulate = Color.WHITE

# ------------------------------------------------------------ drag and drop
## Bound args arrive after the engine's own, hence (at, [data,] kind, key).

func _inventory() -> Inventory:
	if player == null or not is_instance_valid(player) or not "inventory" in player:
		return null
	return player.inventory


func _item_at(kind: String, key) -> Item:
	var inv := _inventory()
	if inv == null:
		return null
	if kind == "equipment":
		return inv.get_equipped(key)
	return inv.items[key] if key < inv.items.size() else null


func _drag_from(_at: Vector2, kind: String, key) -> Variant:
	var item: Item = _item_at(kind, key)
	if item == null:
		return null

	var preview := ColorRect.new()
	preview.color = Color(0.55, 0.35, 0.85, 0.8)
	preview.custom_minimum_size = Vector2(48, 48)
	preview.size = Vector2(48, 48)
	set_drag_preview(preview)

	return {"kind": kind, "key": key, "item": item}


func _can_drop_here(_at: Vector2, data: Variant, kind: String, key) -> bool:
	if typeof(data) != TYPE_DICTIONARY or not data.has("item"):
		return false
	if kind == "equipment":
		return data["item"].slot == key      # only items that fit this slot
	return true


func _drop_here(_at: Vector2, data: Variant, kind: String, key) -> void:
	var inv := _inventory()
	if inv == null:
		return
	var item: Item = data["item"]

	if kind == "equipment":
		if data["kind"] == "inventory":
			inv.equip_to(item, key)
	else:
		if data["kind"] == "equipment":
			inv.unequip(data["key"])
		else:
			inv.swap_items(data["key"], key)

	_refresh()
