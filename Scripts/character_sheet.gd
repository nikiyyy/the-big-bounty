extends Control
## Press Tab to open. Builds its own layout so adding a stat to Stats.NAMES
## is the only change needed to show it here.

var player: Node = null

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

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.custom_minimum_size = Vector2(340, 0)
	_panel.add_child(column)

	_header = Label.new()
	_header.add_theme_font_size_override("font_size", 20)
	column.add_child(_header)

	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 14)
	column.add_child(_points_label)

	column.add_child(HSeparator.new())

	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)

	for stat_name in Stats.NAMES:
		var name_label := Label.new()
		name_label.text = Stats.LABELS[stat_name]
		name_label.custom_minimum_size = Vector2(150, 0)
		grid.add_child(name_label)

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.custom_minimum_size = Vector2(40, 0)
		grid.add_child(value_label)

		var button := Button.new()
		button.text = "+"
		button.custom_minimum_size = Vector2(34, 0)
		button.pressed.connect(_on_raise.bind(stat_name))
		grid.add_child(button)

		_rows[stat_name] = {"value": value_label, "button": button}

	column.add_child(HSeparator.new())

	var hint := Label.new()
	hint.text = "Tab or Esc to close"
	hint.add_theme_font_size_override("font_size", 12)
	hint.modulate = Color(1, 1, 1, 0.5)
	column.add_child(hint)


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


func _on_raise(stat_name: String) -> void:
	if player == null or player.stats == null:
		return
	if player.stats.raise(stat_name):
		_refresh()
