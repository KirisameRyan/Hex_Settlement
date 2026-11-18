extends PanelContainer

signal back_requested

const BODY := preload("res://assets/fonts/LXGWWenKaiGB-Regular.ttf")
const DISPLAY := preload("res://assets/fonts/WenYuanSerifSC-Medium.ttf")
const PAPER := preload("res://assets/ui/night-paper.png")
const GOLD := Color("#edcf93")
const PALE := Color("#f4e9ce")
const MUTED := Color("#bfbba1")

var content: VBoxContainer
var note: Label
var confirmation: ConfirmationDialog
var confirmed_action: Callable


func _ready() -> void:
	var menu_theme := Theme.new()
	menu_theme.default_font = BODY
	menu_theme.default_font_size = 20
	theme = menu_theme
	confirmation = ConfirmationDialog.new()
	confirmation.confirmed.connect(func() -> void: confirmed_action.call())
	add_child(confirmation)
	hide()


func place(width: float = 600.0, height: float = 560.0) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -width / 2.0
	offset_right = width / 2.0
	offset_top = -height / 2.0
	offset_bottom = height / 2.0


func prepare(heading: String, width := 600.0, height := 560.0, caption := "", artwork: Texture2D = PAPER) -> void:
	var panel := StyleBoxTexture.new()
	panel.texture = artwork
	for side in [SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM, SIDE_LEFT]:
		panel.set_content_margin(side, 54.0)
	add_theme_stylebox_override("panel", panel)
	if content != null:
		remove_child(content)
		content.queue_free()
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 10)
	add_child(content)
	var title := text_label(heading, 39, GOLD, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(title)
	if not caption.is_empty():
		var lead := text_label(caption, 20, MUTED)
		lead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		content.add_child(lead)
	place(width, height)
	show()


func add_action(caption: String, action: Callable) -> Button:
	var entry := button(caption)
	content.add_child(entry)
	entry.pressed.connect(action)
	return entry


func add_back() -> void:
	var back := add_action("‹  返回", back_requested.emit)
	back.grab_focus()


func add_note() -> void:
	note = text_label("", 16, GOLD)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(note)


func show_slots(game: Node, saving: bool) -> void:
	prepare("保存游戏" if saving else "读取存档", 660.0, 575.0)
	for slot in Session.SLOTS.size():
		if saving and slot == 0:
			continue
		var entry := Session.read_slot(slot)
		var name := "自动存档" if slot == 0 else "手动存档 %d" % slot
		var result := add_action(name + "\n" + describe(entry), choose_slot.bind(game, saving, slot))
		result.disabled = not saving and entry.is_empty()
	add_note()
	add_back()


func choose_slot(game: Node, saving: bool, slot: int) -> void:
	var action := func() -> void:
		var error: Error = game.save_progress(slot) if saving else Session.load_slot(slot)
		if saving and error == OK:
			show_slots(game, true)
			note.text = "已保存至手动存档 %d。" % slot
		elif error != OK:
			note.text = "操作失败。" + ("请检查存档目录是否可写。" if saving else "无法读取这个存档。")
	if saving and not Session.read_slot(slot).is_empty():
		ask("覆盖手动存档 %d？" % slot, "覆盖存档", action)
	elif not saving and game != null:
		ask("读取此存档？当前未保存的进度会丢失。", "读取存档", action)
	else:
		action.call()


func show_settings() -> void:
	prepare("设置", 540.0, 490.0)
	var audio := text_label("主音量  %d%%" % roundi(Session.volume * 100), 21, PALE)
	content.add_child(audio)
	var slider := HSlider.new()
	slider.max_value = 100
	slider.step = 1
	slider.value = roundi(Session.volume * 100)
	slider.custom_minimum_size.y = 28
	content.add_child(slider)
	slider.value_changed.connect(func(value: float) -> void:
		audio.text = "主音量  %d%%" % roundi(value)
		Session.volume = value / 100.0
		report_settings(Session.save_settings()))
	var display := CheckButton.new()
	display.text = "全屏显示"
	display.button_pressed = Session.fullscreen
	display.custom_minimum_size.y = 43
	content.add_child(display)
	display.toggled.connect(func(active: bool) -> void:
		Session.fullscreen = active
		report_settings(Session.save_settings()))
	var effects := CheckButton.new()
	effects.text = "快进边缘蓝光"
	effects.button_pressed = Session.glow
	effects.custom_minimum_size.y = 43
	content.add_child(effects)
	effects.toggled.connect(func(active: bool) -> void:
		Session.glow = active
		report_settings(Session.save_settings()))
	add_note()
	add_back()


func report_settings(error: Error) -> void:
	note.text = "" if error == OK else "设置已生效，写入本机设置文件失败。"


func ask(message: String, accept: String, action: Callable) -> void:
	confirmed_action = action
	confirmation.title = "幻想城镇"
	confirmation.dialog_text = message
	confirmation.ok_button_text = accept
	confirmation.cancel_button_text = "取消"
	confirmation.popup_centered()


static func describe(entry: Dictionary) -> String:
	if entry.is_empty():
		return "空存档"
	var info: Dictionary = entry.summary
	var stage: String = info.get("stage", "")
	return "%s第 %d 天%s　·　%s　·　%s" % [info.get("season", ""), info.get("day", 0),
		"入夜" if info.get("night", false) else "", stage, info.get("saved_at", "")]


static func text_label(caption: String, pixels: int, ink: Color, display := false) -> Label:
	var result := Label.new()
	result.text = caption
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	result.add_theme_font_override("font", DISPLAY if display else BODY)
	result.add_theme_font_size_override("font_size", pixels)
	result.add_theme_color_override("font_color", ink)
	return result


static func button(caption: String, wide := false) -> Button:
	var result := Button.new()
	result.text = caption
	result.custom_minimum_size.y = 54 if wide else 46
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT if wide else HORIZONTAL_ALIGNMENT_CENTER
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.add_theme_font_override("font", DISPLAY if wide else BODY)
	result.add_theme_font_size_override("font_size", 33 if wide else 20)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		var active: bool = state in ["hover", "pressed"]
		style.bg_color = Color(0.92, 0.78, 0.49, 0.12) if active else Color.TRANSPARENT
		style.border_color = Color(GOLD, 0.52 if active or state == "focus" else 0.0)
		style.border_width_bottom = 1
		style.content_margin_left = 32 if wide else 9
		style.content_margin_right = 9
		result.add_theme_stylebox_override(state, style)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		result.add_theme_color_override(color, PALE)
	result.add_theme_color_override("font_disabled_color", Color("#8c958a"))
	if wide:
		result.draw.connect(func() -> void:
			if not result.disabled and (result.is_hovered() or result.has_focus()):
				var center := Vector2(13, result.size.y * 0.5)
				result.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -8), center + Vector2(5, 0),
					center + Vector2(0, 8), center + Vector2(-5, 0)]), GOLD))
	return result
