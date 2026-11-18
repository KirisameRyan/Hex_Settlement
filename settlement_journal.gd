extends Control

signal pickup_selected(key: Vector3i)
signal next_day_requested
signal resident_requested(index: int)
signal planning_requested
signal assignment_requested(index: int)
signal claims_requested

const ResourceIcon := preload("res://resource_icon.gd")
const SidePanel := preload("res://side_panel.gd")
const PAPER := preload("res://assets/ui/journal-paper.png")
const TOWN_COVER := preload("res://assets/ui/council-cover.png")
const AbilityChart := preload("res://ability_chart.gd")
const NIGHT_PAPER := preload("res://assets/ui/night-paper.png")
const TITLE_FONT := preload("res://assets/fonts/WenYuanSerifSC-Medium.ttf")
const MATERIALS := ["木头", "兽肉", "水", "石头", "铁矿", "铁件", "农产品", "鱼肉", "修复部件"]
const TOWN_PAGES := ["议事厅", "居民与调配", "仓库内容", "入住情况", "招募情况"]
const INK := Color("#30291e")
const MUTED_INK := Color("#665238")
const PALE := Color("#f3e9d2")
const DIM_GOLD := Color("#b1a994")
const GOLD := Color("#e9cb80")

var book: SidePanel
var cover_style: StyleBoxTexture
var page_style: StyleBoxTexture
var menu_buttons: Array[Button] = []
var pages: Array[Control] = []
var town_title: Label
var back_button: Button
var summary: Label
var residents: Label
var resident_picker: OptionButton
var chart: AbilityChart
var abilities: Label
var assign: Button
var roster: Array[Node3D] = []
var advancement: Label
var lodgings: Label
var recruitment: Label
var recruits: Array[Button] = []
var storage_rows: Array[Label] = []
var field_summary: Label
var pile_items: VBoxContainer
var cached_piles: Array = []
var night: ColorRect
var night_title: Label
var night_tally: Array[Label] = []
var night_text: Label
var next_button: Button
var claim_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_book()
	build_night()


func build_book() -> void:
	book = SidePanel.new()
	add_child(book)
	book.arrange(475, 580)
	cover_style = paper_style(TOWN_COVER, 43)
	page_style = paper_style(PAPER, 30)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	book.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	town_title = label("", 31, INK)
	town_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(town_title)
	back_button = action_button("返回议事厅", Color("#c5aa77"), INK, 6)
	back_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back_button.pressed.connect(show_page.bind(0))
	top.add_child(back_button)
	var home := add_page(column)
	summary = label("", 17, INK)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	home.add_child(summary)
	advancement = label("", 15, MUTED_INK)
	advancement.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	home.add_child(advancement)
	var menu := GridContainer.new()
	menu.columns = 2
	menu.add_theme_constant_override("h_separation", 9)
	menu.add_theme_constant_override("v_separation", 9)
	home.add_child(menu)
	for page in range(1, TOWN_PAGES.size()):
		var button := action_button(TOWN_PAGES[page], Color("#4b5845"), INK, 14)
		button.custom_minimum_size.y = 53
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(show_page.bind(page))
		menu.add_child(button)
		menu_buttons.append(button)

	residents = label("", 15, INK)
	var personnel := add_page(column)
	resident_picker = OptionButton.new()
	personnel.add_child(resident_picker)
	resident_picker.item_selected.connect(show_resident)
	chart = AbilityChart.new()
	chart.custom_minimum_size.y = 176
	personnel.add_child(chart)
	abilities = label("", 16, INK)
	abilities.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	personnel.add_child(abilities)
	assign = action_button("选中这名居民去地图派工", Color("#4b5845"), INK, 9)
	assign.pressed.connect(func() -> void: assignment_requested.emit(resident_picker.selected))
	personnel.add_child(assign)
	var resident_scroll := ScrollContainer.new()
	resident_scroll.custom_minimum_size.y = 95
	resident_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	personnel.add_child(resident_scroll)
	resident_scroll.add_child(residents)

	var warehouse := add_page(column)
	for resource in MATERIALS.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 7)
		warehouse.add_child(row)
		row.add_child(ResourceIcon.new(resource))
		var item := label("", 15, INK)
		row.add_child(item)
		storage_rows.append(item)
	field_summary = label("", 14, MUTED_INK)
	field_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warehouse.add_child(field_summary)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 102
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	warehouse.add_child(scroll)
	pile_items = VBoxContainer.new()
	pile_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(pile_items)

	lodgings = label("", 17, INK)
	lodgings.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var lodging_page := add_scroll_page(column, lodgings)
	var plan := action_button("重新规划住房", Color("#4b5845"), INK, 10)
	plan.pressed.connect(planning_requested.emit)
	lodging_page.add_child(plan)
	recruitment = label("", 17, INK)
	recruitment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var recruiting := add_page(column)
	recruiting.add_child(recruitment)
	for index in 2:
		var option := action_button("", Color("#4b5845"), INK, 10)
		option.pressed.connect(resident_requested.emit.bind(index))
		recruiting.add_child(option)
		recruits.append(option)
	show_page(0)


