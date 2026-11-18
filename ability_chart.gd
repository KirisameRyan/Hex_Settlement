extends Control

const FONT := preload("res://assets/fonts/LXGWWenKaiGB-Regular.ttf")
const SKILLS := ["采集", "狩猎", "建造", "搬运", "勘探"]
var values: Array = [3, 3, 3, 3, 3]


func _draw() -> void:
	var center := size * 0.5
	var shape := PackedVector2Array()
	for ring in [0.2, 0.4, 0.6, 0.8, 1.0]:
		for index in 5:
			var a := Vector2.from_angle(-PI / 2 + index * TAU / 5) * 56.0
			var b := Vector2.from_angle(-PI / 2 + (index + 1) * TAU / 5) * 56.0
			draw_line(center + a * ring, center + b * ring, Color("#a89570"), 1, true)
			if ring == 1.0:
				draw_line(center, center + a, Color("#a89570"), 1, true)
				shape.append(center + a * values[index] / 5.0)
	draw_colored_polygon(shape, Color(0.27, 0.43, 0.29, 0.44))
	shape.append(shape[0])
	draw_polyline(shape, Color("#41623e"), 2, true)
	for index in 5:
		var anchor := center + Vector2.from_angle(-PI / 2 + index * TAU / 5) * 76.0
		draw_string(FONT, anchor + Vector2(-14, 5), SKILLS[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#51432c"))
