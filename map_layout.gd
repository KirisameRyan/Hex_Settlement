extends RefCounted

const RADIUS := 6
const RIVER_NETWORK_VERSION := 1
const DIRECTIONS := [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]

var terrain: Dictionary = {}
var river_links: Dictionary = {}
var river_path: Array[Vector2i] = []
var source: Vector2i
var mouth: Vector2i
var hunting_ground: Vector2i


func _init(seed_value: int, river_network := RIVER_NETWORK_VERSION) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rotation := rng.randi_range(0, 5)
	var noise := FastNoiseLite.new()
	noise.seed = int(seed_value % 2147483647)
	noise.frequency = 0.29
	for q in range(-RADIUS, RADIUS + 1):
		for r in range(-RADIUS, RADIUS + 1):
			if maxi(absi(q), maxi(absi(r), absi(q + r))) > RADIUS:
				continue
			var value := noise.get_noise_2d(q + r * 0.5, r * 0.86)
			terrain[rotate_cell(Vector2i(q, r), rotation)] = "mountains" if value > 0.27 else (
				"forest" if value < -0.13 else "grassland")
	var headwater_options := [
		[Vector2i(2, -5), Vector2i(2, -4), Vector2i(2, -3), Vector2i(1, -3), Vector2i(1, -2)],
		[Vector2i(0, -4), Vector2i(0, -3), Vector2i(1, -3), Vector2i(2, -3), Vector2i(2, -2)],
		[Vector2i(3, -5), Vector2i(2, -4), Vector2i(2, -3), Vector2i(1, -2)],
	]
	var river: Array = headwater_options[rng.randi_range(0, headwater_options.size() - 1)].duplicate()
	source = rotate_cell(river.pop_front(), rotation)
	river.append_array([Vector2i(1, -1), Vector2i(1, 0), Vector2i(1, 1)])
	if rng.randi_range(0, 1) == 0:
		river.append_array([Vector2i(1, 2), Vector2i(1, 3)])
		mouth = rotate_cell(Vector2i(1, 4), rotation)
		for cell: Vector2i in [Vector2i(1, 4), Vector2i(2, 3), Vector2i(2, 4), Vector2i(0, 5), Vector2i(1, 5)]:
			terrain[rotate_cell(cell, rotation)] = "lake"
	else:
		river.append_array([Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)])
		mouth = rotate_cell(Vector2i(4, 2), rotation)
		for cell: Vector2i in [Vector2i(4, 2), Vector2i(4, 1), Vector2i(5, 1), Vector2i(5, 0), Vector2i(4, 0)]:
			terrain[rotate_cell(cell, rotation)] = "lake"
	for cell: Vector2i in river:
		var point := rotate_cell(cell, rotation)
		river_path.append(point)
		terrain[point] = "river"
	for index in river_path.size():
		var cell := river_path[index]
		var downstream := mouth if index == river_path.size() - 1 else river_path[index + 1]
		river_links[cell] = {
			"in": Vector2i.ZERO if index == 0 else river_path[index - 1] - cell,
			"out": downstream - cell,
			"mouth": downstream == mouth,
			"spring": source - cell if index == 0 else Vector2i.ZERO,
		}
	terrain[source] = "mountains"
	var ridge := 0
	for offset: Vector2i in DIRECTIONS:
		var next := source + offset
		if not terrain.has(next) or terrain[next] in ["river", "lake"]:
			continue
		terrain[next] = "mountains"
		ridge += 1
		if ridge == 2:
			break
	for cell: Vector2i in [Vector2i.ZERO, Vector2i(0, 1), Vector2i(-1, 1), Vector2i(2, 0)]:
		terrain[rotate_cell(cell, rotation)] = "cleared"
	terrain[rotate_cell(Vector2i(-1, 0), rotation)] = "forest"
	terrain[rotate_cell(Vector2i(0, -1), rotation)] = "mountains"
	terrain[rotate_cell(Vector2i(2, -1), rotation)] = "forest"
	hunting_ground = rotate_cell(Vector2i(-1, 2), rotation) if rng.randi_range(0, 1) == 0 else rotate_cell(Vector2i(-2, 1), rotation)
	terrain[hunting_ground] = "grassland"
	if river_network >= 1:
		if rng.randf() < 0.80:
			var west := [Vector2i(-3, 4), Vector2i(-2, 4), Vector2i(-1, 3), Vector2i(0, 2), Vector2i(1, 2)]
			if rng.randi_range(0, 1) == 1:
				west = [Vector2i(-3, 5), Vector2i(-2, 5), Vector2i(-1, 4), Vector2i(0, 3), Vector2i(1, 2)]
			add_watercourse(west, rotation, 0.61)
		if rng.randf() < 0.35:
			add_watercourse([Vector2i(4, -2), Vector2i(3, -1), Vector2i(3, 0), Vector2i(2, 1), Vector2i(1, 1)], rotation, 0.56)
		if rng.randf() < 0.55:
			var lake_inlet := [Vector2i(6, -3), Vector2i(5, -2), Vector2i(5, -1), Vector2i(5, 0)]
			if mouth == rotate_cell(Vector2i(1, 4), rotation):
				lake_inlet = [Vector2i(6, -1), Vector2i(5, 0), Vector2i(4, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(2, 3)]
			add_watercourse(lake_inlet, rotation, 0.75)


func add_watercourse(route: Array, rotation: int, scale: float) -> void:
	var headwater := rotate_cell(route[0], rotation)
	var destination := rotate_cell(route[-1], rotation)
	terrain[headwater] = "mountains"
	for index in range(1, route.size() - 1):
		var cell := rotate_cell(route[index], rotation)
		var previous := rotate_cell(route[index - 1], rotation)
		var next := rotate_cell(route[index + 1], rotation)
		terrain[cell] = "river"
		river_links[cell] = {
			"in": Vector2i.ZERO if index == 1 else previous - cell,
			"out": next - cell,
			"spring": previous - cell if index == 1 else Vector2i.ZERO,
			"mouth": terrain[next] == "lake",
			"scale": scale,
		}
	if river_links.has(destination):
		var last := rotate_cell(route[-2], rotation)
		river_links[destination]["tributaries"] = {last - destination: scale}


static func rotate_cell(cell: Vector2i, turns: int) -> Vector2i:
	for turn in turns:
		cell = Vector2i(-cell.y, cell.x + cell.y)
	return cell
