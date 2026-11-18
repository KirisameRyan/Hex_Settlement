extends Control

signal speed_requested(mode: int)
signal progression_requested(magic: bool)

const ResourceIcon := preload("res://resource_icon.gd")
const TITLE_FONT := preload("res://assets/fonts/WenYuanSerifSC-Medium.ttf")
const INK := Color("#192723")
const BRASS := Color("#aa8956")
const GOLD := Color("#efd29a")
const PAPER := Color("#f0e5c8")
const MUTED := Color("#b9c2aa")
const ALERT := Color("#ed9a80")
const RADIUS := 209.0

var season_label: Label
var day_label: Label
var clock_label: Label
var command_value: Label
var capacity_value: Label
var capacity_detail: Label
var survey_value: Label
var gold_value: Label
var experience_value: Label
var experience_meter: ProgressBar
var magic_points: Label
var effects: Control
var remaining_ratio := 1.0
var urgent := false
var speed_buttons: Array[Button] = []
var task_shortcut: Button
var task_dot: Control
var speed_state := Vector3i(-1, -1, -1)


class TimeGlyph extends Control:
	var mode := 0

	func _draw() -> void:
		var center := size * 0.5
		if mode == 0:
			for x in [-6, 2]:
				draw_rect(Rect2(center + Vector2(x, -8), Vector2(4, 16)), GOLD)
		elif mode == 2:
			var start := center + Vector2(-9, 0)
			draw_colored_polygon(PackedVector2Array([start + Vector2(0, -8), start + Vector2(12, 0), start + Vector2(0, 8)]), GOLD)
			draw_rect(Rect2(center + Vector2(5, -8), Vector2(3, 16)), GOLD)
		else:
			var arrows := [0] if mode == 1 else [-6, 3]
			for x in arrows:
				var start := center + Vector2(x - 4, 0)
				draw_colored_polygon(PackedVector2Array([
					start + Vector2(0, -8), start + Vector2(10, 0), start + Vector2(0, 8)
				]), GOLD)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	season_label = make_label("春季", 39, GOLD, true)
	place_dial_label(season_label, Vector2(28, 20))
	day_label = make_label("", 22, PAPER, true)
	place_dial_label(day_label, Vector2(29, 75))
	clock_label = make_label("", 16, MUTED)
	place_dial_label(clock_label, Vector2(29, 112))
	build_status_bar()
	build_shortcuts()
	build_time_controls()


func build_time_controls() -> void:
	var row := HBoxContainer.new()
	row.process_mode = Node.PROCESS_MODE_ALWAYS
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 9)
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	row.offset_left = -200
	row.offset_right = -28
	row.offset_top = 21
	row.offset_bottom = 69
	var captions := ["暂停 / 继续", "切换 ×1 / ×3", "跳过剩余白天"]
	for mode in captions.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(51, 48)
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = captions[mode]
		button.pressed.connect(speed_requested.emit.bind(mode))
		row.add_child(button)
		var glyph := TimeGlyph.new()
		glyph.mode = mode
		if mode == 1:
			button.text = "×1"
			glyph.hide()
		glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(glyph)
		glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		speed_buttons.append(button)


func set_speed_buttons(active: int, out_of_commands: bool, at_night: bool) -> void:
	var state := Vector3i(active, int(out_of_commands), int(at_night))
	if state == speed_state:
		return
	speed_state = state
	for mode in speed_buttons.size():
		var button := speed_buttons[mode]
		var suggested := mode == 2 and out_of_commands and not at_night
		var selected := mode == 0 and active == 0 or mode == 1 and active == 2
		button.disabled = at_night or (mode == 2 and not out_of_commands)
		button.get_child(0).modulate.a = 0.45 if at_night else 1.0
		var fill := Color("#645234") if selected or suggested else Color("#2d3c33")
		var edge := GOLD if selected or suggested else Color("#687153")
		button.add_theme_stylebox_override("normal", plaque(fill, edge))
		button.add_theme_stylebox_override("hover", plaque(fill.lightened(0.13), GOLD))
		button.add_theme_stylebox_override("pressed", plaque(fill.darkened(0.15), GOLD))
		button.add_theme_stylebox_override("disabled", plaque(Color("#25302b"), Color("#484c42")))
		if mode == 2:
			button.tooltip_text = "跳过剩余白天" if suggested else "行动点用完后可以入夜"
		elif mode == 1:
			button.text = "×3" if active == 2 else "×1"


func place_dial_label(item: Label, offset: Vector2) -> void:
	add_child(item)
	item.position = offset


