extends ColorRect

signal dismissed
signal locate_requested(index: int)
signal claim_requested(index: int, origin: Vector2)
signal learn_requested(index: int)

const Icon := preload("res://resource_icon.gd")
const Campaign := preload("res://campaign.gd")
const Book := preload("res://assets/ui/spellbook.png")
const Board := preload("res://assets/ui/quest-board-wide.png")
const Display := preload("res://assets/fonts/WenYuanSerifSC-Medium.ttf")
const INK := Color("#392b21")
const MUTED := Color("#68513b")
const BRASS := Color("#916735")
const GREEN := Color("#50633f")
const BRANCHES := ["生息", "行旅", "营造"]
const INTRO := [
	"研究如何让土地持续产出。掌握入门法术后，可进一步解读两支符文。",
	"研究和旅途有关的魔法。点击节点，查阅已经解读的法术。",
	"研究城镇营造的法术。议事厅升阶后，可以研习更高阶的符文。",
]
const LAYOUTS := [
	{Campaign.Spell.FARMING: Vector2(193, 68), Campaign.Spell.HUSBANDRY: Vector2(97, 237), Campaign.Spell.FORESTRY: Vector2(289, 237)},
	{Campaign.Spell.ROAD: Vector2(193, 76), Campaign.Spell.SATCHEL: Vector2(97, 255),
		Campaign.Spell.ROAD_ARRAY: Vector2(289, 255)},
	{Campaign.Spell.CARPENTRY: Vector2(193, 55), Campaign.Spell.COTTAGE: Vector2(97, 181),
		Campaign.Spell.WAREHOUSING: Vector2(289, 181), Campaign.Spell.TOWNHOUSE: Vector2(97, 306)},
]

var panel: Panel
var close: Button
var previous_page: Button
var next_page: Button
var surface: Control
var closing := false
var drag_start := -1.0
var drag_offset := 0.0
var slide: Tween
var pages: Array[Control] = []
var tabs: Array[Button] = []
var quest_titles: Array[Label] = []
var quest_progress: Array[Label] = []
var quest_actions: Array[Button] = []
var meters: Array[ProgressBar] = []
var quarter_page: VBoxContainer
var quarter_snapshot: Array = []
var magic_page: Control
var task_page: VBoxContainer
var branch_title: Label
var page_number: Label
var tree: Control
var spell_title: Label
var spell_illustration: TextureRect
var spell_info: Label
var spell_cost: Label
var learn_button: Button
var spell_nodes: Dictionary = {}
var spell_names: Dictionary = {}
var spell_icons: Dictionary = {}
var branch := 0
var chosen := -1
var campaign: Campaign
var stage := 0
var notice: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	color = Color.TRANSPARENT
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	surface = Control.new()
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	surface.offset_top = -328
	surface.offset_bottom = 328
	shift(0)
	panel = Panel.new()
	surface.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_tasks()
	build_magic()
	close = button("")
	surface.add_child(close)
	close.position = Vector2(1010, 281)
	close.size = Vector2(66, 94)
	close.tooltip_text = "点击或向右拖动关闭"
	for state in ["normal", "hover", "pressed", "focus"]:
		close.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	close.draw.connect(draw_close)
	close.pressed.connect(dismissed.emit)
	hide()


func _draw() -> void:
	var top := Color(0.036, 0.042, 0.037, 0.17)
	var dim := Color(0.036, 0.042, 0.037, 0.78)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 93)), top)
	draw_polygon(PackedVector2Array([Vector2(0, 93), Vector2(size.x, 93), Vector2(size.x, 157), Vector2(0, 157)]),
		PackedColorArray([top, top, dim, dim]))
	draw_rect(Rect2(Vector2(0, 157), Vector2(size.x, maxf(size.y - 157, 0))), dim)


func draw_close() -> void:
	var ink := Color("#e2ddce") if close.is_hovered() or drag_start >= 0.0 else Color("#a4a49e")
	close.draw_polyline(PackedVector2Array([Vector2(18, 21), Vector2(44, 47), Vector2(18, 73)]), ink, 3.0, true)