func add_page(parent: VBoxContainer) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.add_theme_constant_override("separation", 9)
	parent.add_child(page)
	pages.append(page)
	return page


func add_scroll_page(parent: VBoxContainer, content: Label) -> VBoxContainer:
	var page := add_page(parent)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 280
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	return page


func show_page(index: int) -> void:
	book.add_theme_stylebox_override("panel", cover_style if index == 0 else page_style)
	for number in pages.size():
		pages[number].visible = index == number
	town_title.text = TOWN_PAGES[index]
	back_button.visible = index != 0


func refresh_residents(workers: Array[Node3D], requirements: String) -> void:
	advancement.text = requirements
	roster = workers
	if resident_picker.item_count != roster.size():
		var previous := maxi(0, resident_picker.selected)
		resident_picker.clear()
		for worker in roster:
			resident_picker.add_item(worker.get_meta("resident_name"))
		resident_picker.select(previous)
	if not roster.is_empty():
		show_resident(resident_picker.selected)


func show_resident(index: int) -> void:
	var worker := roster[index]
	chart.values = worker.get_meta("stats")
	chart.queue_redraw()
	var labels := ["采集", "狩猎", "建造", "搬运", "勘探"]
	var lines := PackedStringArray()
	for skill in labels.size():
		var score: int = chart.values[skill]
		lines.append("%s %d/5" % [labels[skill], score])
	abilities.text = "  ·  ".join(lines) + "\n" + ("正在工作" if worker.visible else "空闲，可调配")
	assign.disabled = worker.visible


func refresh_book(overview: String, resident_list: PackedStringArray, housing_list: String, vacant: bool,
		candidate_list: Array[Dictionary], stock: Array[int], staged: Array[int], transit: Array[int], entries: Array) -> void:
	summary.text = overview
	residents.text = "\n".join(resident_list)
	lodgings.text = housing_list
	recruitment.text = "床位已满。" if not vacant else (
		"结算后会有新的候选人。" if candidate_list.is_empty() else "选择一位居民入住。")
	for index in recruits.size():
		var option := recruits[index]
		option.visible = index < candidate_list.size()
		option.disabled = not vacant
		if option.visible:
			var candidate := candidate_list[index]
			option.text = "%s  ·  %s效率 +25%%" % [candidate["name"], ["伐木", "打猎"][candidate["specialty"]]]
	for resource in MATERIALS.size():
		storage_rows[resource].text = "%s  %d 入库   ·   %d 待取   ·   %d 在途" % [
			MATERIALS[resource], stock[resource], staged[resource], transit[resource]]
	field_summary.text = "点击货物定位地块" if not entries.is_empty() else "地块上暂无待取物资"
	if cached_piles == entries:
		return
	cached_piles = entries
	for child in pile_items.get_children():
		pile_items.remove_child(child)
		child.queue_free()
	for entry: Dictionary in entries:
		var row := action_button(entry["label"], Color("#736149"), INK, 8)
		row.pressed.connect(pickup_selected.emit.bind(entry["key"]))
		pile_items.add_child(row)


