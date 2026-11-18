extends RefCounted

const TREE_SITES := [Vector3(-0.26, 0, -0.27), Vector3(0.30, 0, 0.30)]
const FORESTS := [
	preload("res://assets/pixel/nature/forest-spring.png"), preload("res://assets/pixel/nature/forest-summer.png"),
	preload("res://assets/pixel/nature/forest-autumn.png"), preload("res://assets/pixel/nature/forest-winter.png"),
]
const MOUNTAINS := [
	preload("res://assets/pixel/nature/mountain-spring.png"), preload("res://assets/pixel/nature/mountain-summer.png"),
	preload("res://assets/pixel/nature/mountain-autumn.png"), preload("res://assets/pixel/nature/mountain-winter.png"),
]
const ANIMALS := [
	preload("res://assets/pixel/nature/deer.png"), preload("res://assets/pixel/nature/hare.png"),
	preload("res://assets/pixel/nature/boar.png"), preload("res://assets/pixel/nature/fox.png"),
]
const WATER_ART := preload("res://assets/pixel/ground/water.png")

var materials: Dictionary = {}
var peak_images: Dictionary = {}
var box_mesh := BoxMesh.new()


func forest(parent: Node3D, rng: RandomNumberGenerator, season: int) -> Array[AABB]:
	var hits: Array[AABB] = []
	for site: Vector3 in TREE_SITES:
		var at := site + Vector3(rng.randf_range(-0.08, 0.08), 0, rng.randf_range(-0.07, 0.07))
		var height := rng.randf_range(1.08, 1.30)
		var tree := nature_sprite(parent, FORESTS[season], at, height, 1.20)
		tree.flip_h = rng.randi_range(0, 1) == 1
		hits.append(AABB(at + Vector3(-0.53, 0, -0.16), Vector3(1.06, height, 0.34)))
	return hits


func mountain(parent: Node3D, rng: RandomNumberGenerator, season: int) -> Sprite3D:
	var peak := nature_sprite(parent, MOUNTAINS[season], Vector3(-0.05, 0, 0.20),
		rng.randf_range(1.20, 1.42), rng.randf_range(1.32, 1.49))
	peak.flip_h = rng.randi_range(0, 1) == 1
	return peak


func mountain_hit(peak: Sprite3D, origin: Vector3, direction: Vector3, normal: Vector3, right: Vector3) -> Variant:
	var contact: Variant = Plane(normal, peak.global_position).intersects_ray(origin, direction)
	if contact == null:
		return null
	var offset: Vector3 = (contact - peak.global_position) / peak.pixel_size
	var art := peak.texture
	var size := art.get_size()
	var pixel := Vector2i((Vector2(offset.dot(right), -offset.y) + size * 0.5).floor())
	if not Rect2i(Vector2i.ZERO, Vector2i(size)).has_point(pixel):
		return null
	if peak.flip_h:
		pixel.x = art.get_width() - 1 - pixel.x
	if not peak_images.has(art):
		peak_images[art] = art.get_image()
	var pixels: Image = peak_images[art]
	return contact if pixels.get_pixelv(pixel).a >= peak.alpha_scissor_threshold else null


func nature_sprite(parent: Node3D, art: Texture2D, ground: Vector3, height: float, width: float) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sprite.set_meta("ground", ground)
	sprite.set_meta("paint_size", Vector2(width, height))
	apply_sprite_art(sprite, art)
	parent.add_child(sprite)
	return sprite


func apply_sprite_art(sprite: Sprite3D, art: Texture2D) -> void:
	var ground: Vector3 = sprite.get_meta("ground")
	var limits: Vector2 = sprite.get_meta("paint_size")
	sprite.texture = art
	sprite.pixel_size = minf(limits.x / art.get_width(), limits.y / art.get_height())
	sprite.position = ground + Vector3.UP * (art.get_height() * sprite.pixel_size * 0.5 + 0.012)


func river(parent: Node3D, origin: Vector3, links: Dictionary) -> void:
	var upstream := hex_edge(links["in"]).normalized()
	var downstream := hex_edge(links.out).normalized()
	var spring := upstream == Vector3.ZERO
	var start := channel_port(origin, links["in"])
	if spring:
		upstream = hex_edge(links.get("spring", -links.out)).normalized()
		start = upstream * 0.77
	var finish := channel_port(origin, links.out)
	var scale: float = links.get("scale", 1.0)
	var curve := river_curve(origin, start, -upstream, finish, downstream)
	draw_channel(parent, origin, curve, -upstream, downstream, scale, spring, links.mouth)
	var tributaries: Dictionary = links.get("tributaries", {})
	for reach: Vector2i in tributaries:
		var toward_merge := -hex_edge(reach).normalized()
		var merge := curve[15]
		var merge_direction := (curve[16] - curve[14]).normalized()
		var branch := river_curve(origin, channel_port(origin, reach), toward_merge, merge, merge_direction)
		draw_channel(parent, origin, branch, toward_merge, merge_direction, tributaries[reach], false, false)


func hex_edge(direction: Vector2i) -> Vector3:
	return Vector3(1.5 * direction.x, 0.0, sqrt(3.0) * (direction.y + direction.x * 0.5)) * 0.5


func channel_port(origin: Vector3, direction: Vector2i) -> Vector3:
	var edge := hex_edge(direction)
	var midpoint := origin + edge
	var axis := Vector3.UP.cross(edge.normalized())
	if direction.x < 0 or (direction.x == 0 and direction.y < 0):
		axis = -axis
	return edge + axis * sin(midpoint.x * 2.4 + midpoint.z * 1.7) * 0.10