func _draw() -> void:
	var band := PackedVector2Array([Vector2(161, 0), Vector2(size.x, 0), Vector2(size.x, 93), Vector2(161, 93)])
	draw_colored_polygon(band, INK)
	draw_line(Vector2(161, 92), Vector2(size.x, 92), BRASS.darkened(0.2), 2.0, true)
	draw_line(Vector2(173, 86), Vector2(size.x, 86), Color("#4b5950"), 1.0, true)
	var quarter := PackedVector2Array([Vector2.ZERO])
	for tick in 49:
		quarter.append(Vector2.from_angle(float(tick) / 48.0 * PI / 2) * RADIUS)
	draw_colored_polygon(quarter, Color("#1d2e29"))
	draw_arc(Vector2.ZERO, RADIUS - 1.0, 0, PI / 2, 48, BRASS, 2.0, true)
	draw_arc(Vector2.ZERO, RADIUS - 11.0, 0.027, PI / 2 - 0.027, 48, Color("#505a4b"), 4.5, true)
	for tick in range(1, 8):
		var spoke := Vector2.from_angle(tick * PI / 16)
		draw_line(spoke * (RADIUS - 24), spoke * (RADIUS - 17), BRASS.darkened(0.15), 1.2, true)
	if remaining_ratio > 0.0:
		var tail := lerpf(0.027, PI / 2 - 0.027, remaining_ratio)
		var tint := ALERT if urgent else GOLD
		draw_arc(Vector2.ZERO, RADIUS - 11.0, 0.027, tail, 48, tint, 4.5, true)
		draw_circle(Vector2.from_angle(tail) * (RADIUS - 11), 4.2, tint, true, -1.0, true)


func build_status_bar() -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 14)
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	row.offset_left = 229
	row.offset_top = 10
	row.offset_right = -22
	row.offset_bottom = 73
	var advancement := VBoxContainer.new()
	advancement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	advancement.custom_minimum_size.x = 194
	advancement.add_theme_constant_override("separation", 4)
	row.add_child(advancement)
	experience_value = make_label("", 16, PAPER, true)
	advancement.add_child(experience_value)
	experience_meter = ProgressBar.new()
	experience_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	experience_meter.show_percentage = false
	experience_meter.custom_minimum_size.y = 7
	experience_meter.add_theme_stylebox_override("background", plaque(Color("#465344"), Color("#596356")))
	experience_meter.add_theme_stylebox_override("fill", plaque(Color("#b097df"), Color("#e3c9ff")))
	advancement.add_child(experience_meter)
	magic_points = make_label("", 14, GOLD)
	advancement.add_child(magic_points)
	add_divider(row)
	command_value = status_item(row, ResourceIcon.prop("talisman", 40), "行动点")[0]
	var storage := status_item(row, ResourceIcon.prop("chest", 40), "仓库")
	capacity_value = storage[0]
	capacity_detail = storage[1]
	survey_value = status_item(row, ResourceIcon.prop("spyglass", 40), "已探明")[0]
	gold_value = status_item(row, ResourceIcon.prop("coin", 40), "金币")[0]
	effects = Control.new()
	effects.process_mode = Node.PROCESS_MODE_ALWAYS
	effects.z_index = 20
	effects.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(effects)
	effects.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func status_item(row: HBoxContainer, icon: Control, title: String) -> Array[Label]:
	var group := HBoxContainer.new()
	group.custom_minimum_size.x = 136
	group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	group.add_theme_constant_override("separation", 6)
	row.add_child(group)
	group.add_child(icon)
	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 0)
	group.add_child(column)
	column.add_child(make_label(title, 14, MUTED))
	var value := make_label("", 22, PAPER, true)
	column.add_child(value)
	var detail := make_label("", 13, MUTED)
	column.add_child(detail)
	if title != "已探明":
		add_divider(row)
	return [value, detail]


func add_divider(row: HBoxContainer) -> void:
	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(1, 34)
	divider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	divider.color = Color("#48584b")
	row.add_child(divider)


func set_experience(level: int, xp: int, threshold: int, points: int) -> void:
	experience_value.text = "魔理沙 Lv.%d     %d / %d" % [level, xp, threshold]
	experience_meter.max_value = threshold
	experience_meter.value = xp
	magic_points.text = "◇  魔法点 %d" % points


func fly_reward(kind: String, amount: int, origin: Vector2, xp := false, level_up := false) -> void:
	var target := experience_meter.get_global_rect().get_center() if xp else capacity_value.get_global_rect().get_center()
	var tint := Color("#e8c6ff") if xp else GOLD
	var badge := HBoxContainer.new()
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.add_child(badge)
	badge.add_child(ResourceIcon.prop(kind, 37))
	var count := make_label("+%d%s" % [amount, " 经验" if xp else ""], 19, tint)
	count.add_theme_color_override("font_outline_color", INK)
	count.add_theme_constant_override("outline_size", 7)
	badge.add_child(count)
	var flight := badge.create_tween().set_speed_scale(1.0 / maxf(Engine.time_scale, 1.0))
	var midpoint := origin.lerp(target, 0.47) + Vector2(-50 if xp else 50, -85)
	flight.tween_method(func(progress: float) -> void:
		var travel := origin.lerp(midpoint, progress).lerp(midpoint.lerp(target, progress), progress)
		badge.position = travel - badge.size * 0.5
		badge.scale = Vector2.ONE * lerpf(1.0, 0.60, progress),
		0.0, 1.0, 0.62).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	flight.tween_callback(flash_reward.bind(target, tint, level_up))
	flight.tween_property(badge, "modulate:a", 0.0, 0.13)
	flight.tween_callback(badge.queue_free)


