extends Control

const Pages := preload("res://menu_pages.gd")
const Cover := preload("res://assets/ui/title-cover.png")

var actions: VBoxContainer
var pages: Pages
var shade: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var art := TextureRect.new()
	art.texture = Cover
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var heading := Pages.text_label("幻想城镇", 92, Pages.GOLD, true)
	heading.add_theme_color_override("font_shadow_color", Color("#132426"))
	heading.add_theme_constant_override("shadow_offset_x", 3)
	heading.add_theme_constant_override("shadow_offset_y", 4)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(heading)
	heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	heading.offset_left = -520
	heading.offset_right = -72
	heading.offset_top = 68
	var rule := ColorRect.new()
	rule.color = Color(Pages.GOLD, 0.58)
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rule)
	rule.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	rule.offset_left = -372
	rule.offset_right = -73
	rule.offset_top = 198
	rule.offset_bottom = 200
	actions = VBoxContainer.new()
	actions.add_theme_constant_override("separation", 11)
	add_child(actions)
	actions.anchor_top = 0.31
	actions.anchor_bottom = 0.31
	actions.offset_left = 114
	actions.offset_right = 376
	var recent := Session.latest_slot()
	var resume := add_action("继续游戏", func() -> void:
		if Session.load_slot(Session.latest_slot()) != OK:
			open_slots())
	resume.disabled = recent < 0
	var start := add_action("新游戏", open_intro)
	add_action("读取存档", open_slots)
	add_action("设置", open_settings)
	add_action("退出游戏", get_tree().quit)
	shade = ColorRect.new()
	shade.color = Color(0.028, 0.049, 0.054, 0.62)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages = Pages.new()
	shade.add_child(pages)
	pages.back_requested.connect(show_title)
	shade.hide()
	(start if resume.disabled else resume).grab_focus()


func add_action(caption: String, callback: Callable) -> Button:
	var action := Pages.button(caption, true)
	action.pressed.connect(callback)
	actions.add_child(action)
	return action


func _input(event: InputEvent) -> void:
	if shade.visible and not pages.confirmation.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		show_title()


func open_slots() -> void:
	shade.show()
	pages.show_slots(null, false)


func open_settings() -> void:
	shade.show()
	pages.show_settings()


func open_intro() -> void:
	shade.show()
	pages.prepare("幻想乡折叠异变", 620.0, 435.0)
	var story := Pages.text_label("一夜之间，幻想乡的一角折进了一张沙盘。魔理沙在迷雾中央找到六名居民，以及一座还能点起灯火的营地。要弄清异变，她得先让大家在这里安顿下来。", 24, Pages.PALE)
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	pages.content.add_child(story)
	pages.add_back()
	pages.add_action("进入沙盘", Session.start_new).grab_focus()


func show_title() -> void:
	shade.hide()
	for button: Button in actions.get_children():
		if not button.disabled:
			button.grab_focus()
			return