func build_night() -> void:
	night = ColorRect.new()
	night.color = Color.TRANSPARENT
	night.resized.connect(night.queue_redraw)
	night.draw.connect(func() -> void:
		night.draw_rect(Rect2(Vector2.ZERO, Vector2(night.size.x, 93)), Color(0.025, 0.038, 0.069, 0.29))
		night.draw_rect(Rect2(Vector2(0, 93), Vector2(night.size.x, maxf(0, night.size.y - 93))), Color(0.025, 0.038, 0.069, 0.77)))
	night.mouse_filter = Control.MOUSE_FILTER_STOP
	night.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(night)
	night.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	night.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -405
	panel.offset_right = 405
	panel.offset_top = -246
	panel.offset_bottom = 246
	panel.add_theme_stylebox_override("panel", paper_style(NIGHT_PAPER, 45))
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 19)
	panel.add_child(column)
	night_title = label("", 33, PALE)
	column.add_child(night_title)
	var ledger := GridContainer.new()
	ledger.columns = 6
	ledger.add_theme_constant_override("h_separation", 13)
	ledger.add_theme_constant_override("v_separation", 9)
	column.add_child(ledger)
	for caption in ["资源", "白天入库", "夜间带回", "留在地块", "今晚消耗", "结余"]:
		var heading := label(caption, 15, DIM_GOLD)
		heading.custom_minimum_size.x = 86
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ledger.add_child(heading)
	for resource in MATERIALS.size():
		var row := HBoxContainer.new()
		ledger.add_child(row)
		row.add_child(ResourceIcon.new(resource))
		row.add_child(label(MATERIALS[resource], 17, PALE))
		for count in 5:
			var item := label("", 17, GOLD if count == 4 else PALE)
			ledger.add_child(item)
			night_tally.append(item)
	night_text = label("", 16, PALE)
	night_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	night_text.custom_minimum_size.y = 52
	column.add_child(night_text)
	claim_button = action_button("", GOLD, PALE, 9)
	claim_button.pressed.connect(claims_requested.emit)
	column.add_child(claim_button)
	next_button = action_button("开始下一天", GOLD, PALE, 14)
	next_button.custom_minimum_size.y = 48
	column.add_child(next_button)
	next_button.pressed.connect(next_day_requested.emit)
	night.hide()


func enter_night(day: int, deliveries: Array[int], brought: Array[int], left: Array[int], consumed: Array[int],
		balance: Array[int], report: String) -> void:
	night_title.text = "第 %d 天 · 夜间结算" % day
	for resource in MATERIALS.size():
		var numbers := [deliveries[resource], brought[resource], left[resource], consumed[resource], balance[resource]]
		for column in numbers.size():
			night_tally[resource * 5 + column].text = str(numbers[column])
	night_text.text = report
	night.modulate.a = 0.0
	night.show()
	next_button.grab_focus()
	night.create_tween().tween_property(night, "modulate:a", 1.0, 0.28)


func leave_night() -> void:
	next_button.release_focus()
	night.hide()


func set_unclaimed(count: int) -> void:
	claim_button.visible = count > 0
	claim_button.text = "领取委托奖励  ·  %d 项" % count


func update_night_stock(balance: Array[int], field: Array[int]) -> void:
	for resource in MATERIALS.size():
		night_tally[resource * 5 + 2].text = str(field[resource])
		night_tally[resource * 5 + 4].text = str(balance[resource])


func paper_style(texture: Texture2D, padding: float) -> StyleBoxTexture:
	var paper := StyleBoxTexture.new()
	paper.texture = texture
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		paper.set_content_margin(side, padding)
	return paper


func label(content: String, size: int, tint: Color) -> Label:
	var item := Label.new()
	item.text = content
	item.add_theme_color_override("font_color", tint)
	item.add_theme_font_size_override("font_size", size)
	if size >= 26:
		item.add_theme_font_override("font", TITLE_FONT)
	return item


func action_button(content: String, color: Color, ink: Color, padding: float) -> Button:
	var button := Button.new()
	button.text = content
	for state in ["normal", "hover", "pressed"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(color, 0.10 if state == "normal" else 0.29)
		box.set_corner_radius_all(1)
		box.border_color = Color(color, 0.52)
		box.border_width_bottom = 1
		for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
			box.set_content_margin(side, padding if side == SIDE_TOP or side == SIDE_BOTTOM else 9)
		button.add_theme_stylebox_override(state, box)
	for property in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color"]:
		button.add_theme_color_override(property, ink)
	return button