func _input(event: InputEvent) -> void:
	if not visible or closing:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismissed.emit()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and close.get_global_rect().has_point(event.position):
			drag_start = event.position.x
			close.queue_redraw()
			get_viewport().set_input_as_handled()
		elif not event.pressed and drag_start >= 0.0:
			var moved: float = event.position.x - drag_start
			drag_start = -1.0
			get_viewport().set_input_as_handled()
			if absf(moved) <= 8.0 or moved >= 95.0:
				dismissed.emit()
			else:
				if slide:
					slide.kill()
				slide = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
				slide.tween_method(shift, drag_offset, 0.0, 0.20)
	elif event is InputEventMouseMotion and drag_start >= 0.0:
		if slide:
			slide.kill()
		shift(maxf(event.position.x - drag_start, 0.0))
		get_viewport().set_input_as_handled()


func shift(offset: float) -> void:
	drag_offset = offset
	surface.offset_left = -500 + offset
	surface.offset_right = 500 + offset


func slide_out() -> void:
	closing = true
	if slide:
		slide.kill()
	slide = create_tween().set_parallel().set_speed_scale(1.0 / maxf(Engine.time_scale, 1.0))
	slide.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	slide.tween_method(shift, drag_offset, size.x + 100.0, 0.27)
	slide.tween_property(self, "modulate:a", 0.0, 0.27)
	await slide.finished
	hide()
	closing = false


func open(magic: bool) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()
	var paper := StyleBoxTexture.new()
	paper.texture = Book if magic else Board
	panel.add_theme_stylebox_override("panel", paper)
	magic_page.visible = magic
	task_page.visible = not magic
	if not magic:
		show_tab(0)
	notice.text = ""
	drag_start = -1.0
	shift(0)
	modulate.a = 1.0
	show()
	close.grab_focus()


func build_tasks() -> void:
	task_page = VBoxContainer.new()
	task_page.add_theme_constant_override("separation", 14)
	panel.add_child(task_page)
	task_page.position = Vector2(58, 87)
	task_page.size = Vector2(884, 510)
	task_page.add_child(label("委托板", 34, true))
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 10)
	task_page.add_child(bar)
	for name_text in ["每日委托", "季度主线", "限时任务"]:
		var tab := button(name_text)
		tab.toggle_mode = true
		tab.pressed.connect(show_tab.bind(tabs.size()))
		bar.add_child(tab)
		tabs.append(tab)
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 16)
	task_page.add_child(cards)
	pages.append(cards)
	for index in 3:
		var body := card(cards)
		body.add_child(Icon.prop(["chest", "spyglass", "journal"][index], 50))
		var title := label("", 23, true)
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(title)
		quest_titles.append(title)
		var progress := label("", 16)
		body.add_child(progress)
		quest_progress.append(progress)
		var meter := progress_bar()
		body.add_child(meter)
		meters.append(meter)
		body.add_child(label("奖励  %d 经验 · %d 木头" % [Campaign.QUEST_XP, Campaign.QUEST_WOOD], 16))
		var action := button("")
		action.pressed.connect(task_action.bind(index))
		body.add_child(action)
		quest_actions.append(action)
	quarter_page = VBoxContainer.new()
	quarter_page.add_theme_constant_override("separation", 10)
	task_page.add_child(quarter_page)
	pages.append(quarter_page)
	var events := label("暂无限时任务", 23, true)
	task_page.add_child(events)
	pages.append(events)
	notice = label("", 16)
	task_page.add_child(notice)
	show_tab(0)


func card(parent: Container) -> VBoxContainer:
	var frame := PanelContainer.new()
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel", style(Color(0.99, 0.93, 0.76, 0.52), Color("#a88b59"), 13))
	parent.add_child(frame)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	frame.add_child(body)
	return body


