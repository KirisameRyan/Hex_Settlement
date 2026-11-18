extends PanelContainer

const INSET := 24.0
var opened := false
var panel_width := 0.0
var motion: Tween
var preferred_width := 0.0
var preferred_height := 0.0


func arrange(width: float, height: float) -> void:
	preferred_width = width
	preferred_height = height
	set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	get_viewport().size_changed.connect(fit_viewport)
	fit_viewport()
	hide()


func fit_viewport() -> void:
	var view := get_viewport_rect().size
	panel_width = minf(preferred_width, view.x - INSET * 2.0)
	var height := minf(preferred_height, view.y - 150.0)
	offset_top = -height / 2.0 + 41
	offset_bottom = height / 2.0 + 41
	if motion != null and motion.is_running():
		motion.kill()
	shift_to(-INSET if opened else panel_width)
	if not opened:
		hide()


func set_open(state: bool) -> void:
	if opened == state:
		return
	opened = state
	if motion != null and motion.is_running():
		motion.kill()
	mouse_filter = Control.MOUSE_FILTER_STOP if state else Control.MOUSE_FILTER_IGNORE
	if state:
		show()
	motion = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	motion.tween_method(shift_to, offset_right, -INSET if state else panel_width, 0.23)
	if not state:
		motion.tween_callback(hide)


func shift_to(edge: float) -> void:
	offset_right = edge
	offset_left = edge - panel_width
