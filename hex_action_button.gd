extends Button

var title := ""
var symbol := ""
var compact := false


func _ready() -> void:
	compact = symbol in ["work", "upgrade"]
	custom_minimum_size = Vector2(65, 52) if compact else Vector2(79, 64)
	flat = true
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)


func set_title(value: String) -> void:
	title = value
	queue_redraw()


func _draw() -> void:
	var middle := size.x / 2.0
	var bevel := 16.0 if compact else 19.0
	var vertices := PackedVector2Array([Vector2(2, size.y / 2.0), Vector2(bevel, 2),
		Vector2(size.x - bevel, 2), Vector2(size.x - 2, size.y / 2.0),
		Vector2(size.x - bevel, size.y - 2), Vector2(bevel, size.y - 2)])
	var active := is_hovered() or has_focus()
	var ink := Color("#bbbcb8") if disabled else Color("#fff0c7")
	var border := Color("#717874") if disabled else (Color("#f4d595") if active else Color("#c3a46a"))
	var fill := Color("#2d3331") if disabled else (Color("#3c5a47") if active else Color("#1d352b"))
	draw_colored_polygon(vertices, fill)
	vertices.append(vertices[0])
	draw_polyline(vertices, border, 1.8, true)
	var at := Vector2(middle, 17 if compact else 22)
	match symbol:
		"upgrade":
			draw_polyline(PackedVector2Array([at + Vector2(-8, 2), at + Vector2(0, -6), at + Vector2(8, 2)]), ink, 2.8, true)
			draw_line(at + Vector2(0, -5), at + Vector2(0, 9), ink, 2.8, true)
		"work", "build":
			draw_line(at + Vector2(-7, 9), at + Vector2(5, -3), ink, 3.2, true)
			draw_line(at + Vector2(-2, -7), at + Vector2(9, 4), ink, 5.0, true)
		"people":
			draw_circle(at + Vector2(0, -5), 3.5, ink)
			draw_arc(at + Vector2(0, 9), 7, PI, TAU, 12, ink, 2.8, true)
		_:
			draw_rect(Rect2(at - Vector2(8, 6), Vector2(16, 13)), ink, false, 2)
			draw_line(at + Vector2(-8, -1), at + Vector2(8, -1), ink, 2)
	var font := get_theme_font("font")
	var font_size := 14 if compact else 15
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var baseline := size.y - (10 if compact else 14)
	draw_string(font, Vector2(middle - width / 2.0, baseline), title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)
