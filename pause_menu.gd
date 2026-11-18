extends ColorRect

const Pages := preload("res://menu_pages.gd")
const COVER := preload("res://assets/ui/pause-cover.png")

var pages: Pages
var game: Node
var front := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 30
	color = Color(0.035, 0.056, 0.063, 0.70)
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pages = Pages.new()
	add_child(pages)
	pages.back_requested.connect(show_front)
	hide()


func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_ESCAPE:
		return
	if game == null or (not visible and (not game.night_open or game.progression.visible)):
		return
	if pages.confirmation.visible:
		return
	get_viewport().set_input_as_handled()
	if visible and not front:
		show_front()
	else:
		game.toggle_pause_menu()


func open_for(map: Node) -> void:
	game = map
	show()
	show_front()


func show_front() -> void:
	front = true
	pages.prepare("已暂停", 480.0, 590.0, "%s　第 %d 天%s" % [
		game.campaign.season(game.day), game.season_day(), " · 夜间结算" if game.night_open else ""], COVER)
	var resume := pages.add_action("继续游戏", game.toggle_pause_menu)
	pages.add_action("保存游戏", show_slots.bind(true))
	pages.add_action("读取存档", show_slots.bind(false))
	pages.add_action("设置", show_settings)
	pages.add_action("返回标题", func() -> void:
		pages.ask("返回标题？当前未保存的进度会丢失。", "返回标题", Session.open_title))
	resume.grab_focus()


func show_slots(saving: bool) -> void:
	front = false
	pages.show_slots(game, saving)


func show_settings() -> void:
	front = false
	pages.show_settings()
