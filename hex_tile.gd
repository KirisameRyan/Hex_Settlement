extends Node3D

const Scenery := preload("res://scenery.gd")

enum Knowledge { HIDDEN, SEEN, SURVEYED }

const LEVEL_INSET := 0.72
const HEX_HEIGHT := 0.8660254
const BASE_HEIGHT := -0.46
const CORNERS := [
	Vector2(1, 0), Vector2(0.5, HEX_HEIGHT), Vector2(-0.5, HEX_HEIGHT),
	Vector2(-1, 0), Vector2(-0.5, -HEX_HEIGHT), Vector2(0.5, -HEX_HEIGHT),
]
const TEXTURES := {
	"cleared": preload("res://assets/pixel/ground/cleared-land.png"),
	"mountains": preload("res://assets/pixel/ground/mountain-scree.png"),
	"lake": Scenery.WATER_ART,
}
const HEIGHTS := {
	"grassland": 0.0, "cleared": 0.0, "forest": 0.0,
	"mountains": 0.17, "lake": -0.10, "river": -0.10,
}
const GROUND_TINTS := {
	"lake": Color("#81bdca"), "river": Color("#ddd3a1"),
}
const SEASON_GROUND := [
	preload("res://assets/pixel/ground/meadow-spring.png"), preload("res://assets/pixel/ground/meadow-summer.png"),
	preload("res://assets/pixel/ground/meadow-autumn.png"), preload("res://assets/pixel/ground/meadow-winter.png"),
]
const SEASON_TINTS := [Color("#c2cbb8"), Color("#cad1c2"), Color("#d4cebd"), Color("#bac6d6")]
const SEEN_BRIGHTNESS := 0.80
const SOIL_WALL := preload("res://assets/pixel/ground/soil-wall.png")
const ROCK_WALL := preload("res://assets/pixel/ground/rock-wall.png")
const PAVING := preload("res://assets/pixel/ground/town-paving.png")
const TRAVEL_FACTORS := {"grassland": 1.0, "cleared": 1.0, "forest": 1.35,
	"mountains": 1.80, "river": 1.70, "lake": 2.0}

var terrain: String
var resources: String
var wood := 0
var initial_wood := 0
var prey := 0
var initial_prey := 0
var stone := 0
var ore := 0
var initial_stone := 0
var quarry: Sprite3D
var town_ground: Texture2D
var rune_glow: MeshInstance3D
var knowledge := Knowledge.HIDDEN
var elevation := 0.0
var ground_height := 0.0
var previous_ground_height := 0.0
var season := 0
var peak: Sprite3D
var top: MeshInstance3D
var sides: MeshInstance3D
var outline: MeshInstance3D
var scenery: Node3D
var wildlife: Node3D
var trees: Node3D
var pick_bounds: Array[AABB] = []
var top_material := StandardMaterial3D.new()
var side_material := StandardMaterial3D.new()
var outline_material := StandardMaterial3D.new()
var rim_heights: PackedFloat32Array
var floor_faces := PackedVector3Array()
var floor_bounds := AABB()
var edge_material: ShaderMaterial
var material_season := -1
var material_knowledge := -1
var material_ground := -1
var ground_neighbors: PackedInt32Array
var ground_neighbor_light: PackedFloat32Array


func build(kind: String, contents: String) -> void:
	terrain = kind
	resources = contents
	top = MeshInstance3D.new()
	top.mesh = make_top()
	top_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	top_material.roughness = 1.0
	top_material.metallic_specular = 0.0
	top_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	top.material_override = top_material
	floor_bounds = top.mesh.get_aabb().grow(0.005)
	add_child(top)

	sides = MeshInstance3D.new()
	side_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	side_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	side_material.vertex_color_use_as_albedo = true
	side_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(sides)

	outline = MeshInstance3D.new()
	outline.mesh = make_outline()
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	outline.material_override = outline_material
	outline.visible = false
	add_child(outline)
	reveal(Knowledge.HIDDEN)


func reveal(state: Knowledge) -> void:
	knowledge = state
	elevation = -0.18 if knowledge == Knowledge.HIDDEN else ground_height
	top.position.y = elevation
	outline.position.y = elevation + 0.014
	refresh_ground()