func progress_bar() -> ProgressBar:
	var meter := ProgressBar.new()
	meter.show_percentage = false
	meter.custom_minimum_size.y = 7
	meter.add_theme_stylebox_override("background", style(Color("#d2b88a"), Color("#d2b88a"), 0))
	meter.add_theme_stylebox_override("fill", style(GREEN, GREEN, 0))
	return meter


func show_tab(index: int) -> void:
	for number in pages.size():
		pages[number].visible = index == number
		tabs[number].set_pressed_no_signal(index == number)


func task_action(index: int) -> void:
	if closing:
		return
	var action := quest_actions[index]
	if action.get_meta("claim", false):
		claim_requested.emit(index, action.get_global_rect().get_center())
	else:
		locate_requested.emit(index)


func set_tasks(titles: Array, totals: Array, goals: Array[int], claimed: Array, at_night: bool) -> void:
	for index in quest_titles.size():
		var complete: bool = totals[index] >= goals[index]
		quest_titles[index].text = titles[index]
		quest_progress[index].text = "已完成 · 待领取" if complete and not claimed[index] else "进度  %d / %d" % [mini(totals[index], goals[index]), goals[index]]
		if claimed[index]:
			quest_progress[index].text = "奖励已领取"
		meters[index].max_value = goals[index]
		meters[index].value = totals[index]
		var action := quest_actions[index]
		action.set_meta("claim", complete)
		action.text = "已领取" if claimed[index] else ("领取任务奖励" if complete else ("本日未完成" if at_night else "在地图上定位"))
		action.disabled = claimed[index] or (at_night and not complete)


func set_quarter(deadline: String, goal: int, goals: Array, achieved: bool, restored: bool) -> void:
	var snapshot := [deadline, goal, goals, achieved, restored]
	if snapshot == quarter_snapshot:
		return
	quarter_snapshot = snapshot
	for child in quarter_page.get_children():
		quarter_page.remove_child(child)
		child.queue_free()
	var heading := "将聚落发展为村庄" if goal == 1 else "将村庄发展为城镇"
	quarter_page.add_child(label(heading, 30, true))
	quarter_page.add_child(label(deadline, 17))
	var status := "结算时自动检查 · 未达标则本局结束"
	if restored:
		status = "季度主线已完成"
	elif achieved:
		status = "本季目标已达成"
	quarter_page.add_child(label(status, 17, true))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	quarter_page.add_child(row)
	if goal == 2:
		for entry: Array in goals.slice(0, 2):
			goal_card(row, entry, true)
		quarter_page.add_child(label("发展设施 · 牧场和木工作坊达成其一", 17, true))
		var choices := HBoxContainer.new()
		choices.add_theme_constant_override("separation", 14)
		quarter_page.add_child(choices)
		for entry: Array in goals.slice(2):
			goal_card(choices, entry, true)
	else:
		for entry: Array in goals:
			goal_card(row, entry, false)


func goal_card(parent: Container, entry: Array, compact: bool) -> void:
	var body := card(parent)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	body.add_child(title_row)
	var icon := TextureRect.new()
	var texture: Texture2D = entry[1] if entry[1] is Texture2D else Icon.ART[entry[1]]
	Icon.setup(icon, texture, 34 if compact else 56)
	title_row.add_child(icon)
	title_row.add_child(label(entry[0], 21, true))
	var status: String = entry[4] if not entry[4].is_empty() else ("已达标" if entry[2] >= entry[3] else "进行中")
	body.add_child(label("%d / %d   ·   %s" % [mini(entry[2], entry[3]), entry[3], status], 16))
	var meter := progress_bar()
	body.add_child(meter)
	meter.max_value = entry[3]
	meter.value = entry[2]


