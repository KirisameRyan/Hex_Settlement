extends ColorRect

signal dismissed
signal mode_changed(selling: bool)
signal traded(kind: int, amount: int)

const ICON := preload("res://resource_icon.gd")
const Plate := preload("res://building_plate.gd")
const BODY := preload("res://assets/fonts/LXGWWenKaiGB-Regular.ttf")
const TITLE := preload("res://assets/fonts/WenYuanSerifSC-Medium.ttf")
const BACKGROUNDS := [preload("res://assets/ui/korindou-shelves.png"), preload("res://assets/ui/travelling-trader-shelves.png")]
const PORTRAITS := [preload("res://assets/characters/rinnosuke-shopkeeper.png"), preload("res://assets/characters/mike-trader-v2.png")]
const FRAME := Vector2(1260, 840)
const GOLD := Color("#ffd386")
const CREAM := Color("#fff0cf")

var scene: Control
var background: TextureRect
var portrait: TextureRect
var heading: Label
var notice: Label
var wallet: Label
var speaker: Label
var dialogue: Label
var total: Label
var quantity_text: Label
var confirm: Button
var less: Button
var more: Button
var buy_tab: Button
var sell_tab: Button
var slots: Array[Button] = []
var slot_icons: Array[TextureRect] = []
var slot_names: Array[Plate] = []
var trader := false
var selling := false
var entries: Array = []
var selected_index := -1
var quantity := 1
var resting_line := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 40
	color = Color(0.035, 0.030, 0.026, 0.84)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scene = Control.new()
	scene.size = FRAME
	add_child(scene)
	background = art(Rect2(Vector2.ZERO, FRAME))
	portrait = art(Rect2(23, 107, 403, 624))
	heading = label(Rect2(38, 23, 560, 52), 36, true)
	notice = label(Rect2(40, 75, 660, 38), 22)
	backing(Rect2(1014, 19, 203, 48))
	var coin := art(Rect2(1026, 24, 36, 36))
	coin.texture = ICON.ART.coin
	wallet = label(Rect2(1068, 23, 148, 40), 25)
	wallet.modulate = GOLD
	var close := button(Rect2(FRAME.x + 17, FRAME.y / 2 - 47, 66, 94), "")
	for state in ["normal", "hover", "pressed", "focus"]:
		close.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	close.draw.connect(func() -> void:
		var ink := CREAM if close.is_hovered() or close.has_focus() else Color("#b2b0a7")
		close.draw_polyline(PackedVector2Array([Vector2(18, 21), Vector2(44, 47), Vector2(18, 73)]), ink, 3.3, true))
	close.mouse_entered.connect(close.queue_redraw)
	close.mouse_exited.connect(close.queue_redraw)
	close.tooltip_text = "关闭交易"
	close.pressed.connect(dismissed.emit)
	var dialogue_plate := ColorRect.new()
	dialogue_plate.color = Color("#302219ec")
	dialogue_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_at(dialogue_plate, Rect2(24, 708, 420, 112))
	speaker = label(Rect2(42, 715, 193, 35), 25, true)
	speaker.modulate = GOLD
	buy_tab = button(Rect2(239, 715, 87, 37), "购买")
	frame_button(buy_tab)
	buy_tab.pressed.connect(set_mode.bind(false))
	sell_tab = button(Rect2(337, 715, 87, 37), "出售")
	frame_button(sell_tab)
	sell_tab.pressed.connect(set_mode.bind(true))
	dialogue = label(Rect2(42, 752, 379, 62), 20)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for index in 6:
		var slot := button(Rect2(), "")
		slot.pressed.connect(select_item.bind(index))
		slot.mouse_entered.connect(describe.bind(index))
		slot.focus_entered.connect(describe.bind(index))
		slot.mouse_exited.connect(restore_dialogue)
		slots.append(slot)
		var icon := TextureRect.new()
		ICON.setup(icon, ICON.ART.wood, 0)
		slot.add_child(icon)
		icon.position = Vector2(45, 0)
		icon.size = Vector2(107, 106)
		slot_icons.append(icon)
		var caption := Plate.new()
		slot.add_child(caption)
		caption.caption.add_theme_font_size_override("font_size", 19)
		slot_names.append(caption)
	backing(Rect2(502, 708, 711, 108))
	total = label(Rect2(523, 714, 665, 38), 21)
	quantity_text = label(Rect2(588, 766, 112, 40), 22)
	quantity_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	less = button(Rect2(536, 758, 52, 52), "−")
	more = button(Rect2(702, 758, 52, 52), "+")
	frame_button(less)
	frame_button(more)
	less.pressed.connect(change_quantity.bind(-1))
	more.pressed.connect(change_quantity.bind(1))
	confirm = button(Rect2(1008, 754, 189, 52), "确认购买")
	frame_button(confirm)
	confirm.pressed.connect(confirm_trade)
	resized.connect(fit)
	hide()


func add_at(child: Control, rect: Rect2) -> void:
	scene.add_child(child)
	child.position = rect.position
	child.size = rect.size


func dark_frame(fill: Color, border: Color) -> StyleBoxFlat:
	var frame := StyleBoxFlat.new()
	frame.bg_color = fill
	frame.border_color = border
	frame.set_border_width_all(1)
	return frame


func backing(rect: Rect2) -> void:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", dark_frame(Color("#201a15ee"), Color("#a07d4f")))
	add_at(panel, rect)