func refresh_ground() -> void:
	var ground_tint: Color = GROUND_TINTS.get(terrain, Color.WHITE)
	var ground: Texture2D = TEXTURES.get(terrain, SEASON_GROUND[season])
	if terrain in ["grassland", "forest", "river"] or (season == 3 and terrain in ["cleared", "mountains"]):
		ground = SEASON_GROUND[season]
		ground_tint = SEASON_TINTS[season]
	match knowledge:
		Knowledge.HIDDEN:
			top.material_override = top_material
			top_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			top_material.albedo_texture = null
			top_material.albedo_color = Color("#233632")
			side_material.albedo_color = Color("#3b4c43")
			side_material.albedo_texture = null
		Knowledge.SEEN:
			top_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			top_material.albedo_texture = ground
			top_material.albedo_color = ground_tint * Color("#778d9e")
			side_material.albedo_color = Color("#a0afbd") if season == 3 else Color("#a1a79b")
			side_material.albedo_texture = side_texture()
		Knowledge.SURVEYED:
			top_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			top_material.albedo_texture = town_ground if town_ground != null else ground
			top_material.albedo_color = ground_tint
			side_material.albedo_color = Color("#bacedc") if season == 3 else Color.WHITE
			side_material.albedo_texture = side_texture()


func side_texture() -> Texture2D:
	return ROCK_WALL if terrain in ["mountains", "lake", "river"] else SOIL_WALL


func set_town_ground(texture: Texture2D) -> void:
	if town_ground == texture:
		return
	town_ground = texture
	refresh_ground()


func set_rune_glow(active: bool) -> void:
	if active and rune_glow == null:
		var mesh := SurfaceTool.new()
		mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
		for index in CORNERS.size():
			var a: Vector2 = CORNERS[index]
			var b: Vector2 = CORNERS[(index + 1) % CORNERS.size()]
			for step in [0, 1, 2, 0, 2, 3]:
				var corner := a if step == 0 or step == 3 else b
				var inside: bool = step >= 2
				mesh.set_uv(Vector2(1.0 if inside else 0.0, 0.0))
				var radius := 0.805 if inside else 0.985
				var local := Vector3(corner.x * radius, 0, corner.y * radius)
				local.y = surface_height(position + local) - elevation
				mesh.add_vertex(local)
		rune_glow = MeshInstance3D.new()
		rune_glow.mesh = mesh.commit()
		rune_glow.position.y = elevation + 0.021
		rune_glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var material := ShaderMaterial.new()
		material.shader = preload("res://rune_glow.gdshader")
		rune_glow.material_override = material
		add_child(rune_glow)
	if rune_glow != null:
		rune_glow.visible = active


func update_edges(neighbor_heights: Array[float]) -> void:
	sides.mesh = make_sides(neighbor_heights)
	sides.visible = sides.mesh != null
	if sides.visible:
		sides.material_override = side_material


func shape_floor(heights: PackedFloat32Array) -> void:
	if rim_heights == heights:
		return
	rim_heights = heights
	top.mesh = make_top()
	floor_bounds = top.mesh.get_aabb().grow(0.005)
	outline.mesh = make_outline()
	if rune_glow != null and rune_glow.visible:
		rune_glow.hide()
		rune_glow.queue_free()
		rune_glow = null
		set_rune_glow(true)


func rim_point(index: int) -> Vector3:
	var point: Vector2 = CORNERS[index]
	var height := rim_heights[index] if rim_heights.size() == 6 else 0.0
	return Vector3(point.x, height, point.y)


func floor_hit(origin: Vector3, direction: Vector3) -> Variant:
	var anchor := position + Vector3.UP * elevation
	var start := origin - anchor
	if floor_faces.is_empty() or floor_bounds.intersects_ray(start, direction) == null:
		return null
	var closest := INF
	var result: Variant = null
	for index in range(0, floor_faces.size(), 3):
		var point: Variant = Geometry3D.ray_intersects_triangle(start, direction,
			floor_faces[index], floor_faces[index + 1], floor_faces[index + 2])
		if point != null:
			var depth: float = (point - start).dot(direction)
			if depth < closest:
				closest = depth
				result = anchor + point
	return result


func surface_height(point: Vector3) -> float:
	var surface: Variant = floor_hit(Vector3(point.x, elevation + 2.0, point.z), Vector3.DOWN)
	return surface.y if surface != null else elevation


func ground_class() -> int:
	if knowledge == Knowledge.HIDDEN or terrain == "lake":
		return -1
	if town_ground == PAVING:
		return 3
	if town_ground == TEXTURES["cleared"] or (terrain == "cleared" and season != 3):
		return 1
	if terrain == "mountains" and season != 3:
		return 2
	return 0


func ground_brightness() -> float:
	return SEEN_BRIGHTNESS if knowledge == Knowledge.SEEN else 1.0