func build_magic() -> void:
	magic_page = Control.new()
	magic_page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(magic_page)
	magic_page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	branch_title = label("", 32, true)
	magic_page.add_child(branch_title)
	branch_title.position = Vector2(62, 82)
	tree = Control.new()
	tree.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tree.position = Vector2(54, 149)
	tree.size = Vector2(390, 390)
	tree.draw.connect(draw_branches)
	magic_page.add_child(tree)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 22)
	magic_page.add_child(details)
	details.position = Vector2(548, 107)
	details.size = Vector2(383, 430)
	var heading := HBoxContainer.new()
	heading.custom_minimum_size.y = 49
	details.add_child(heading)
	spell_title = label("", 31, true)
	spell_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(spell_title)
	spell_illustration = Icon.prop("journal", 49)
	heading.add_child(spell_illustration)
	var rule := ColorRect.new()
	rule.color = Color(BRASS, 0.43)
	rule.custom_minimum_size.y = 1
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(rule)
	spell_info = label("", 21)
	spell_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(spell_info)
	spell_cost = label("", 17)
	details.add_child(spell_cost)
	learn_button = button("◇ 研习此术")
	learn_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	learn_button.pressed.connect(func() -> void: learn_requested.emit(chosen))
	details.add_child(learn_button)
	previous_page = page_button("‹", Vector2(51, 547), -1)
	next_page = page_button("›", Vector2(879, 547), 1)
	page_number = label("", 16)
	page_number.position = Vector2(300, 571)
	page_number.size.x = 400
	page_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	magic_page.add_child(page_number)
	show_branch(0)


func page_button(glyph: String, at: Vector2, direction: int) -> Button:
	var corner := button(glyph)
	corner.add_theme_font_size_override("font_size", 43)
	corner.custom_minimum_size = Vector2(64, 58)
	corner.position = at
	corner.tooltip_text = "上一系" if direction < 0 else "下一系"
	corner.draw.connect(func() -> void:
		var sign_x := float(direction)
		var point := Vector2(32, 38)
		var ink := BRASS.lightened(0.13) if corner.is_hovered() else BRASS
		corner.draw_polyline(PackedVector2Array([point - Vector2(23 * sign_x, 0), point + Vector2(22 * sign_x, 0),
			point + Vector2(22 * sign_x, -22)]), ink, 1.4, true))
	corner.pressed.connect(func() -> void: show_branch(branch + direction))
	magic_page.add_child(corner)
	return corner


func draw_branches() -> void:
	var positions: Dictionary = LAYOUTS[branch]
	for key: int in positions:
		var parent: int = Campaign.RESEARCH[key][3]
		if not positions.has(parent):
			continue
		var start: Vector2 = positions[parent] + Vector2(0, 62)
		var finish: Vector2 = positions[key] - Vector2(0, 37)
		var mid := (start.y + finish.y) * 0.5
		var points := PackedVector2Array([start, Vector2(start.x, mid), Vector2(finish.x, mid), finish])
		var active := campaign != null and campaign.revealed(key)
		tree.draw_polyline(points, BRASS if active else Color("#a99067"), 2.0 if active else 1.25, true)
		if not is_equal_approx(start.x, finish.x):
			tree.draw_circle(Vector2(start.x, mid), 2.6, BRASS, true, -1.0, true)


func show_branch(index: int) -> void:
	branch = clampi(index, 0, BRANCHES.size() - 1)
	chosen = -1
	branch_title.text = BRANCHES[branch] + "研习"
	page_number.text = "%s  ·  %d / %d" % [BRANCHES[branch], branch + 1, BRANCHES.size()]
	previous_page.disabled = branch == 0
	next_page.disabled = branch == BRANCHES.size() - 1
	for child in tree.get_children():
		tree.remove_child(child)
		child.queue_free()
	spell_nodes.clear()
	spell_names.clear()
	spell_icons.clear()
	for key: int in LAYOUTS[branch]:
		var center: Vector2 = LAYOUTS[branch][key]
		var node := button("")
		node.toggle_mode = true
		node.custom_minimum_size = Vector2(68, 68)
		node.position = center - Vector2(34, 34)
		node.pressed.connect(choose_spell.bind(key))
		tree.add_child(node)
		var art := Icon.prop(Campaign.RESEARCH[key][2], 41)
		node.add_child(art)
		art.position = Vector2(13, 13)
		art.size = Vector2(42, 42)
		var title := label("", 17, true)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.position = center + Vector2(-81, 36)
		title.size.x = 162
		tree.add_child(title)
		spell_nodes[key] = node
		spell_names[key] = title
		spell_icons[key] = art
	sync_tree()