func frame_button(control: Button) -> void:
	control.add_theme_stylebox_override("normal", dark_frame(Color("#34271dea"), Color("#bd985e")))
	control.add_theme_stylebox_override("disabled", dark_frame(Color("#302b25"), Color("#665949")))
	for state in ["hover", "pressed", "focus"]:
		control.add_theme_stylebox_override(state, dark_frame(Color("#614a31"), GOLD))


func art(rect: Rect2) -> TextureRect:
	var view := TextureRect.new()
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_at(view, rect)
	return view


func label(rect: Rect2, points: int, display := false) -> Label:
	var text := Label.new()
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.add_theme_font_override("font", TITLE if display else BODY)
	text.add_theme_font_size_override("font_size", points)
	text.add_theme_color_override("font_color", CREAM)
	text.add_theme_color_override("font_shadow_color", Color("#1e140d"))
	text.add_theme_constant_override("shadow_offset_x", 1)
	text.add_theme_constant_override("shadow_offset_y", 2)
	add_at(text, rect)
	return text


func button(rect: Rect2, text: String) -> Button:
	var control := Button.new()
	control.text = text
	control.add_theme_font_override("font", TITLE)
	control.add_theme_font_size_override("font_size", 23)
	control.add_theme_color_override("font_color", CREAM)
	control.add_theme_color_override("font_hover_color", GOLD)
	control.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	control.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	var highlight := StyleBoxFlat.new()
	highlight.bg_color = Color(0.75, 0.45, 0.17, 0.12)
	highlight.border_color = GOLD
	highlight.border_width_bottom = 2
	for state in ["hover", "focus", "pressed"]:
		control.add_theme_stylebox_override(state, highlight)
	add_at(control, rect)
	return control


func fit() -> void:
	var layout_width := FRAME.x + 83
	var factor := minf((size.x - 40) / layout_width, (size.y - 36) / FRAME.y)
	scene.scale = Vector2.ONE * factor
	scene.position = (size - Vector2(layout_width, FRAME.y) * factor) * 0.5


func open(is_trader: bool) -> void:
	trader = is_trader
	selling = false
	selected_index = -1
	quantity = 1
	background.texture = BACKGROUNDS[int(trader)]
	portrait.texture = PORTRAITS[int(trader)]
	var aspect := portrait.texture.get_size()
	var scale_to_fit := minf(400.0 / aspect.x, 610.0 / aspect.y)
	portrait.size = aspect * scale_to_fit
	portrait.position = Vector2(225 - portrait.size.x * 0.5, 718 - portrait.size.y)
	heading.text = "三花的行商摊" if trader else "香霖堂·临时铺"
	speaker.text = "豪德寺三花" if trader else "森近霖之助"
	sell_tab.text = "收购" if trader else "出售"
	show()
	fit()


func set_mode(sell: bool) -> void:
	if selling != sell:
		selling = sell
		selected_index = -1
		quantity = 1
		mode_changed.emit(selling)


func populate(stock: Array, coins: int, summary: String, message := "") -> void:
	entries = stock
	wallet.text = "金币  %d" % coins
	notice.text = summary
	buy_tab.modulate = CREAM if selling else GOLD
	sell_tab.modulate = GOLD if selling else CREAM
	resting_line = message if not message.is_empty() else ("看看这趟带来的货吧。" if trader else "要看看今天的货吗？")
	for index in slots.size():
		var slot := slots[index]
		slot.visible = index < entries.size()
		if not slot.visible:
			continue
		var item: Dictionary = entries[index]
		var top := 333.0 if trader else 341.0
		var bottom := 526.0 if trader else 555.0
		slot.position = Vector2(510 + index % 3 * 221, (top if index < 3 else bottom) - 110)
		slot.size = Vector2(200, 150)
		slot_icons[index].texture = ICON.ART[item.icon]
		slot_icons[index].modulate.a = 0.42 if item.available == 0 else 1.0
		var tag := slot_names[index]
		tag.set_caption("%s  ·  %d 金" % [item.name, item.price])
		tag.position = Vector2((slot.size.x - tag.size.x) / 2.0, 114)
		slot.tooltip_text = "%s · %s %d" % [item.name, "还收" if selling else "剩余", item.available]
	restore_dialogue()
	update_quantity()


func describe(index: int) -> void:
	if index < entries.size():
		dialogue.text = entries[index].description


func restore_dialogue() -> void:
	dialogue.text = resting_line


func select_item(index: int) -> void:
	selected_index = index
	quantity = 1
	describe(index)
	update_quantity()


func change_quantity(delta: int) -> void:
	quantity += delta
	update_quantity()


func update_quantity() -> void:
	var item: Dictionary = entries[selected_index] if selected_index >= 0 and selected_index < entries.size() else {}
	var maximum: int = item.get("maximum", 0)
	quantity = clampi(quantity, 1, maxi(1, maximum))
	less.disabled = quantity <= 1
	more.disabled = quantity >= maximum
	confirm.disabled = maximum <= 0
	confirm.text = "确认出售" if selling else "确认购买"
	quantity_text.text = str(quantity) if maximum > 0 else "—"
	var explanation := "从货架选择商品"
	if not item.is_empty():
		explanation = "%s  ·  %d 金币" % [item.name, quantity * item.price] if maximum > 0 else item.unavailable
		if selling and maximum > 0 and item.get("ration", 0) > 0:
			explanation += "  ·  卖完可供 %d 人吃一晚" % (item.food - item.ration * quantity)
	total.text = explanation


func confirm_trade() -> void:
	if selected_index >= 0 and selected_index < entries.size() and not confirm.disabled:
		traded.emit(entries[selected_index].kind, quantity)


func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		dismissed.emit()
