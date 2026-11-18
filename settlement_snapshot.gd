extends RefCounted

const MAP_FIELDS := ["day", "day_elapsed", "commands", "center_stage", "pending_stage", "ending", "restored",
	"gathering_rate", "night_open", "night_ledger", "map_focus", "candidates", "stock", "site_stock", "delivered_today",
	"selected", "selected_resource", "menu", "speed_mode"]
const CAMPAIGN_FIELDS := ["level", "experience", "points", "learned", "claimed", "targets", "daily_resource", "explored", "built"]
const TRADE_FIELDS := ["coins", "trade_stock", "trade_orders", "trade_tools", "trader_cell", "ruin_cell"]
const Tile := preload("res://hex_tile.gd")


static func capture(game) -> Dictionary:
	var state := read_fields(game, MAP_FIELDS)
	state["campaign"] = read_fields(game.campaign, CAMPAIGN_FIELDS)
	state["trade"] = read_fields(game, TRADE_FIELDS)
	state["posts"] = {}
	state["tiles"] = {}
	state["workers"] = []
	state["houses"] = {}
	state["facilities"] = {}
	state["jobs"] = {}
	state["crews"] = {}
	state["pickups"] = []
	state["map_seed"] = game.map_seed
	state["river_network_version"] = game.river_network_version
	state["height_version"] = 2
	state["charms"] = game.charm_cells
	state["zoom"] = game.camera.size
	state["camera_turns"] = game.camera_turns
	state["high_camera"] = game.high_camera
	state["assigned"] = game.workers.find(game.assigned_worker)
	state["feedback"] = game.feedback.text
	for cell: Vector2i in game.tiles:
		var tile: Tile = game.tiles[cell]
		state.tiles[cell] = [tile.knowledge, tile.wood, tile.prey, tile.stone, tile.ore]
	for worker: Node3D in game.workers:
		state.workers.append({"name": worker.get_meta("resident_name"), "specialty": worker.get_meta("specialty"),
			"stats": worker.get_meta("stats"), "position": worker.position, "visible": worker.visible,
			"flip": worker.get_child(0).flip_h})
	for cell: Vector2i in game.houses:
		var home = game.houses[cell]
		var residents: Array[int] = []
		for worker in home.residents:
			residents.append(game.workers.find(worker))
		state.houses[cell] = {"level": home.level, "building": home.building, "residents": residents}
	for cell: Vector2i in game.facilities:
		var facility: Dictionary = game.facilities[cell]
		state.facilities[cell] = {"kind": facility.kind, "ready": facility.ready,
			"level": facility.level, "upgrading": facility.get("upgrading", false)}
	for worker: Node3D in game.post_residents:
		state.posts[game.workers.find(worker)] = game.post_residents[worker]
	for worker: Node3D in game.orders:
		var order: Dictionary = game.orders[worker]
		var saved := {"kind": order.kind, "target": order.target, "home": order.home, "route": order.route,
			"phase": order.phase, "travel": capture_motion(game, worker)}
		if order.phase == "work":
			saved["remaining"] = maxf(order.timer.time_left, 0.001)
		state.jobs[game.workers.find(worker)] = saved
	for key: Vector3i in game.crews:
		var crew = game.crews[key]
		var jobs := []
		for job in crew.jobs:
			jobs.append({"worker": game.workers.find(job.worker), "home": job.home, "route": job.route,
				"offset": job.offset, "load": job.load, "returning": job.returning, "remaining": job.timer.time_left,
				"travel": capture_motion(game, job.worker)})
		state.crews[key] = {"finishing": crew.finishing, "reserved": crew.reserved, "jobs": jobs}
	for trip in game.pickups.values():
		state.pickups.append({"worker": game.workers.find(trip.worker), "key": trip.key, "home": trip.home,
			"route": trip.route, "amount": trip.amount, "loaded": trip.loaded, "travel": capture_motion(game, trip.worker)})
	return state