func set_magic(state: Campaign, center_stage: int) -> void:
	campaign = state
	stage = center_stage
	sync_tree()


func sync_tree() -> void:
	tree.queue_redraw()
	for key: int in spell_nodes:
		var node: Button = spell_nodes[key]
		var revealed := campaign != null and campaign.revealed(key)
		var completed: bool = revealed and campaign.learned[key]
		var title: Label = spell_names[key]
		title.text = Campaign.RESEARCH[key][0] if revealed else ""
		spell_icons[key].visible = revealed
		node.tooltip_text = title.text if revealed else "尚未解读"
		node.text = "" if revealed else ["⋔", "⟐", "⋇"][key % 3]
		node.add_theme_font_size_override("font_size", 29)
		for state in ["normal", "hover", "pressed", "focus"]:
			var fill := Color(0.80, 0.69, 0.49, 0.40)
			if revealed:
				fill = Color("#a69a62") if completed else Color("#e6c992")
			if state == "hover" or state == "pressed":
				fill = fill.lightened(0.14)
			var disk := style(fill, GREEN if completed else BRASS, 0)
			disk.set_corner_radius_all(34)
			disk.set_border_width_all(2 if completed or state == "pressed" else 1)
			node.add_theme_stylebox_override(state, disk)
	choose_spell(chosen)


func choose_spell(index: int) -> void:
	chosen = index
	for key: int in spell_nodes:
		spell_nodes[key].set_pressed_no_signal(key == index)
	learn_button.hide()
	spell_illustration.hide()
	spell_cost.text = ""
	if index < 0 or campaign == null:
		spell_title.text = BRANCHES[branch] + "手稿"
		spell_info.text = INTRO[branch]
		if campaign != null:
			spell_cost.text = "可用魔法点  %d" % campaign.points
		return
	if not campaign.revealed(index):
		spell_title.text = "尚未解读"
		spell_info.text = "掌握相连的前置法术后，符文才会显出内容。"
		return
	var entry: Array = Campaign.RESEARCH[index]
	spell_title.text = entry[0]
	spell_info.text = entry[1]
	spell_illustration.texture = Icon.ART[entry[2]]
	spell_illustration.show()
	if campaign.learned[index]:
		spell_cost.text = "已掌握"
		return
	var need: int = entry[4]
	spell_cost.text = "消耗 1 魔法点 · 当前 %d 点" % campaign.points
	if stage < need:
		spell_cost.text += "\n需要议事厅升至" + ["聚落", "村庄", "城镇"][need]
	learn_button.show()
	learn_button.disabled = not campaign.can_learn(index, stage)


func style(fill: Color, edge: Color, margin: float) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = edge
	box.set_border_width_all(1)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, margin)
	return box


func button(caption: String) -> Button:
	var result := Button.new()
	result.text = caption
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var active: bool = state in ["hover", "pressed", "hover_pressed", "focus"]
		var rule := style(Color(0.46, 0.28, 0.09, 0.09) if active else Color.TRANSPARENT, BRASS, 7)
		rule.set_border_width_all(0)
		rule.border_width_bottom = 1 if active else 0
		result.add_theme_stylebox_override(state, rule)
	for item in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		result.add_theme_color_override(item, INK)
	result.add_theme_color_override("font_disabled_color", Color("#99816a"))
	return result


func label(caption: String, font_size: int, prominent := false) -> Label:
	var result := Label.new()
	result.text = caption
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", INK if prominent else MUTED)
	if prominent:
		result.add_theme_font_override("font", Display)
	return result