func set_ground_neighbors(kinds: PackedInt32Array, brightness: PackedFloat32Array) -> void:
	var current := ground_class()
	if current < 0:
		top.material_override = top_material
		return
	if edge_material == null:
		edge_material = ShaderMaterial.new()
		edge_material.shader = preload("res://ground_edges.gdshader")
		edge_material.set_shader_parameter("dirt", TEXTURES["cleared"])
		edge_material.set_shader_parameter("stone", TEXTURES["mountains"])
		edge_material.set_shader_parameter("paving", PAVING)
	if top.material_override != edge_material:
		top.material_override = edge_material
	if material_season != season:
		material_season = season
		edge_material.set_shader_parameter("meadow", SEASON_GROUND[season])
		edge_material.set_shader_parameter("meadow_tint", SEASON_TINTS[season])
	if material_knowledge != knowledge:
		material_knowledge = knowledge
		edge_material.set_shader_parameter("visibility", ground_brightness())
	if material_ground != current or ground_neighbors != kinds:
		material_ground = current
		ground_neighbors = kinds
		edge_material.set_shader_parameter("ground", current)
		edge_material.set_shader_parameter("neighbor_ground", kinds)
	if ground_neighbor_light != brightness:
		ground_neighbor_light = brightness
		edge_material.set_shader_parameter("neighbor_visibility", brightness)


func mark(color: Color) -> void:
	outline.visible = color.a > 0
	outline_material.albedo_color = color


func harvest_wood(amount: int) -> int:
	var load := mini(wood, amount)
	wood -= load
	var standing := ceili(float(wood) * Scenery.TREE_SITES.size() / initial_wood)
	while pick_bounds.size() > standing:
		var tree := trees.get_child(pick_bounds.size() - 1) as Node3D
		tree.hide()
		trees.remove_child(tree)
		tree.queue_free()
		pick_bounds.pop_back()
	if wood == 0:
		terrain = "cleared"
		resources = "适合建造"
		harvest_prey(prey)
		reveal(knowledge)
	return load


func harvest_prey(amount: int) -> int:
	var load := mini(prey, amount)
	prey -= load
	if wildlife == null:
		return load
	var displayed := 2 if terrain == "grassland" else 1
	var remaining_models := ceili(float(prey) * displayed / initial_prey)
	for index in range(wildlife.get_child_count() - 1, remaining_models - 1, -1):
		var animal := wildlife.get_child(index) as Node3D
		wildlife.remove_child(animal)
		animal.queue_free()
	return load


func make_top() -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	floor_faces.clear()
	for index in CORNERS.size():
		var outer := rim_point(index)
		var next := rim_point((index + 1) % 6)
		var inner := Vector3(outer.x, 0, outer.z) * LEVEL_INSET
		var inner_next := Vector3(next.x, 0, next.z) * LEVEL_INSET
		add_top_triangle(mesh, Vector3.ZERO, inner, inner_next)
		add_top_triangle(mesh, inner, outer, next)
		add_top_triangle(mesh, inner, next, inner_next)
	return mesh.commit()


func add_top_triangle(mesh: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (c - a).cross(b - a).normalized()
	var texture_scale := Vector2(0.30, 0.36) if terrain == "lake" else Vector2(0.477, 0.519)
	for point: Vector3 in [a, b, c]:
		mesh.set_uv(Vector2(0.5, 0.5) + Vector2(point.x, point.z) * texture_scale)
		mesh.set_normal(normal)
		mesh.add_vertex(point)
		floor_faces.append(point)


func make_sides(neighbor_heights: Array[float]) -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	var has_edge := false
	for index in CORNERS.size():
		var lower := neighbor_heights[index]
		var high_a := rim_point(index) + Vector3.UP * elevation
		var high_b := rim_point((index + 1) % 6) + Vector3.UP * elevation
		if lower >= maxf(high_a.y, high_b.y):
			continue
		has_edge = true
		var low_a := Vector3(high_a.x, minf(lower, high_a.y), high_a.z)
		var low_b := Vector3(high_b.x, minf(lower, high_b.y), high_b.z)
		var shade: float = [0.88, 0.93, 1.0, 0.88, 0.79, 0.76][index]
		var points := [high_a, high_b, low_a, low_b]
		var coordinates := [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]
		for vertex in [0, 1, 2, 1, 3, 2]:
			var tint := shade * (0.86 if vertex > 1 else 1.0)
			mesh.set_color(Color(tint, tint, tint))
			mesh.set_uv(coordinates[vertex])
			mesh.add_vertex(points[vertex])
	return mesh.commit() if has_edge else null


func make_outline() -> ArrayMesh:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in CORNERS.size():
		var a := rim_point(index)
		var b := rim_point((index + 1) % 6)
		var outer_a := outline_point(a, 0.985)
		var outer_b := outline_point(b, 0.985)
		var inner_a := outline_point(a, 0.952)
		var inner_b := outline_point(b, 0.952)
		for point: Vector3 in [outer_a, outer_b, inner_b, outer_a, inner_b, inner_a]:
			mesh.add_vertex(point)
	return mesh.commit()


func outline_point(rim: Vector3, radius: float) -> Vector3:
	return Vector3(rim.x * radius, rim.y * ((radius - LEVEL_INSET) / (1.0 - LEVEL_INSET)), rim.z * radius)