func river_curve(origin: Vector3, start: Vector3, entering: Vector3, finish: Vector3, leaving: Vector3) -> PackedVector3Array:
	var curve := PackedVector3Array()
	var handle := start.distance_to(finish) * 0.36
	var a := start + entering * handle
	var b := finish - leaving * handle
	for segment in 25:
		var t := segment / 24.0
		var point := start.bezier_interpolate(a, b, finish, t)
		var normal := Vector3.UP.cross(start.bezier_derivative(a, b, finish, t).normalized())
		var world := origin + point
		var sway := sin(world.x * 4.3 + world.z * 3.7) * 0.087 + sin(world.x * 6.1 - world.z * 8.2) * 0.039
		var envelope := sin(t * PI)
		curve.append(point + normal * sway * envelope * envelope)
	return curve


func draw_channel(parent: Node3D, origin: Vector3, curve: PackedVector3Array, entering: Vector3,
		leaving: Vector3, scale: float, spring: bool, mouth: bool) -> void:
	var bank := SurfaceTool.new()
	var water := SurfaceTool.new()
	bank.begin(Mesh.PRIMITIVE_TRIANGLES)
	water.begin(Mesh.PRIMITIVE_TRIANGLES)
	var last_bank := PackedVector3Array()
	var last_water := PackedVector3Array()
	for segment in curve.size():
		var t := float(segment) / (curve.size() - 1)
		var point := curve[segment]
		var direction := entering if segment == 0 else leaving
		if segment > 0 and segment < curve.size() - 1:
			direction = (curve[segment + 1] - curve[segment - 1]).normalized()
		var across := Vector3.UP.cross(direction)
		var world := origin + point
		var width := scale * (0.178 + sin(world.x * 3.5 + world.z * 2.5) * 0.025)
		if spring:
			width *= lerpf(0.16, 1.0, smoothstep(0.0, 0.53, t))
		if mouth:
			width *= lerpf(1.0, 1.62, smoothstep(0.48, 1.0, t))
		var fringe := scale * (0.035 + sin(t * PI) * sin(t * 36.0) * 0.016)
		var bank_span := PackedVector3Array([point - across * (width + fringe), point + across * (width + fringe)])
		var water_span := PackedVector3Array([point - across * width, point + across * width])
		if segment > 0:
			add_channel_strip(bank, origin, last_bank, bank_span, 0.007)
			add_channel_strip(water, origin, last_water, water_span, 0.014)
		last_bank = bank_span
		last_water = water_span
	part(parent, bank.commit(), Vector3.ZERO, Vector3.ONE, "#6d754c", false, true)
	var stream := part(parent, water.commit(), Vector3.ZERO, Vector3.ONE, "#81bdca", false, true)
	var water_material := stream.material_override.duplicate() as StandardMaterial3D
	water_material.albedo_texture = WATER_ART
	water_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	water_material.roughness = 1.0
	stream.material_override = water_material


func add_channel_strip(mesh: SurfaceTool, origin: Vector3, previous: PackedVector3Array,
		current: PackedVector3Array, height: float) -> void:
	for vertex: Vector3 in [previous[0], previous[1], current[0], previous[1], current[1], current[0]]:
		mesh.set_normal(Vector3.UP)
		mesh.set_uv(Vector2(vertex.x + origin.x, vertex.z + origin.z) * 0.36)
		mesh.add_vertex(vertex + Vector3.UP * height)

func animal(parent: Node3D, species: int, location: Vector3, stride: Vector3) -> void:
	var actor := Node3D.new()
	actor.position = location
	parent.add_child(actor)
	var heights := [0.39, 0.24, 0.30, 0.31]
	var sprite := nature_sprite(actor, ANIMALS[species], Vector3.ZERO, heights[species], 0.46)
	sprite.flip_h = stride.x > 0.0
	var wander := actor.create_tween().set_loops()
	wander.tween_interval(2.0 + species * 0.46)
	wander.tween_property(actor, "position", location + stride, 1.25).set_trans(Tween.TRANS_SINE)
	wander.tween_interval(2.4)
	wander.tween_callback(sprite.set_flip_h.bind(stride.x <= 0.0))
	wander.tween_property(actor, "position", location, 1.25).set_trans(Tween.TRANS_SINE)
	wander.tween_callback(sprite.set_flip_h.bind(stride.x > 0.0))


func box(parent: Node3D, location: Vector3, size: Vector3, color: String) -> MeshInstance3D:
	return part(parent, box_mesh, location, size, color)


func part(parent: Node3D, mesh: Mesh, location: Vector3, scale: Vector3, color: String,
		vertex_color := false, double_sided := false) -> MeshInstance3D:
	var key := [color, vertex_color, double_sided]
	var material: StandardMaterial3D = materials.get(key)
	if material == null:
		material = StandardMaterial3D.new()
		material.albedo_color = Color(color)
		material.roughness = 0.95
		material.metallic_specular = 0.0
		material.vertex_color_use_as_albedo = vertex_color
		if double_sided:
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		materials[key] = material
	var visual := MeshInstance3D.new()
	visual.mesh = mesh
	visual.material_override = material
	visual.position = location
	visual.scale = scale
	parent.add_child(visual)
	return visual
