extends Control

var requested := false
var strength := 0.0
var pulse := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	set_process(false)


func set_active(active: bool) -> void:
	requested = active and Session.glow
	set_process(requested or strength > 0.0)


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 1.0)
	strength = move_toward(strength, 1.0 if requested else 0.0, real_delta * 4.5)
	pulse = fmod(pulse + real_delta * 1.9, TAU)
	queue_redraw()
	if not requested and is_zero_approx(strength):
		set_process(false)


func _draw() -> void:
	if strength <= 0.0:
		return
	var width := minf(size.x, size.y) * 0.095
	var clear := Color(0.39, 0.74, 1.0, 0.0)
	var corners := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
	var inside := PackedVector2Array([Vector2(width, width), Vector2(size.x - width, width),
		size - Vector2(width, width), Vector2(width, size.y - width)])
	for index in 4:
		var next := (index + 1) % 4
		var edge := Color(0.43, 0.76, 1.0, (0.25 + sin(pulse + index * 1.6) * 0.055) * strength)
		draw_polygon(PackedVector2Array([corners[index], corners[next], inside[next], inside[index]]),
			PackedColorArray([edge, edge, clear, clear]))