func flash_reward(target: Vector2, tint: Color, level_up: bool) -> void:
	var flare := Control.new()
	flare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	effects.add_child(flare)
	flare.position = target
	flare.draw.connect(func() -> void:
		flare.draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 40, tint, 2.0, true)
		for index in 8:
			var ray := Vector2.from_angle(index * TAU / 8.0)
			flare.draw_line(ray * 21.0, ray * 30.0, tint, 2.0, true))
	if level_up:
		var new_point := make_label("+1 魔法点", 18, GOLD, true)
		new_point.position = Vector2(-42, 16)
		new_point.add_theme_color_override("font_outline_color", INK)
		new_point.add_theme_constant_override("outline_size", 7)
		flare.add_child(new_point)
	var fade := flare.create_tween().set_parallel().set_speed_scale(1.0 / maxf(Engine.time_scale, 1.0))
	fade.tween_property(flare, "scale", Vector2.ONE * 1.6, 0.44)
	fade.tween_property(flare, "modulate:a", 0.0, 0.44)
	fade.chain().tween_callback(flare.queue_free)


func build_shortcuts() -> void:
	var rail := VBoxContainer.new()
	rail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rail.position = Vector2(26, 236)
	rail.add_theme_constant_override("separation", 15)
	add_child(rail)
	for item in [["talisman", "任务"], ["journal", "成就"], ["spyglass", "魔法研习"]]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(65, 66)
		button.focus_mode = Control.FOCUS_NONE
		var enabled: bool = item[0] != "journal"
		button.disabled = not enabled
		button.add_theme_stylebox_override("normal", plaque(Color("#415045"), BRASS))
		button.add_theme_stylebox_override("hover", plaque(Color("#5b6451"), GOLD))
		button.add_theme_stylebox_override("pressed", plaque(Color("#2e3b33"), BRASS))
		button.add_theme_stylebox_override("disabled", plaque(Color("#202e28"), Color("#6d725a")))
		rail.add_child(button)
		if item[0] == "talisman":
			task_shortcut = button
			task_dot = Control.new()
			task_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(task_dot)
			task_dot.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			task_dot.draw.connect(func() -> void:
				task_dot.draw_circle(Vector2(-2, 3), 7.5, Color("#34241f"), true, -1, true)
				task_dot.draw_circle(Vector2(-2, 3), 5.5, Color("#f06457"), true, -1, true))
			task_dot.hide()
		var body := VBoxContainer.new()
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.alignment = BoxContainer.ALIGNMENT_CENTER
		body.add_theme_constant_override("separation", 1)
		button.add_child(body)
		body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var icon := ResourceIcon.prop(item[0], 30)
		icon.modulate.a = 0.70 if not enabled else 1.0
		body.add_child(icon)
		var title := make_label(item[1], 15, PAPER if enabled else MUTED)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.add_child(title)
		if enabled:
			button.pressed.connect(progression_requested.emit.bind(item[0] == "spyglass"))
		else:
			button.tooltip_text = "菜单预留"


func set_pending_tasks(count: int) -> void:
	task_dot.visible = count > 0
	task_shortcut.tooltip_text = "任务 · %d 项待领取" % count if count > 0 else "任务"


func set_clock(day: int, remaining: float, duration: float, season := "春季") -> void:
	season_label.text = season
	var display := ceili(remaining)
	day_label.text = "第 %d 天" % day
	clock_label.text = "入夜  %02d:%02d" % [floori(display / 60.0), display % 60]
	urgent = remaining < 30.0
	clock_label.add_theme_color_override("font_color", ALERT if urgent else MUTED)
	remaining_ratio = clampf(remaining / duration, 0.0, 1.0)
	queue_redraw()


func set_status(commands: int, starting: int, stock: Array[int], available: int, capacity: int,
		explored: int, total_tiles: int, coins := 0) -> void:
	command_value.text = "%d / %d" % [commands, starting]
	var used := 0
	for amount in stock:
		used += amount
	capacity_value.text = "%d / %d" % [used, capacity]
	capacity_detail.text = "可用 %d" % available
	if available == 0:
		capacity_detail.add_theme_color_override("font_color", ALERT)
	else:
		capacity_detail.add_theme_color_override("font_color", MUTED)
	survey_value.text = "%d / %d" % [explored, total_tiles]
	gold_value.text = str(coins)


func make_label(content: String, font_size: int, tint: Color, display := false) -> Label:
	var item := Label.new()
	item.text = content
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.add_theme_color_override("font_color", tint)
	item.add_theme_font_size_override("font_size", font_size)
	if display:
		item.add_theme_font_override("font", TITLE_FONT)
	return item


func plaque(fill: Color, edge: Color) -> StyleBoxFlat:
	var panel := StyleBoxFlat.new()
	panel.bg_color = fill
	panel.border_color = edge
	panel.set_border_width_all(1)
	panel.border_width_bottom = 3
	panel.shadow_color = Color(0.02, 0.04, 0.02, 0.48)
	panel.shadow_offset = Vector2(1, 3)
	panel.shadow_size = 2
	return panel
