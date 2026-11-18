extends BaseButton

const ResourceIcon := preload("res://resource_icon.gd")
const RADIUS := 27.0
const CENTER := Vector2(30, 30)
const REST_EDGE := Color("#718077")
const FILL := Color("#1b2a25")

var tint: Color
var displayed: Label
var progress := -1.0
var flash := 0.0
var previous_total := 0
var vertices: PackedVector2Array


func build(kind: int) -> void:
	tint = ResourceIcon.COLORS[kind]
	size = CENTER * 2
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for index in 6:
		vertices.append(CENTER + direction(index) * RADIUS)
	var body := VBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", -2)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(body)
	body.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	body.add_child(ResourceIcon.new(kind, 24))
	displayed = Label.new()
	displayed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	displayed.add_theme_font_size_override("font_size", 15)
	displayed.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(displayed)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)


func direction(index: int) -> Vector2:
	return Vector2.from_angle(-PI / 2 + TAU / 6 * index)


func set_amount(ready: int, reserved: int) -> void:
	if ready + reserved > previous_total:
		flash = 1.0
	previous_total = ready + reserved
	displayed.text = str(ready)
	displayed.modulate = Color("#fff2d6") if ready > 0 else Color("#b9caba")
	queue_redraw()


func set_progress(value: float, delta: float) -> void:
	if value == progress and flash <= 0.0:
		return
	progress = value
	flash = move_toward(flash, 0.0, delta * 3.4)
	queue_redraw()


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, vertices)


func _draw() -> void:
	if vertices.is_empty():
		return
	draw_colored_polygon(vertices, FILL.lightened(0.12) if is_hovered() else FILL)
	var edge := tint.lerp(Color.WHITE, flash * 0.72)
	for index in 6:
		var from := vertices[index]
		var to := vertices[(index + 1) % 6]
		draw_line(from, to, edge if progress < 0.0 else REST_EDGE, 1.8, true)
		var travelled := clampf(progress * 6.0 - index, 0.0, 1.0)
		if travelled > 0.0:
			draw_line(from, from.lerp(to, travelled), edge, 3.4, true)
		if flash > 0.0:
			draw_line(from, to, Color(edge, flash * 0.75), 3.2, true)