static func restore(game, state: Dictionary) -> void:
	var previous_height_version: int = state.get("height_version", 0)
	if previous_height_version < 2:
		migrate_elevation(game, state, previous_height_version)
	restore_fields(game, state, MAP_FIELDS)
	if state.has("trade"):
		restore_fields(game, state.trade, TRADE_FIELDS)
	var legacy_food: bool = game.stock.size() < game.Gather.size()
	for values: Array in [game.stock, game.delivered_today]:
		while values.size() < game.Gather.size():
			values.append(0)
	if legacy_food:
		game.stock[game.Gather.CROPS] = game.stock[game.Gather.FOOD]
		game.stock[game.Gather.FOOD] = 0
	if game.night_open:
		for field in ["daytime", "landed", "consumed"]:
			while game.night_ledger[field].size() < game.Gather.size():
				game.night_ledger[field].append(0)
	restore_fields(game.campaign, state.campaign, CAMPAIGN_FIELDS)
	while game.campaign.learned.size() < game.campaign.RESEARCH.size():
		game.campaign.learned.append(false)
	game.surveyed_count = 0
	for cell: Vector2i in state.tiles:
		var tile: Tile = game.tiles[cell]
		var record: Array = state.tiles[cell]
		if record.size() > 3:
			tile.stone = record[3]
		if record.size() > 4:
			tile.ore = record[4]
		if record[0] != Tile.Knowledge.HIDDEN:
			game.reveal(cell, record[0])
		if record[0] == Tile.Knowledge.SURVEYED:
			game.surveyed_count += 1
		if tile.wood > record[1]:
			tile.harvest_wood(tile.wood - record[1])
		if tile.prey > record[2]:
			tile.harvest_prey(tile.prey - record[2])
	for index in state.workers.size():
		var record: Dictionary = state.workers[index]
		var worker: Node3D = game.workers[index] if index < game.workers.size() else game.add_resident(record.name, record.specialty)
		worker.set_meta("resident_name", record.name)
		worker.set_meta("specialty", record.specialty)
		worker.set_meta("stats", record.stats)
		worker.position = record.position
		worker.visible = record.visible
		worker.get_child(0).flip_h = record.flip
	for cell: Vector2i in state.houses:
		var record: Dictionary = state.houses[cell]
		var house = game.Housing.new()
		house.level = record.level
		house.building = record.building
		for id: int in record.residents:
			house.residents.append(game.workers[id])
		game.houses[cell] = house
		game.draw_house(cell, house)
	for cell: Vector2i in state.facilities:
		var site: Dictionary = state.facilities[cell].duplicate()
		site.level = site.get("level", int(site.ready))
		var model := Node3D.new()
		model.position = game.cell_position(cell)
		game.add_child(model)
		site.visual = model
		game.facilities[cell] = site
		game.paint_facility(site)
	for id: int in state.get("posts", {}):
		game.post_residents[game.workers[id]] = state.posts[id]
	game.draw_center()
	if state.has("charms"):
		for cell: Vector2i in state.charms:
			game.plant_charm(cell)
	else:
		var charm: Variant = state.get("charm")
		if charm is Array:
			charm = charm.back() if not charm.is_empty() else null
		if charm is Vector2i:
			game.plant_charm(charm)
	game.refresh_town()
	game.camera.size = state.zoom
	game.camera_turns = posmod(int(state.get("camera_turns", 0)), 6)
	game.high_camera = bool(state.get("high_camera", false))
	game.move_camera()
	if state.assigned >= 0:
		game.assigned_worker = game.workers[state.assigned]
	for id: int in state.jobs:
		restore_order(game, game.workers[id], state.jobs[id])
	for key: Vector3i in state.crews:
		var actual := key
		var facility: Dictionary = game.facilities.get(Vector2i(key.x, key.y), {})
		if legacy_food and key.z == game.Gather.FOOD and facility.get("kind") == game.Facility.FARM:
			actual.z = game.Gather.CROPS
		restore_crew(game, actual, state.crews[key])
	for record: Dictionary in state.pickups:
		restore_pickup(game, record)
	game.feedback.text = state.feedback
	if game.night_open:
		game.get_tree().paused = true
		game.show_night_ledger()
	else:
		game.change_speed(game.speed_mode)


static func migrate_elevation(game, state: Dictionary, version: int) -> void:
	for record: Dictionary in state.workers:
		record.position = lift_position(game, record.position, version)
	for record: Dictionary in state.jobs.values():
		lift_assignment(game, record, version)
	for crew: Dictionary in state.crews.values():
		for record: Dictionary in crew.jobs:
			lift_assignment(game, record, version)
	for record: Dictionary in state.pickups:
		lift_assignment(game, record, version)


static func lift_assignment(game, record: Dictionary, version: int) -> void:
	record.home = lift_position(game, record.home, version)
	var path: Array = record.travel.get("points", [])
	for index in path.size():
		path[index] = lift_position(game, path[index], version)


