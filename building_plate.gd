extends Control

var caption: Label
var building: Node3D
var upgrade_hint: Label
var pulse: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption = Label.new()
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 13)
	caption.add_theme_color_override("font_color", Color("#f8e8c2"))
	add_child(caption)
	upgrade_hint = Label.new()
	upgrade_hint.text = "↑"
	upgrade_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_hint.add_theme_font_size_override("font_size", 17)
	upgrade_hint.add_theme_color_override("font_color", Color("#93dcff"))
	upgrade_hint.add_theme_color_override("font_outline_color", Color("#245a89"))
	upgrade_hint.add_theme_constant_override("outline_size", 7)
	upgrade_hint.hide()
	add_child(upgrade_hint)


func set_caption(value: String) -> void:
	if caption.text == value:
		return
	caption.text = value
	fit_caption()


func fit_caption() -> void:
	var text_width := caption.get_minimum_size().x + 23.0
	size = Vector2(text_width, 22)
	caption.size = size
	upgrade_hint.position = Vector2(text_width + 5, -1)
	queue_redraw()


func set_upgrade_ready(ready: bool) -> void:
	if upgrade_hint.visible == ready:
		return
	upgrade_hint.visible = ready
	if pulse != null:
		pulse.kill()
	if ready:
		upgrade_hint.modulate.a = 1.0
		pulse = create_tween().set_loops().set_trans(Tween.TRANS_SINE)
		var original := Vector2(size.x + 5, -1)
		pulse.tween_property(upgrade_hint, "position", original + Vector2(0, -5), 0.52)
		pulse.parallel().tween_property(upgrade_hint, "modulate:a", 0.56, 0.52)
		pulse.tween_property(upgrade_hint, "position", original, 0.52)
		pulse.parallel().tween_property(upgrade_hint, "modulate:a", 1.0, 0.52)
	fit_caption()


func _draw() -> void:
	var tip := 8.0
	var points := PackedVector2Array([Vector2(0, size.y / 2), Vector2(tip, 0),
		Vector2(size.x - tip, 0), Vector2(size.x, size.y / 2),
		Vector2(size.x - tip, size.y), Vector2(tip, size.y)])
	draw_colored_polygon(points, Color(0.09, 0.15, 0.13, 0.96))
	points.append(points[0])
	draw_polyline(points, Color("#b29965"), 1.35, true)