static func lift_position(game, position: Vector3, version: int) -> Vector3:
	var tile: Tile = game.tiles[game.nearest_cell(position)]
	var original: float = tile.previous_ground_height if version == 1 else Tile.HEIGHTS[tile.terrain]
	return position + Vector3.UP * (tile.ground_height - original)


static func read_fields(source: Object, keys: Array) -> Dictionary:
	var result := {}
	for key: String in keys:
		result[key] = source.get(key)
	return result


static func restore_fields(target: Object, state: Dictionary, keys: Array) -> void:
	for key: String in keys:
		target.set(key, state[key])


static func capture_motion(game, worker: Node3D) -> Dictionary:
	var active: Dictionary = game.travelling.get(worker, {})
	if active.is_empty():
		return {}
	var points: Array[Vector3] = []
	var times: Array[float] = []
	var elapsed: float = active.tween.get_total_elapsed_time()
	for index in active.times.size():
		var duration: float = active.times[index]
		if elapsed < duration:
			points.append(active.points[index])
			times.append(duration - elapsed)
			elapsed = 0.0
		else:
			elapsed -= duration
	return {"points": points, "times": times}


static func resume_motion(game, worker: Node3D, travel: Dictionary, arrival: Callable) -> Tween:
	var points: Array[Vector3] = []
	points.assign(travel.get("points", []))
	return game.move_along(worker, points, arrival, travel.get("times", []))


static func restore_order(game, worker: Node3D, record: Dictionary) -> void:
	var cell: Vector2i = record.target
	var route: Array[Vector2i] = []
	route.assign(record.route)
	var home: Vector3 = record.home
	game.register_order(worker, record.kind, cell, route, home)
	game.orders[worker].phase = record.phase
	var work: Callable
	var finish := Callable(game, "builder_return").bind(worker)
	if record.kind == "scout":
		game.open_scouts[cell] = worker
		work = Callable(game, "scouting_arrival")
		finish = Callable(game, "scouting_return").bind(cell, worker)
	elif record.kind != "carrier":
		game.builders[worker] = cell
		work = Callable(game, "build_housing") if record.kind == "house" else Callable(game, "build_facility")
	var args := [cell, worker, route, home]
	if record.kind == "house":
		args.insert(1, game.houses[cell])
	match record.phase:
		"work":
			args.append(record.remaining)
			work.callv(args)
		"return":
			resume_motion(game, worker, record.travel, finish)
		_:
			resume_motion(game, worker, record.travel, work.bindv(args))


static func restore_crew(game, key: Vector3i, record: Dictionary) -> void:
	var crew = game.GatheringCrew.new()
	crew.finishing = record.finishing
	crew.reserved = record.reserved
	game.crews[key] = crew
	var tile: Tile = game.tiles[Vector2i(key.x, key.y)]
	for entry: Dictionary in record.jobs:
		var job = game.GatheringJob.new()
		job.worker = game.workers[entry.worker]
		job.home = entry.home
		job.route.assign(entry.route)
		job.offset = entry.offset
		job.load = entry.load
		job.returning = entry.returning
		job.timer = Timer.new()
		job.timer.one_shot = true
		job.worker.add_child(job.timer)
		job.timer.timeout.connect(Callable(game, "complete_load").bind(tile, key, crew, job))
		crew.jobs.append(job)
		if not entry.travel.is_empty():
			var method := "gathering_return" if job.returning else "begin_load"
			resume_motion(game, job.worker, entry.travel, Callable(game, method).bind(tile, key, crew, job))
		else:
			job.timer.start(maxf(entry.remaining, 0.001))
	if key.z == game.Gather.STONE:
		game.refresh_quarry(Vector2i(key.x, key.y))


static func restore_pickup(game, record: Dictionary) -> void:
	var trip = game.Pickup.new()
	trip.key = record.key
	trip.worker = game.workers[record.worker]
	trip.route.assign(record.route)
	trip.home = record.home
	trip.amount = record.amount
	trip.loaded = record.loaded
	var id: int = trip.worker.get_instance_id()
	game.pickups[id] = trip
	var method := "deposit_pickup" if trip.loaded else "collect_pickup"
	if trip.loaded:
		game.draw_cargo(trip)
	trip.motion = resume_motion(game, trip.worker, record.travel, Callable(game, method).bind(id))
