extends Node3D

class GatheringJob:
	var worker: Node3D
	var timer: Timer
	var route: Array[Vector2i]
	var offset: Vector3
	var home: Vector3
	var load := 0
	var returning := false

class GatheringCrew:
	var jobs: Array[GatheringJob] = []
	var finishing := false
	var reserved := 0

class Pickup:
	var key: Vector3i
	var worker: Node3D
	var home: Vector3
	var route: Array[Vector2i]
	var amount: int
	var loaded := false
	var motion: Tween
	var cargo: MeshInstance3D

enum Gather { WOOD, FOOD, WATER, STONE, ORE, IRON, CROPS, FISH, PART }
enum Menu { CLOSED, FIELD, TOWN }
enum Facility { FARM, PASTURE, WORKSHOP, WAREHOUSE, TREE_FARM, BRIDGE, QUARRY, MINE, SMITHY, STATION, SHOP, FISHERY, MAGIC, RUIN }

class Housing:
	var level := 0
	var residents: Array[Node3D] = []
	var visual: Node3D
	var building := false

const HOUSING_COSTS := [18, 24, 32]
const HOUSING_TIMES := [10.0, 14.0, 18.0]
const CENTER_NAMES := ["小聚落", "小村庄", "大城镇"]
const RECRUIT_NAMES := ["小椿", "枫", "千寻", "葵", "朝雾", "青叶", "小满", "穗乃"]
const Campaign := preload("res://campaign.gd")
const Snapshot := preload("res://settlement_snapshot.gd")
const MapLayout := preload("res://map_layout.gd")
const PauseMenu := preload("res://pause_menu.gd")
const SpeedGlow := preload("res://speed_glow.gd")
const ProgressionWindow := preload("res://progression_window.gd")
const FACILITY_NAMES := ["基础农田", "牧场", "木工作坊", "大型仓库", "树场", "木桥", "采石场", "采矿场", "铁匠铺", "驿站", "香霖堂·临时铺", "渔埠", "魔理沙的魔法工房", "古驿站"]
const FACILITY_COSTS := [12, 18, 20, 24, 16, 12, 18, 22, 24, 22, 18, 16, 26, 16]
const BRIDGE_STONE := 10
const FACILITY_SPELLS := [Campaign.Spell.FARMING, Campaign.Spell.HUSBANDRY,
	Campaign.Spell.CARPENTRY, Campaign.Spell.WAREHOUSING, Campaign.Spell.FORESTRY]
const STARTERS := ["罗文", "艾琳", "贝克", "米拉", "芬恩", "艾尔"]
const STARTER_STATS := [[5, 2, 3, 4, 3], [3, 5, 2, 3, 4], [2, 3, 5, 4, 2], [4, 2, 3, 5, 3], [3, 4, 2, 3, 5], [4, 3, 4, 2, 3]]
const Tile := preload("res://hex_tile.gd")
const Scenery := preload("res://scenery.gd")
const Journal := preload("res://settlement_journal.gd")
const GameHud := preload("res://game_hud.gd")
const ResourceIcon := preload("res://resource_icon.gd")
const FieldBadge := preload("res://field_badge.gd")
const BuildingPlate := preload("res://building_plate.gd")
const SidePanel := preload("res://side_panel.gd")
const VILLAGER := preload("res://assets/characters/villager-walk.png")
const VILLAGER_WALK_FRAMES := 8
const VILLAGER_STRIDE := 0.30
const HOUSE_ART := [
	preload("res://assets/pixel/buildings/camp-tent.png"),
	preload("res://assets/pixel/buildings/village-cottage.png"),
	preload("res://assets/pixel/buildings/town-house.png"),
]
const PORTRAITS := [
	preload("res://assets/characters/marisa-spring.png"), preload("res://assets/characters/marisa-summer.png"),
	preload("res://assets/characters/marisa-autumn.png"), preload("res://assets/characters/marisa-winter.png"),
]
const COUNCIL_ART := [
	preload("res://assets/pixel/buildings/council-camp.png"), preload("res://assets/pixel/buildings/council-village.png"),
	preload("res://assets/pixel/buildings/council-town.png"),
]
const FACILITY_ART := [
	preload("res://assets/pixel/buildings/farm.png"), preload("res://assets/pixel/buildings/pasture.png"),
	preload("res://assets/pixel/buildings/workshop.png"), preload("res://assets/pixel/buildings/warehouse.png"),
	preload("res://assets/pixel/buildings/tree-farm.png"),
	preload("res://assets/pixel/buildings/river-bridge.png"),
	preload("res://assets/pixel/buildings/quarry-lv1.png"), preload("res://assets/pixel/buildings/iron-mine-lv1.png"),
	preload("res://assets/pixel/buildings/smithy-lv1.png"), preload("res://assets/pixel/buildings/waystation-lv1.png"),
	preload("res://assets/pixel/buildings/trade-shop-lv1.png"), preload("res://assets/pixel/buildings/fishery-lv1.png"),
	preload("res://assets/pixel/buildings/magic-workshop-lv1.png"), preload("res://assets/pixel/buildings/ancient-waystation-restored.png"),
]
const FACILITY_SPRITES := ["farm", "pasture", "workshop", "warehouse", "tree-farm", "river-bridge",
	"quarry", "iron-mine", "smithy", "waystation", "trade-shop", "fishery", "magic-workshop"]
const FACILITY_DESCRIPTIONS := ["持续生产农产品", "持续生产兽肉", "降低建造费用", "增加仓库容量",
	"持续生产木头", "连接两岸", "提高石料采集能力，仍消耗本格储量", "在探明的矿脉开采铁矿",
	"用铁矿和木头锻造铁件", "可安排居民驻扎，接通后缩短驿路通行时间",
	"买卖基础物资，库存和收购额度随补货更新", "在河湖岸边持续生产鱼肉",
	"用铁件与石头制作修复部件", "修复后揭开附近地形，并可安排居民驻扎"]
const RUIN_ART := preload("res://assets/pixel/buildings/ancient-waystation-ruined.png")
const RUIN_REPAIR_ART := preload("res://assets/pixel/buildings/ancient-waystation-repairing.png")
const TRADER_CART := preload("res://assets/pixel/buildings/trader-cart.png")
const TradeWindow := preload("res://trade_window.gd")
const HexAction := preload("res://hex_action_button.gd")
const QUARRY_ART := preload("res://assets/pixel/buildings/quarry.png")
const CONSTRUCTION_ART := preload("res://assets/pixel/buildings/construction-site.png")
const BODY_FONT := preload("res://assets/fonts/LXGWWenKaiGB-Regular.ttf")
const TITLE_FONT := preload("res://assets/fonts/WenYuanSerifSC-Medium.ttf")
const MAP_BACKDROP := preload("res://assets/ui/map-washi.png")
const QUEST_BOARD := preload("res://assets/ui/quest-board.png")
const CAMERA_OFFSET := Vector3(0, 12.5, 17.0)
const HIGH_CAMERA_PITCH := deg_to_rad(56.0)
const CAMERA_ZOOM := 15.1
const DIRECTIONS := [
	Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(0, -1), Vector2i(1, -1),
]
const NAMES := {
	"grassland": "草原", "cleared": "平原空地", "forest": "林地",
	"mountains": "山地", "lake": "湖泊", "river": "河流",
}
const BASE := Vector2i.ZERO
const STARTING_COMMANDS := 12
const WAREHOUSE_CAPACITY := 240
const GATHER_NAMES := ["伐木", "获取兽肉", "取水", "采石", "采矿", "锻造", "耕作", "捕鱼", "制作修复部件"]
const RESOURCE_NAMES := ["木头", "兽肉", "水", "石头", "铁矿", "铁件", "农产品", "鱼肉", "修复部件"]
const PER_TRIP := [6, 3, 3, 5, 4, 1, 4, 3, 1]
const SECONDS_PER_UNIT := [1.25, 4.5, 6.0, 2.4, 3.0, 9.0, 3.4, 4.0, 11.0]
const RATION_VALUES := {Gather.FOOD: 2, Gather.CROPS: 1, Gather.FISH: 2}
const RECIPES := {Gather.IRON: {Gather.ORE: 2, Gather.WOOD: 1}, Gather.PART: {Gather.IRON: 1, Gather.STONE: 2}}
const SHOP_GOODS := {Gather.CROPS: [3, 6], Gather.WOOD: [2, 8], Gather.STONE: [4, 5], Gather.WATER: [2, 6], Gather.IRON: [8, 2]}
const SHOP_DEMAND := {Gather.WOOD: [1, 12], Gather.CROPS: [1, 8], Gather.FOOD: [3, 6], Gather.FISH: [4, 6], Gather.STONE: [2, 8]}
const VISITOR_GOODS := {-1: [12, 1], -2: [18, 1], Gather.IRON: [7, 3]}
const VISITOR_DEMAND := {Gather.FISH: [5, 5], Gather.STONE: [3, 8], Gather.IRON: [5, 3]}
const GATHER_POSITIONS := [Vector3(-0.23, 0, 0.12), Vector3(0.23, 0, -0.12), Vector3(0.19, 0, 0.28)]
const CARGO_COLORS := ["#a87946", "#a87663", "#73abb2", "#a0a29a", "#a26b44", "#9dabb8", "#9dac59", "#61a5b5", "#b593cb"]
const DAY_SECONDS := 240.0
const SECONDS_PER_HEX := 5.0
const MAX_NEIGHBOR_RISE := 0.26
const SHORTAGE_RATE := 0.75
const ACCENT := Color("#e9ce84")
const SOFT_OUTLINE := Color("#b7d5be")
const PAPER_INK := Color("#352b20")
const PAPER_MUTED := Color("#5e4734")
const CAMP_SLOTS := [
	Vector3(-0.50, 0, -0.29), Vector3(0.11, 0, -0.48), Vector3(0.57, 0, -0.17),
	Vector3(0.46, 0, 0.37), Vector3(0, 0, 0.52), Vector3(-0.47, 0, 0.25),
]

var tiles: Dictionary = {}
var scenery := Scenery.new()
var workers: Array[Node3D] = []
var open_scouts: Dictionary = {}
var crews: Dictionary = {}
var stock: Array[int] = empty_resources()
var site_stock: Dictionary = {}
var pickups: Dictionary = {}
var delivered_today: Array[int] = empty_resources()
var night_open := false
var speed_mode := 1
var campaign := Campaign.new()
var facilities: Dictionary = {}
var post_residents: Dictionary = {}
var station_roads: Dictionary = {}
var ruin_cell: Variant = null
var ruin_visual: Node3D
var coins := 8
var trade_stock: Dictionary = {}
var trade_orders: Dictionary = {}
var trade_tools: Dictionary = {}
var trader_cell: Variant = null
var trader_visual: Node3D
var trade_window: TradeWindow
var upgrade_button: HexAction
var upgrade_confirm: Button
var trade_button: HexAction
var tool_button: Button
var post_roster: OptionButton
var pending_stage := 0
var ending := ""
var restored := false
var assigned_worker: Node3D
var skipping := false
var skip_dialog: ConfirmationDialog
var progression: ProgressionWindow
var pause_before_progression := false
var field_workers: OptionButton
var field_roster: Array[Node3D] = []
var facility_buttons: Array[Button] = []
var charm_button: Button
var charm_cells: Array[Vector2i] = []
var town_cells: Dictionary = {}
var map_seed := -1
var river_network_version := MapLayout.RIVER_NETWORK_VERSION
var layout: MapLayout
var map_season := -1
var houses: Dictionary = {}
var builders: Dictionary = {}
var orders: Dictionary = {}
var travelling: Dictionary = {}
var night_ledger: Dictionary = {}
var pause_menu: PauseMenu
var speed_glow: SpeedGlow
var candidates: Array[Dictionary] = []
var center_stage := 0
var camp: Node3D
var planning := false
var dragged_house: Variant
var drop_cell: Variant
var build_button: Button
var planning_hint: Label
var day := 1
var day_elapsed := 0.0
var gathering_rate := 1.0
var selected := BASE
var selected_resource := -1
var menu := Menu.CLOSED
var commands := STARTING_COMMANDS
var surveyed_count := 0
var camera: Camera3D
var backdrop_mesh: QuadMesh
var map_focus := Vector3.ZERO
var camera_turns := 0
var high_camera := false
var panning := false
var hovered: Variant
var preview_route: Array[Vector2i] = []
var hud_title: Label
var intel_label: Label
var details_label: Label
var scout_button: Button
var gather_buttons: Array[Button] = []
var stop_buttons: Array[Button] = []
var supply_status := ""
var status_hud: GameHud
var tile_card: SidePanel
var tile_action_bar: PanelContainer
var tile_action_panel: PanelContainer
var tile_action_scroll: ScrollContainer
var build_choices: VBoxContainer
var work_choices: VBoxContainer
var upgrade_choices: VBoxContainer
var back_to_tile: Button
var build_shortcut: HexAction
var work_shortcut: HexAction
var town_shortcuts: Array[HexAction] = []
var action_group := ""
var action_rise := 0.0
var action_motion: Tween
var pickup_button: Button
var journal: Journal
var badge_layer: Control
var building_plate_layer: Control
var building_plates: Dictionary = {}
var badges: Dictionary = {}
var last_displayed_second := -1
var feedback: Label
var feedback_plate: PanelContainer
var feedback_fade: Tween
var marisa: TextureRect
var portrait_visible := false
var portrait_motion: Tween


func _ready() -> void:
	var saved := Session.take_pending()
	map_seed = int(saved.get("map_seed", -1)) if not saved.is_empty() else randi()
	if not saved.is_empty():
		river_network_version = int(saved.get("river_network_version", 0))
	if map_seed >= 0:
		layout = MapLayout.new(map_seed, river_network_version)
	build_map()
	survey(BASE)
	for direction: Vector2i in DIRECTIONS:
		survey(direction)
	build_camp()
	stock[Gather.CROPS] = workers.size()
	stock[Gather.WATER] = workers.size()
	build_camera()
	build_hud()
	campaign.next_day(day)
	if not saved.is_empty():
		Snapshot.restore(self, saved)
	prepare_world_sites()
	refresh_trade_day(false)
	refresh_station_roads()
	update_hud()


func empty_resources() -> Array[int]:
	var values: Array[int] = []
	values.resize(Gather.size())
	values.fill(0)
	return values


func food_rations() -> int:
	var total := 0
	for kind: int in RATION_VALUES:
		total += stock[kind] * RATION_VALUES[kind]
	return total


func consume_food(needed: int, consumed: Array[int]) -> int:
	for kind: int in [Gather.CROPS, Gather.FISH, Gather.FOOD]:
		var value: int = RATION_VALUES[kind]
		var amount := mini(stock[kind], ceili(float(needed) / value))
		consumed[kind] = amount
		stock[kind] -= amount
		needed = maxi(0, needed - amount * value)
	return needed


func prepare_world_sites() -> void:
	if ruin_cell != null:
		refresh_ruin_visual()
		return
	var reachable := {BASE: true}
	var frontier: Array[Vector2i] = [BASE]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		for direction: Vector2i in DIRECTIONS:
			var next := current + direction
			var next_tile: Tile = tiles.get(next)
			if next_tile != null and not is_water(next_tile) and not reachable.has(next):
				reachable[next] = true
				frontier.append(next)
	for distance in [3, 2, 4]:
		for cell: Vector2i in tiles:
			var tile: Tile = tiles[cell]
			var ring := maxi(absi(cell.x), maxi(absi(cell.y), absi(cell.x + cell.y)))
			if ring != distance or not reachable.has(cell) or tile.terrain not in ["grassland", "cleared"] or tile.prey > 0 or houses.has(cell) or facilities.has(cell):
				continue
			ruin_cell = cell
			refresh_ruin_visual()
			return


func refresh_ruin_visual() -> void:
	if ruin_cell == null:
		return
	if ruin_visual != null:
		ruin_visual.hide()
		ruin_visual.queue_free()
		ruin_visual = null
	if facilities.has(ruin_cell) or tiles[ruin_cell].knowledge == Tile.Knowledge.HIDDEN:
		return
	ruin_visual = Node3D.new()
	ruin_visual.position = cell_position(ruin_cell)
	add_child(ruin_visual)
	draw_building(ruin_visual, RUIN_ART, 1.30, 1.32)


func maximum_shop_level() -> int:
	var level := 1
	for site: Dictionary in facilities.values():
		if site.ready and site.kind == Facility.SHOP:
			level = maxi(level, site.level)
	return level


func refresh_trade_day(reset: bool) -> void:
	if reset or trade_stock.is_empty():
		trade_stock.clear()
		trade_orders.clear()
		var level := maximum_shop_level()
		for market in 2:
			var offers: Dictionary = VISITOR_GOODS if market == 1 else SHOP_GOODS
			var demand: Dictionary = VISITOR_DEMAND if market == 1 else SHOP_DEMAND
			for kind: int in offers:
				trade_stock[Vector2i(market, kind)] = offers[kind][1] + (level - 1 if market == 0 else 0)
			for kind: int in demand:
				trade_orders[Vector2i(market, kind)] = demand[kind][1] + (level - 1 if market == 0 else 0)
		if reset:
			trader_cell = null
	if day % 3 == 2 and trader_cell == null:
		for cell: Vector2i in DIRECTIONS:
			var tile: Tile = tiles[cell]
			if not is_water(tile) and not houses.has(cell) and not facilities.has(cell) and cell != ruin_cell:
				trader_cell = cell
				break
	if trader_visual != null:
		trader_visual.hide()
		trader_visual.queue_free()
		trader_visual = null
	if trader_cell != null:
		trader_visual = Node3D.new()
		trader_visual.position = cell_position(trader_cell)
		add_child(trader_visual)
		draw_building(trader_visual, TRADER_CART, 1.04, 1.13)


func trade_kind_name(kind: int) -> String:
	match kind:
		-1: return "古驿站线索"
		-2: return "探矿罗盘"
		_: return RESOURCE_NAMES[kind]


func trade_kind_icon(kind: int) -> String:
	match kind:
		-1: return "journal"
		-2: return "spyglass"
		_: return ResourceIcon.RESOURCES[kind]


func trade_amount(market: int, kind: int, selling: bool) -> int:
	var key := Vector2i(market, kind)
	if selling:
		return mini(int(trade_orders.get(key, 0)), stock[kind])
	var offers: Dictionary = VISITOR_GOODS if market == 1 else SHOP_GOODS
	var in_stock: int = trade_stock.get(key, 0)
	var affordable := coins / int(offers[kind][0])
	if kind < 0:
		if kind == -1 and (ruin_cell == null or tiles[ruin_cell].knowledge != Tile.Knowledge.HIDDEN):
			return 0
		return mini(in_stock, affordable) if not trade_tools.has(kind) else 0
	return mini(in_stock, mini(affordable, warehouse_available()))


func open_trade() -> void:
	var site: Dictionary = facilities.get(selected, {})
	var visiting: bool = trader_cell == selected
	if night_open or planning or (not visiting and (not site.get("ready", false) or site.kind != Facility.SHOP)):
		return
	panning = false
	action_group = ""
	tile_action_panel.hide()
	trade_window.open(visiting)
	get_tree().paused = true
	refresh_trade()


func close_trade() -> void:
	trade_window.hide()
	get_tree().paused = night_open
	update_hud()


func refresh_trade(message := "") -> void:
	var market := int(trade_window.trader)
	var selling := trade_window.selling
	var offers: Dictionary = (VISITOR_DEMAND if market == 1 else SHOP_DEMAND) if selling else (
		VISITOR_GOODS if market == 1 else SHOP_GOODS)
	var limits: Dictionary = trade_orders if selling else trade_stock
	var entries := []
	for kind: int in offers:
		var available: int = limits.get(Vector2i(market, kind), 0)
		var name_of_item := trade_kind_name(kind)
		var description := ("%s，这次还收 %d 份。" if selling else "%s，手边还剩 %d 份。") % [name_of_item, available]
		if kind == -1:
			description = "这张旧图能标出古驿站一带。你得自己派人过去查清。"
		elif kind == -2:
			description = "它能指个大概方向。真要找矿，还得派人去看看。"
		entries.append({"kind": kind, "name": name_of_item, "icon": trade_kind_icon(kind), "price": offers[kind][0],
			"description": description, "available": available, "maximum": trade_amount(market, kind, selling),
			"unavailable": "已售罄或到达收购额度" if available == 0 else "库存、金币或仓库余量不足，或已持有",
			"ration": RATION_VALUES.get(kind, 0), "food": food_rations()})
	var summary := "停留至今晚" if market == 1 else "下批补货 明日  ·  仓库余量 %d" % warehouse_available()
	trade_window.populate(entries, coins, summary, message)


func exchange_goods(kind: int, amount: int) -> void:
	if not trade_window.visible or amount <= 0:
		return
	var market := int(trade_window.trader)
	var selling := trade_window.selling
	var offers: Dictionary = (VISITOR_DEMAND if market == 1 else SHOP_DEMAND) if selling else (
		VISITOR_GOODS if market == 1 else SHOP_GOODS)
	if not offers.has(kind) or amount > trade_amount(market, kind, selling):
		refresh_trade("这笔交易已经不能成交。")
		return
	var total: int = offers[kind][0] * amount
	var key := Vector2i(market, kind)
	if selling:
		trade_orders[key] -= amount
		stock[kind] -= amount
		coins += total
	else:
		trade_stock[key] -= amount
		coins -= total
		if kind < 0:
			trade_tools[kind] = true
		else:
			stock[kind] += amount
	refresh_trade("已%s %d 份%s。" % ["收购" if selling else "售出", amount, trade_kind_name(kind)])
	update_hud()


func use_trade_tool() -> void:
	if trade_tools.has(-1) and ruin_cell != null and tiles[ruin_cell].knowledge == Tile.Knowledge.HIDDEN:
		reveal(ruin_cell, Tile.Knowledge.SEEN)
		trade_tools.erase(-1)
		map_focus = cell_position(ruin_cell)
		move_camera()
		select_tile(ruin_cell)
	elif trade_tools.has(-2):
		var target: Variant = null
		var distance := INF
		for cell: Vector2i in tiles:
			var tile: Tile = tiles[cell]
			if tile.ore <= 0 or tile.knowledge != Tile.Knowledge.HIDDEN:
				continue
			var candidate := tile.position.distance_squared_to(cell_position(BASE))
			if candidate < distance:
				target = cell
				distance = candidate
		if target != null:
			reveal(target, Tile.Knowledge.SEEN)
			trade_tools.erase(-2)
			map_focus = cell_position(target)
			move_camera()
			select_tile(target)
		else:
			show_feedback("罗盘没找到隐藏的矿脉。")
	update_hud()


func _process(delta: float) -> void:
	day_elapsed = minf(day_elapsed + delta, DAY_SECONDS)
	position_tile_actions()
	update_badge_positions(delta)
	var seconds := ceili(DAY_SECONDS - day_elapsed)
	if last_displayed_second != seconds:
		last_displayed_second = seconds
		status_hud.set_clock(season_day(), DAY_SECONDS - day_elapsed, DAY_SECONDS, campaign.season(day))
		if selected_resource >= 0 or has_gatherers(selected):
			update_hud()
	if day_elapsed >= DAY_SECONDS:
		close_day()


func change_speed(mode: int) -> void:
	if night_open:
		return
	speed_mode = mode
	panning = false
	Engine.time_scale = 3.0 if mode == 2 else 1.0
	status_hud.set_speed_buttons(speed_mode, commands == 0, night_open)
	refresh_speed_glow()


func refresh_speed_glow() -> void:
	speed_glow.set_active((speed_mode == 2 or skipping) and not get_tree().paused)


func toggle_pause_menu() -> void:
	if skipping or progression.visible or trade_window.visible or skip_dialog.visible:
		return
	if pause_menu.visible:
		pause_menu.hide()
		get_tree().paused = night_open
		if night_open:
			journal.next_button.grab_focus()
	else:
		finish_drag(false)
		panning = false
		get_tree().paused = true
		pause_menu.open_for(self)
	status_hud.set_speed_buttons(0 if pause_menu.visible else speed_mode, commands == 0, night_open)
	refresh_speed_glow()


func time_control(index: int) -> void:
	if index == 0:
		toggle_pause_menu()
		return
	if night_open or skipping or pause_menu.visible:
		return
	if index == 2:
		if commands == 0:
			var left := field_total()
			skip_dialog.dialog_text = "剩余白天的施工、采集和运输会继续模拟。\n地块上的 %d 木头、%d 食物、%d 水、%d 石头仍需派人取回。" % left
			skip_dialog.popup_centered()
	else:
		change_speed(1 if speed_mode == 2 else 2)


func skip_day() -> void:
	if night_open or commands != 0:
		return
	skipping = true
	panning = false
	get_viewport().gui_disable_input = true
	get_tree().paused = false
	Engine.time_scale = 24.0
	refresh_speed_glow()


func season_day() -> int:
	return (day - 1) % Campaign.SEASON_DAYS + 1


func command_limit() -> int:
	return STARTING_COMMANDS + campaign.level - 1


func earn_experience(amount: int, origin: Vector2) -> void:
	var previous := command_limit()
	campaign.earn(amount)
	if not skipping:
		commands += command_limit() - previous
	status_hud.fly_reward("talisman", amount, origin, true, command_limit() > previous)


func _exit_tree() -> void:
	Engine.time_scale = 1.0
	if skipping:
		get_viewport().gui_disable_input = false
	get_tree().paused = false


func close_day() -> void:
	if night_open:
		return
	night_open = true
	skipping = false
	get_viewport().gui_disable_input = false
	skip_dialog.hide()
	finish_drag(false)
	set_planning(false)
	Engine.time_scale = 1.0
	panning = false
	var landed := empty_resources()
	var empty_returns := 0
	for trip: Pickup in pickups.values():
		trip.motion.kill()
		travelling.erase(trip.worker)
		if trip.loaded:
			stock[trip.key.z] += trip.amount
			landed[trip.key.z] += trip.amount
			status_hud.fly_reward(ResourceIcon.RESOURCES[trip.key.z], trip.amount, reward_origin(BASE))
		else:
			add_site_stock(trip.key, trip.amount)
			empty_returns += 1
		restore_carrier(trip)
	pickups.clear()
	var needed := workers.size()
	var consumed := empty_resources()
	consumed[Gather.WATER] = mini(needed, stock[Gather.WATER])
	var lacks_food := consume_food(needed, consumed) > 0
	var lacks_water := consumed[Gather.WATER] < needed
	stock[Gather.WATER] -= consumed[Gather.WATER]
	var next_rate := SHORTAGE_RATE if lacks_food or lacks_water else 1.0
	if next_rate != gathering_rate:
		for crew: GatheringCrew in crews.values():
			for job in crew.jobs:
				if job.timer.time_left > 0:
					job.timer.start(job.timer.time_left * gathering_rate / next_rate)
		gathering_rate = next_rate
	var report := "粮水充足。"
	if lacks_food or lacks_water:
		var lacking := "食物和水" if lacks_food and lacks_water else ("食物" if lacks_food else "水")
		report = "今晚缺%s，明日采集效率降低 25%%。" % lacking
	if empty_returns > 0:
		report += "\n%d 人空手回营，预留的货物留在原地。" % empty_returns
	for kind in Gather.size():
		delivered_today[kind] += landed[kind]
	report += "\n今日完工 %d 项。" % campaign.built
	pending_stage = assess_center()
	if pending_stage > center_stage:
		report += "\n魔理沙：「这块折叠的土地，总算有了%s的样子。」\n次日议事厅升阶，新的研习可以开放。" % CENTER_NAMES[pending_stage]
	if day == campaign.deadline(day):
		var goal := 1 if day == Campaign.SEASON_DAYS else 2
		if pending_stage < goal:
			ending = "季度目标未达成 · 本局结束"
		elif goal == 2 and not restored and (ruin_cell == null or not station_ready(ruin_cell)):
			report += "\n城镇考核已通过。修复古驿站，才能接回这片土地的旧路。"
	if not restored and pending_stage >= 2 and day >= Campaign.SEASON_DAYS * 2 and ruin_cell != null and station_ready(ruin_cell):
		restored = true
		report += "\n异变解除 · 幻想乡重新展开。城镇保留，可以继续经营。"
	if not ending.is_empty():
		report += "\n" + ending
	feedback.text = report
	update_hud()
	get_tree().paused = true
	var daytime := delivered_today.duplicate()
	for kind in Gather.size():
		daytime[kind] -= landed[kind]
	night_ledger = {"daytime": daytime, "landed": landed, "consumed": consumed, "report": report}
	show_night_ledger()
	refresh_speed_glow()


func show_night_ledger() -> void:
	journal.enter_night(day, night_ledger.daytime, night_ledger.landed, field_total(),
		night_ledger.consumed, stock, night_ledger.report)
	update_night_claims()
	journal.next_button.text = "重新开始" if not ending.is_empty() else "开始下一天"


func start_next_day() -> void:
	if not night_open or progression.visible or pause_menu.visible:
		return
	if not ending.is_empty():
		get_tree().paused = false
		get_tree().reload_current_scene()
		return
	night_open = false
	night_ledger.clear()
	day += 1
	day_elapsed = 0.0
	commands = command_limit()
	delivered_today = empty_resources()
	campaign.next_day(day)
	refresh_trade_day(true)
	update_center()
	refresh_candidates()
	journal.leave_night()
	get_tree().paused = false
	change_speed(1)
	update_hud()
	var result := save_progress(0)
	if result != OK:
		show_feedback("自动存档失败。可以从暂停菜单手动保存。")


func save_progress(slot: int) -> Error:
	return Session.write_slot(slot, Snapshot.capture(self), {
		"season": campaign.season(day), "day": season_day(), "total_day": day,
		"stage": CENTER_NAMES[center_stage], "night": night_open,
	})


func build_map() -> void:
	var tile_layer := Node3D.new()
	tile_layer.name = "Terrain"
	add_child(tile_layer)
	var radius := 4 if layout == null else MapLayout.RADIUS
	var grades := FastNoiseLite.new()
	var raw_heights := {}
	grades.seed = 853 if map_seed < 0 else int(map_seed % 2147483647)
	grades.frequency = 0.23
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			if maxi(absi(q), maxi(absi(r), absi(q + r))) > radius:
				continue
			var cell := Vector2i(q, r)
			var kind := terrain_at(cell)
			var tile := Tile.new()
			tile.position = Vector3(1.5 * q, 0, sqrt(3.0) * (r + q * 0.5))
			tile.previous_ground_height = previous_relief_at(cell, kind, grades)
			raw_heights[cell] = -0.17 if kind in ["lake", "river"] else 0.01 + tile.previous_ground_height * 0.34
			tile_layer.add_child(tile)
			tile.build(kind, resources_at(cell, kind))
			tile.prey = wildlife_amount(cell, kind)
			tile.initial_prey = tile.prey
			if kind == "forest":
				tile.initial_wood = 48 + 6 * posmod(cell.x * 17 + cell.y * 31, 6)
				tile.wood = tile.initial_wood
			if kind == "mountains":
				tile.initial_stone = 36 + 6 * posmod(cell.x * 23 + cell.y * 7, 5)
				tile.stone = tile.initial_stone
				tile.ore = 20 + 4 * posmod(cell.x * 41 - cell.y * 13, 6) if posmod(q + r, 3) != 0 else 0
			tiles[cell] = tile
	for cell: Vector2i in tiles:
		var surface: float = raw_heights[cell]
		for nearby: Vector2i in raw_heights:
			var delta := nearby - cell
			var distance := maxi(absi(delta.x), maxi(absi(delta.y), absi(delta.x + delta.y)))
			surface = minf(surface, raw_heights[nearby] + distance * MAX_NEIGHBOR_RISE)
		tiles[cell].ground_height = surface
		refresh_edges(cell)


func previous_relief_at(cell: Vector2i, kind: String, grades: FastNoiseLite) -> float:
	if kind in ["river", "lake"]:
		return -0.17
	var sample := grades.get_noise_2d(cell.x + cell.y * 0.5, cell.y * 0.866)
	var terrace := clampi(roundi(2.0 + sample * 3.8), 0, 4)
	if kind == "mountains":
		return 0.77 + terrace * 0.24
	for direction: Vector2i in DIRECTIONS:
		if terrain_at(cell + direction) in ["river", "lake"]:
			return mini(terrace, 1) * 0.21 + 0.04
	return 0.08 + terrace * 0.22 + (0.12 if kind == "forest" else 0.0)


func terrain_at(cell: Vector2i) -> String:
	if layout != null:
		return layout.terrain.get(cell, "grassland")
	if cell == BASE or cell in [Vector2i(-1, 1), Vector2i(2, 0)]:
		return "cleared"
	if cell in [Vector2i(1, 2), Vector2i(2, -1), Vector2i(2, 1), Vector2i(2, 2),
			Vector2i(3, -2), Vector2i(3, -1), Vector2i(3, 0), Vector2i(3, 1), Vector2i(4, -2),
			Vector2i(4, -1), Vector2i(4, 0)]:
		return "lake"
	if cell.x == 1 and cell.y >= -3 and cell.y < 2:
		return "river"
	if cell in [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(-2, 1),
			Vector2i(-3, 2), Vector2i(0, 2), Vector2i(2, -3), Vector2i(-3, 0), Vector2i(-2, 3)]:
		return "forest"
	if cell in [Vector2i(-2, 0), Vector2i(-1, -1), Vector2i(0, -2),
			Vector2i(-2, -1), Vector2i(-1, -2), Vector2i(0, -3),
			Vector2i(2, -4), Vector2i(3, -4), Vector2i(-4, 1)]:
		return "mountains"
	return "grassland"


func resources_at(cell: Vector2i, kind: String) -> String:
	match kind:
		"mountains":
			return "矿脉  %s" % ("已发现" if cell.x + cell.y == -2 else "无")
		"river":
			return "水  可持续取用"
		"lake":
			return "水  可持续取用\n鱼  18"
		_:
			return "适合建造"


func wildlife_amount(cell: Vector2i, kind: String) -> int:
	if layout != null and cell == layout.hunting_ground:
		return 24
	if kind == "forest" and posmod(cell.x + cell.y, 2) == 0:
		return 12
	if kind == "grassland" and posmod(cell.x - cell.y, 3) != 0:
		return 18
	return 0


func reveal(cell: Vector2i, state: Tile.Knowledge) -> void:
	var tile: Tile = tiles[cell]
	tile.reveal(state)
	refresh_edges(cell)
	for direction: Vector2i in DIRECTIONS:
		if tiles.has(cell + direction):
			refresh_edges(cell + direction)
	if tile.scenery == null:
		var rng := RandomNumberGenerator.new()
		rng.seed = (cell.x + 4) * 151 + (cell.y + 4) * 997
		tile.scenery = Node3D.new()
		tile.scenery.position.y = tile.elevation
		tile.add_child(tile.scenery)
		match tile.terrain:
			"forest":
				tile.trees = Node3D.new()
				tile.scenery.add_child(tile.trees)
				tile.pick_bounds = scenery.forest(tile.trees, rng, tile.season)
			"mountains":
				tile.peak = scenery.mountain(tile.scenery, rng, tile.season)
			"river":
				var links := {"in": Vector2i(0, -1) if cell.y > -3 else Vector2i.ZERO,
					"out": Vector2i(0, 1), "mouth": cell.y == 1}
				if layout != null:
					links = layout.river_links[cell]
				scenery.river(tile.scenery, tile.position, links)
	if state == Tile.Knowledge.SURVEYED and tile.wildlife == null and tile.prey > 0:
		tile.wildlife = Node3D.new()
		tile.scenery.add_child(tile.wildlife)
		var species := posmod(cell.x * 31 + cell.y * 17, Scenery.ANIMALS.size())
		scenery.animal(tile.wildlife, species, Vector3(-0.13, 0, 0.01), Vector3(0.23, 0, -0.13))
		if tile.terrain == "grassland":
			scenery.animal(tile.wildlife, (species + 1) % Scenery.ANIMALS.size(), Vector3(0.40, 0, -0.19), Vector3(-0.21, 0, -0.24))
	if cell == ruin_cell:
		refresh_ruin_visual()


func refresh_season() -> void:
	var next := Campaign.SEASONS.find(campaign.season(day))
	if map_season == next:
		return
	map_season = next
	for tile: Tile in tiles.values():
		tile.season = next
		tile.refresh_ground()
		if tile.trees != null:
			for tree: Sprite3D in tile.trees.get_children():
				scenery.apply_sprite_art(tree, Scenery.FORESTS[next])
		if tile.peak != null:
			scenery.apply_sprite_art(tile.peak, Scenery.MOUNTAINS[next])


func refresh_quarry(cell: Vector2i) -> void:
	var tile: Tile = tiles[cell]
	var crew: GatheringCrew = crews.get(Vector3i(cell.x, cell.y, Gather.STONE))
	var mining := false
	if crew != null:
		for job in crew.jobs:
			if job.load > 0 and not job.returning:
				mining = true
				break
	if facilities.has(cell) and facilities[cell].kind == Facility.QUARRY and facilities[cell].ready:
		mining = false
	if mining and tile.quarry == null:
		tile.quarry = draw_building(tile.scenery, QUARRY_ART, 0.56, 0.77, 0.79)
		tile.quarry.position.x = 0.34
	if tile.quarry != null:
		tile.quarry.visible = mining


func refresh_edges(cell: Vector2i) -> void:
	var tile: Tile = tiles[cell]
	var heights: Array[float] = []
	var profile := PackedFloat32Array()
	for edge in 6:
		var neighbor: Tile = tiles.get(cell + DIRECTIONS[edge])
		var open_edge := tile.knowledge != Tile.Knowledge.HIDDEN and neighbor != null and neighbor.knowledge != Tile.Knowledge.HIDDEN
		if open_edge or (tile.knowledge == Tile.Knowledge.HIDDEN and neighbor != null and neighbor.knowledge != Tile.Knowledge.HIDDEN):
			heights.append(INF)
		else:
			heights.append(neighbor.elevation if neighbor != null else Tile.BASE_HEIGHT)
		profile.append(shared_corner_height(cell, edge) - tile.elevation)
	tile.shape_floor(profile)
	tile.update_edges(heights)


func shared_corner_height(cell: Vector2i, corner: int) -> float:
	var tile: Tile = tiles[cell]
	if tile.knowledge == Tile.Knowledge.HIDDEN or is_water(tile):
		return tile.elevation
	var near: Array[Vector2i] = [cell, cell + DIRECTIONS[corner], cell + DIRECTIONS[(corner + 5) % 6]]
	var total := 0.0
	var count := 0
	for candidate in near:
		var neighbor: Tile = tiles.get(candidate)
		if neighbor == null or neighbor.knowledge == Tile.Knowledge.HIDDEN:
			continue
		if is_water(neighbor):
			return neighbor.elevation
		total += neighbor.elevation
		count += 1
	return total / count


func survey(cell: Vector2i) -> void:
	var tile: Tile = tiles[cell]
	if tile.knowledge == Tile.Knowledge.SURVEYED:
		return
	reveal(cell, Tile.Knowledge.SURVEYED)
	surveyed_count += 1
	for direction: Vector2i in DIRECTIONS:
		var neighbor: Tile = tiles.get(cell + direction)
		if neighbor != null and neighbor.knowledge == Tile.Knowledge.HIDDEN:
			reveal(cell + direction, Tile.Knowledge.SEEN)


func build_camp() -> void:
	for index in CAMP_SLOTS.size():
		var worker := add_resident(STARTERS[index])
		worker.set_meta("stats", STARTER_STATS[index])
	draw_center()


func draw_center() -> void:
	if camp != null:
		camp.hide()
		camp.queue_free()
	camp = Node3D.new()
	camp.name = "CouncilHall"
	camp.position = cell_position(BASE)
	add_child(camp)
	var height: float = [1.10, 1.37, 1.67][center_stage]
	var art := draw_building(camp, COUNCIL_ART[center_stage], height, 1.44)
	var tile: Tile = tiles[BASE]
	var width := art.texture.get_width() * art.pixel_size
	tile.pick_bounds.assign([AABB(Vector3(-width * 0.5, 0, -0.51), Vector3(width, height, 1.04))])


func add_resident(resident_name: String, specialty := -1) -> Node3D:
	var worker := Node3D.new()
	worker.position = cell_position(BASE) + CAMP_SLOTS[workers.size() % CAMP_SLOTS.size()]
	worker.set_meta("resident_name", resident_name)
	worker.set_meta("specialty", specialty)
	var stats := [3, 3, 3, 3, 3]
	if specialty >= 0:
		stats[specialty] = 5
	worker.set_meta("stats", stats)
	worker.hide()
	add_child(worker)
	var sprite := Sprite3D.new()
	sprite.texture = VILLAGER
	sprite.hframes = VILLAGER_WALK_FRAMES + 1
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = 0.00975
	sprite.position.y = (VILLAGER.get_height() * 0.5 - 1.0) * sprite.pixel_size
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	worker.add_child(sprite)
	workers.append(worker)
	return worker


func resident_rate(worker: Node3D, skill: int) -> float:
	return 1.0 + (int(worker.get_meta("stats")[skill]) - 3) * 0.125


func choose_worker(index: int) -> void:
	if index < 0 or index >= workers.size() or workers[index].visible:
		return
	assigned_worker = workers[index]
	close_side_menus()
	show_feedback("已选 %s。点击地块下达命令。" % assigned_worker.get_meta("resident_name"))
	update_hud()


func begin_assignment(worker: Node3D) -> void:
	if worker == assigned_worker:
		assigned_worker = null
	worker.show()


func resident_cell(worker: Node3D) -> Vector2i:
	if post_residents.has(worker):
		return post_residents[worker]
	for cell: Vector2i in houses:
		if worker in houses[cell].residents:
			return cell
	return BASE


func resident_start(worker: Node3D) -> Vector3:
	var cell := resident_cell(worker)
	var point: Vector3 = cell_position(cell) + CAMP_SLOTS[workers.find(worker) % CAMP_SLOTS.size()] * 0.48
	point.y = tiles[cell].surface_height(point)
	worker.position = point
	return point


func station_ready(cell: Vector2i) -> bool:
	var site: Dictionary = facilities.get(cell, {})
	return site.get("ready", false) and site.kind in [Facility.STATION, Facility.RUIN]


func station_capacity(cell: Vector2i) -> int:
	return (int(facilities[cell].get("level", 1)) + 1) if station_ready(cell) else 0


func set_station_resident(index: int) -> void:
	var id := post_roster.get_item_id(index)
	var house: Housing = houses.get(selected)
	if id <= 0 or id > workers.size() or (house == null and not station_ready(selected)):
		return
	var worker := workers[id - 1]
	if worker.visible:
		return
	if house != null:
		if worker in house.residents:
			if camp_resident_count() >= CAMP_SLOTS.size():
				return
			house.residents.erase(worker)
		elif house.residents.size() < house.level:
			for old: Housing in houses.values():
				old.residents.erase(worker)
			house.residents.append(worker)
			post_residents.erase(worker)
	elif post_residents.get(worker) == selected:
		post_residents.erase(worker)
	elif post_residents.values().count(selected) < station_capacity(selected):
		post_residents[worker] = selected
	resident_start(worker)
	update_hud()


func refresh_post_roster() -> void:
	var house: Housing = houses.get(selected)
	var station := house == null
	var occupied := post_residents.values().count(selected) if station else house.residents.size()
	var capacity := station_capacity(selected) if station else house.level
	post_roster.clear()
	post_roster.add_item("安排居民驻站 / 返回原住处" if station else "安排居民入住 / 返回议事厅", 0)
	for index in workers.size():
		var worker := workers[index]
		if worker.visible:
			continue
		var housed: bool = post_residents.get(worker) == selected if station else worker in house.residents
		var action := ("返回原住处" if housed else "安排驻站") if station else ("返回议事厅" if housed else "安排入住")
		var text := "%s · %s" % [worker.get_meta("resident_name"), action]
		post_roster.add_item(text, index + 1)
		post_roster.set_item_disabled(post_roster.item_count - 1, occupied >= capacity if not housed else (not station and camp_resident_count() >= CAMP_SLOTS.size()))
	post_roster.select(0)


func refresh_station_roads() -> void:
	station_roads.clear()
	var road := {}
	for cell: Vector2i in facilities:
		if not station_ready(cell):
			continue
		for part: Vector2i in find_route(cell, Tile.Knowledge.SURVEYED, true):
			road[part] = true
	station_roads = road


func free_home() -> Housing:
	for house: Housing in houses.values():
		if house.residents.size() < house.level:
			return house
	return null


func camp_resident_count() -> int:
	var total := workers.size()
	for house: Housing in houses.values():
		total -= house.residents.size()
	return total


func has_bed() -> bool:
	return free_home() != null or camp_resident_count() < CAMP_SLOTS.size()


func refresh_candidates() -> void:
	candidates.clear()
	if not has_bed():
		return
	for index in 2:
		candidates.append({
			"name": RECRUIT_NAMES[(day * 2 + index) % RECRUIT_NAMES.size()],
			"specialty": index,
		})


func recruit(index: int) -> void:
	var house := free_home()
	if night_open or not has_bed() or index < 0 or index >= candidates.size():
		return
	var candidate := candidates[index]
	candidates.remove_at(index)
	var worker := add_resident(candidate["name"], candidate["specialty"])
	if house != null:
		house.residents.append(worker)
	resident_start(worker)
	for cell: Vector2i in houses:
		if houses[cell] == house:
			draw_house(cell, house)
			break
	update_center()
	show_feedback("%s 已入住。" % candidate["name"])
	update_hud()


func residential_plot(cell: Vector2i) -> bool:
	var tile: Tile = tiles.get(cell)
	return tile != null and cell != BASE and cell != ruin_cell and cell != trader_cell and tile.knowledge == Tile.Knowledge.SURVEYED and (
		tile.terrain == "cleared" or tile.terrain == "grassland") and tile.prey == 0 and not houses.has(cell) and not facilities.has(cell) and not has_gatherers(cell)


func facility_count(kind: Facility) -> int:
	var total := 0
	for site: Dictionary in facilities.values():
		total += int(site.ready and site.kind == kind)
	return total


func building_cost(base_cost: int) -> int:
	var discount := 0
	for site: Dictionary in facilities.values():
		if site.ready and site.kind == Facility.WORKSHOP:
			discount = maxi(discount, 2 + site.level * 2)
	return maxi(1, base_cost - discount)


func facility_unlocked(kind: Facility) -> bool:
	if kind == Facility.BRIDGE:
		return campaign.learned[Campaign.Spell.ROAD]
	if kind >= Facility.QUARRY:
		return center_stage >= (2 if kind == Facility.MAGIC else 1) if kind in [Facility.MINE, Facility.SMITHY, Facility.MAGIC] else true
	var spell: int = FACILITY_SPELLS[kind]
	return campaign.learned[spell] and center_stage >= Campaign.RESEARCH[spell][4]


func housing_unlocked(level: int) -> bool:
	return level == 0 or (level == 1 and center_stage >= 1 and campaign.learned[Campaign.Spell.COTTAGE]) or (
		level == 2 and center_stage >= 2 and campaign.learned[Campaign.Spell.TOWNHOUSE])


func facility_plot(kind: Facility, cell: Vector2i) -> bool:
	var tile: Tile = tiles[cell]
	if kind == Facility.BRIDGE:
		return bridge_plot(cell)
	if kind in [Facility.QUARRY, Facility.MINE, Facility.RUIN]:
		if cell == trader_cell or tile.knowledge != Tile.Knowledge.SURVEYED or facilities.has(cell) or has_gatherers(cell):
			return false
		if kind == Facility.RUIN:
			return cell == ruin_cell
		return tile.terrain == "mountains" and (tile.ore > 0 if kind == Facility.MINE else tile.stone > 0)
	if not residential_plot(cell):
		return false
	if kind == Facility.FISHERY:
		for direction: Vector2i in DIRECTIONS:
			var bank: Tile = tiles.get(cell + direction)
			if bank != null and bank.knowledge != Tile.Knowledge.HIDDEN and is_water(bank):
				return true
		return false
	return true


func site_cost(kind: Facility, level: int) -> Dictionary:
	var costs := {Gather.WOOD: building_cost(FACILITY_COSTS[kind] + level * 8)}
	if kind == Facility.BRIDGE or kind == Facility.RUIN:
		costs[Gather.STONE] = BRIDGE_STONE + level * 4
	elif level > 0:
		costs[Gather.STONE] = level * 4
	if level == 2:
		costs[Gather.PART if kind == Facility.STATION else Gather.IRON] = 2
	return costs


func cost_text(costs: Dictionary) -> String:
	var parts := PackedStringArray()
	for kind: int in costs:
		parts.append("%d %s" % [costs[kind], RESOURCE_NAMES[kind]])
	return " + ".join(parts)


func can_pay(costs: Dictionary) -> bool:
	for kind: int in costs:
		if stock[kind] < costs[kind]:
			return false
	return true


func pay(costs: Dictionary) -> void:
	for kind: int in costs:
		stock[kind] -= costs[kind]


func order_upgrade() -> void:
	if houses.has(selected):
		order_housing()
	elif facilities.has(selected):
		order_facility(facilities[selected].kind, true)


func order_facility(kind: Facility, upgrading := false) -> void:
	var cell := selected
	var worker := available_worker(2)
	var site: Dictionary = facilities.get(cell, {})
	var level: int = site.get("level", 0) if upgrading else 0
	var bridge := kind == Facility.BRIDGE
	if night_open or planning or commands <= 0 or worker == null or not facility_unlocked(kind):
		return
	if upgrading:
		if not site.get("ready", false) or site.kind != kind or kind == Facility.RUIN or site.get("upgrading", false) or level >= 3 or level > center_stage:
			return
	elif not facility_plot(kind, cell):
		return
	var costs := site_cost(kind, level)
	if not can_pay(costs):
		return
	var from := resident_cell(worker)
	var route := find_shore_route(cell, from) if bridge else job_route(cell, Tile.Knowledge.SURVEYED, true, from)
	if route.is_empty():
		return
	if upgrading:
		site.upgrading = true
	else:
		var model := Node3D.new()
		model.position = cell_position(cell)
		add_child(model)
		site = {"kind": kind, "ready": false, "level": 0, "visual": model}
		facilities[cell] = site
		paint_facility(site)
		if kind == Facility.RUIN:
			refresh_ruin_visual()
	commands -= 1
	pay(costs)
	var home := resident_start(worker)
	builders[worker] = cell
	register_order(worker, "facility", cell, route, home)
	begin_assignment(worker)
	var offset := pickup_offset(Vector3i(cell.x, cell.y, Gather.WATER), route) if bridge else Vector3(0.43, 0, 0.37)
	move_along(worker, outbound_points(route, offset),
		build_facility.bind(cell, worker, route, home))
	update_hud()


func build_facility(cell: Vector2i, worker: Node3D, route: Array[Vector2i], home: Vector3, remaining := -1.0) -> void:
	var timer := order_timer(worker)
	timer.timeout.connect(complete_facility.bind(cell, worker, route, home, timer))
	timer.start(remaining if remaining > 0.0 else 11.0 / resident_rate(worker, 2))


func complete_facility(cell: Vector2i, worker: Node3D, route: Array[Vector2i], home: Vector3, timer: Timer) -> void:
	timer.queue_free()
	var site: Dictionary = facilities[cell]
	site.level += 1
	site.upgrading = false
	site.ready = true
	paint_facility(site)
	campaign.built += 1
	earn_experience(3, reward_origin(cell))
	show_feedback(FACILITY_NAMES[site.kind] + "完工。")
	if site.kind == Facility.BRIDGE:
		for direction: Vector2i in DIRECTIONS:
			var bank: Tile = tiles.get(cell + direction)
			if bank != null and not is_water(bank) and bank.knowledge == Tile.Knowledge.HIDDEN:
				reveal(cell + direction, Tile.Knowledge.SEEN)
		show_feedback("木桥完工。现在可以勘探和开拓对岸。")
	elif site.kind == Facility.RUIN:
		for direction: Vector2i in DIRECTIONS:
			var neighbor: Tile = tiles.get(cell + direction)
			if neighbor != null:
				for offset: Vector2i in DIRECTIONS:
					var reveal_cell := cell + direction + offset
					if tiles.has(reveal_cell) and tiles[reveal_cell].knowledge == Tile.Knowledge.HIDDEN:
						reveal(reveal_cell, Tile.Knowledge.SEEN)
		show_feedback("古驿站重新开门，周围的折缝显露了新的地形。可以安排居民驻扎。")
	refresh_town()
	refresh_station_roads()
	orders[worker].phase = "return"
	move_along(worker, return_points(route, home), builder_return.bind(worker))
	update_hud()


func paint_facility(site: Dictionary) -> void:
	var model: Node3D = site.visual
	for child in model.get_children():
		model.remove_child(child)
		child.queue_free()
	if site.ready:
		var height: float = [0.95, 0.94, 1.27, 1.44, 1.14, 0.72, 1.0, 1.15, 1.37, 1.28, 1.32, 1.05, 1.45, 1.32][site.kind]
		var bridge: bool = site.kind == Facility.BRIDGE
		var art: Texture2D = FACILITY_ART[site.kind]
		if site.level > 1 and site.kind != Facility.RUIN:
			art = load("res://assets/pixel/buildings/%s-lv%d.png" % [FACILITY_SPRITES[site.kind], site.level])
		draw_building(model, art, height + 0.09 * (site.level - 1), 1.98 if bridge else 1.30, 0.0 if bridge else 0.18)
	else:
		if site.kind == Facility.RUIN:
			draw_building(model, RUIN_REPAIR_ART, 1.29, 1.32)
		else:
			draw_building(model, CONSTRUCTION_ART, 0.58, 1.20)


func order_housing() -> void:
	var cell := selected
	var house: Housing = houses.get(cell)
	var level := house.level if house != null else 0
	var worker := available_worker(2)
	if night_open or planning or commands <= 0 or worker == null or not housing_unlocked(level) or stock[Gather.WOOD] < building_cost(HOUSING_COSTS[level]):
		return
	if (house == null and not residential_plot(cell)) or (house != null and house.building):
		return
	var route := job_route(cell, Tile.Knowledge.SURVEYED, true, resident_cell(worker))
	if route.is_empty():
		return
	if house == null:
		house = Housing.new()
		houses[cell] = house
	var home := resident_start(worker)
	house.building = true
	stock[Gather.WOOD] -= building_cost(HOUSING_COSTS[level])
	commands -= 1
	builders[worker] = cell
	register_order(worker, "house", cell, route, home)
	begin_assignment(worker)
	draw_house(cell, house)
	move_along(worker, outbound_points(route, Vector3(0.42, 0, 0.37)),
		build_housing.bind(cell, house, worker, route, home))
	update_hud()


func build_housing(cell: Vector2i, house: Housing, worker: Node3D, route: Array[Vector2i], home: Vector3, remaining := -1.0) -> void:
	var timer := order_timer(worker)
	timer.timeout.connect(complete_housing.bind(cell, house, worker, route, home, timer))
	timer.start(remaining if remaining > 0.0 else HOUSING_TIMES[house.level] / resident_rate(worker, 2))


func complete_housing(cell: Vector2i, house: Housing, worker: Node3D, route: Array[Vector2i], home: Vector3, timer: Timer) -> void:
	timer.queue_free()
	house.level += 1
	house.building = false
	campaign.built += 1
	earn_experience(3, reward_origin(cell))
	draw_house(cell, house)
	show_feedback("住房完工，新增 1 个床位。")
	update_center()
	update_hud()
	orders[worker].phase = "return"
	move_along(worker, return_points(route, home), builder_return.bind(worker))


func builder_return(worker: Node3D) -> void:
	builders.erase(worker)
	orders.erase(worker)
	worker.hide()
	resident_start(worker)
	update_hud()


func draw_house(cell: Vector2i, house: Housing) -> void:
	if house.visual != null:
		house.visual.hide()
		house.visual.queue_free()
	var model := Node3D.new()
	house.visual = model
	model.position = cell_position(cell)
	model.scale = Vector3.ONE * (0.68 + house.level * 0.055)
	add_child(model)
	if house.level > 0:
		var height: float = [0.78, 1.12, 1.42][house.level - 1]
		draw_building(model, HOUSE_ART[house.level - 1], height, 1.50)

	if not house.residents.is_empty():
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 0.36, 0.54)
		lamp.light_color = Color("#ffbf73")
		lamp.light_energy = 1.0
		lamp.omni_range = 0.72
		model.add_child(lamp)
	if house.building:
		draw_building(model, CONSTRUCTION_ART, 0.58, 1.20, 0.44)


func draw_building(model: Node3D, texture: Texture2D, height: float, width: float, depth := 0.18) -> Sprite3D:
	var sprite := Sprite3D.new()
	sprite.texture = texture
	sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	sprite.pixel_size = minf(height / texture.get_height(), width / texture.get_width())
	sprite.position = Vector3(0, texture.get_height() * sprite.pixel_size * 0.5 + 0.018, depth)
	sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	model.add_child(sprite)
	return sprite


func assess_center() -> int:
	var completed := 0
	for house: Housing in houses.values():
		completed += int(house.level > 0)
	if center_stage == 0 and workers.size() >= 7 and completed >= 1 and facility_count(Facility.FARM) > 0:
		return 1
	if center_stage == 1 and workers.size() >= 9 and completed >= 2 and (facility_count(Facility.PASTURE) + facility_count(Facility.WORKSHOP)) > 0:
		return 2
	return center_stage


func update_center() -> void:
	if pending_stage > center_stage:
		center_stage = pending_stage
		draw_center()


func build_camera() -> void:
	var atmosphere := WorldEnvironment.new()
	atmosphere.environment = Environment.new()
	atmosphere.environment.background_mode = Environment.BG_COLOR
	atmosphere.environment.background_color = Color("#203438")
	atmosphere.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	atmosphere.environment.ambient_light_color = Color("#c9d6e3")
	atmosphere.environment.ambient_light_energy = 0.53
	add_child(atmosphere)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52, -42, 0)
	sun.light_color = Color("#fff4dc")
	sun.light_energy = 0.83
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40
	add_child(sun)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = CAMERA_ZOOM
	add_child(camera)
	camera.current = true
	var backdrop := MeshInstance3D.new()
	backdrop_mesh = QuadMesh.new()
	backdrop.mesh = backdrop_mesh
	backdrop.position.z = -60.0
	backdrop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var backing := StandardMaterial3D.new()
	backing.albedo_texture = MAP_BACKDROP
	backing.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	backdrop.material_override = backing
	camera.add_child(backdrop)
	get_viewport().size_changed.connect(fit_backdrop)
	move_camera()


func move_camera() -> void:
	var yaw := deg_to_rad(-14.0 + 60.0 * camera_turns)
	var focus := map_focus + Vector3.RIGHT.rotated(Vector3.UP, yaw) * camera.size * 0.135
	var offset := CAMERA_OFFSET
	if high_camera:
		offset = Vector3(0, sin(HIGH_CAMERA_PITCH), cos(HIGH_CAMERA_PITCH)) * CAMERA_OFFSET.length()
	camera.position = focus + offset.rotated(Vector3.UP, yaw)
	camera.look_at(focus)
	fit_backdrop()


func fit_backdrop() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var art_aspect := float(MAP_BACKDROP.get_width()) / MAP_BACKDROP.get_height()
	var view_aspect := viewport_size.x / maxf(1.0, viewport_size.y)
	var height := camera.size * maxf(1.0, view_aspect / art_aspect) * 1.002
	backdrop_mesh.size = Vector2(height * art_aspect, height)


func _input(event: InputEvent) -> void:
	if skipping:
		return
	if planning and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		finish_drag(false)
		set_planning(false)
		get_viewport().set_input_as_handled()
		return
	if dragged_house != null and event is InputEventMouseMotion:
		var target: Variant = cell_at(event.position, false)
		drop_cell = target if target != null and relocation_plot(target) else null
		var house: Housing = houses[dragged_house]
		house.visual.position = cell_position(drop_cell if drop_cell != null else dragged_house)
		update_outlines()
		get_viewport().set_input_as_handled()
		return
	if dragged_house != null and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		finish_drag(true)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		panning = event.pressed
	elif event is InputEventMouseMotion and panning:
		var scale_per_pixel := camera.size / get_viewport().get_visible_rect().size.y
		var right := camera.basis.x
		var forward := camera.basis.z.slide(Vector3.UP).normalized()
		var vertical_projection := camera.basis.y.slide(Vector3.UP).length()
		map_focus -= (right * event.relative.x + forward * event.relative.y / vertical_projection) * scale_per_pixel
		map_focus = map_focus.clamp(Vector3(-11, 0, -11), Vector3(11, 0, 11))
		move_camera()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if skipping:
		return
	if event is InputEventMouseMotion and not panning:
		var next_hover: Variant = cell_at(event.position)
		if next_hover != hovered:
			hovered = next_hover
			update_outlines()
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				var target: Variant = cell_at(event.position)
				if planning:
					var house: Housing = houses.get(target)
					if house != null and not house.building:
						dragged_house = target
					return
				if target != null:
					select_tile(target)
				else:
					close_side_menus()
			MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
				var zoom := 0.91 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.1
				camera.size = clampf(camera.size * zoom, 9.5, 23.0)
				move_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_Q, KEY_E, KEY_ALT]:
			if panning or dragged_house != null:
				return
			match event.keycode:
				KEY_Q:
					camera_turns = posmod(camera_turns - 1, 6)
				KEY_E:
					camera_turns = posmod(camera_turns + 1, 6)
				KEY_ALT:
					high_camera = not high_camera
			move_camera()
			hovered = cell_at(get_viewport().get_mouse_position())
			update_outlines()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_R:
			open_journal()
		elif event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			toggle_pause_menu()


func open_journal() -> void:
	finish_drag(false)
	set_planning(false)
	map_focus = Vector3.ZERO
	camera.size = CAMERA_ZOOM
	move_camera()
	open_town_page(0)


func select_tile(target: Vector2i) -> void:
	action_group = ""
	selected = target
	selected_resource = -1
	menu = Menu.FIELD
	update_hud()
	pop_tile_actions()


func open_town_page(page: int) -> void:
	action_group = ""
	menu = Menu.TOWN
	selected = BASE
	selected_resource = -1
	journal.show_page(page)
	update_hud()


func close_side_menus() -> void:
	action_group = ""
	menu = Menu.CLOSED
	selected_resource = -1
	update_hud()


func set_planning(enabled: bool) -> void:
	planning = enabled
	planning_hint.visible = enabled
	if enabled:
		close_side_menus()
	update_outlines()


func relocation_plot(cell: Vector2i) -> bool:
	return residential_plot(cell) and not find_route(cell, Tile.Knowledge.SURVEYED, true).is_empty()


func finish_drag(commit: bool) -> void:
	if dragged_house == null:
		return
	var house: Housing = houses[dragged_house]
	var destination: Vector2i = dragged_house
	if commit and drop_cell != null and relocation_plot(drop_cell):
		destination = drop_cell
		houses.erase(dragged_house)
		houses[destination] = house
	house.visual.position = cell_position(destination)
	for resident: Node3D in house.residents:
		if not resident.visible:
			resident_start(resident)
	dragged_house = null
	drop_cell = null
	update_hud()


func cell_at(screen_point: Vector2, include_props := true) -> Variant:
	var ray_origin := camera.project_ray_origin(screen_point)
	var ray_direction := camera.project_ray_normal(screen_point)
	var facing := camera.global_basis.z.slide(Vector3.UP).normalized()
	var right := Vector3.UP.cross(facing)
	var hit: Variant = null
	var closest := INF
	for cell: Vector2i in tiles:
		var tile: Tile = tiles[cell]
		var surface: Variant = tile.floor_hit(ray_origin, ray_direction)
		if surface != null:
			var distance: float = (surface - ray_origin).dot(ray_direction)
			if distance < closest:
				closest = distance
				hit = cell
		if not include_props:
			continue
		if tile.peak != null and tile.knowledge != Tile.Knowledge.HIDDEN:
			var peak_contact: Variant = scenery.mountain_hit(tile.peak, ray_origin, ray_direction, facing, right)
			if peak_contact != null:
				var depth: float = (peak_contact - ray_origin).dot(ray_direction)
				if depth < closest:
					closest = depth
					hit = cell
		var origin := Vector3(tile.position.x, tile.elevation, tile.position.z)
		var bounds_list := tile.pick_bounds.duplicate()
		if houses.has(cell) or facilities.has(cell):
			bounds_list.append(AABB(Vector3(-0.49, 0, -0.37), Vector3(0.98, 0.75, 0.74)))
		elif (cell == trader_cell and trader_visual != null) or (cell == ruin_cell and ruin_visual != null):
			bounds_list.append(AABB(Vector3(-0.55, 0, -0.36), Vector3(1.10, 1.10, 0.75)))
		for bounds: AABB in bounds_list:
			var contact: Variant = bounds.intersects_ray(ray_origin - origin, ray_direction)
			if contact != null:
				var depth: float = (origin + contact - ray_origin).dot(ray_direction)
				if depth > 0 and depth < closest:
					closest = depth
					hit = cell
	return hit


func job_route(target: Vector2i, knowledge: int, land_only: bool, start: Vector2i) -> Array[Vector2i]:
	if target == start and tiles[target].knowledge == knowledge:
		return [start]
	return find_route(target, knowledge, land_only, start)


func find_route(target: Vector2i, knowledge := Tile.Knowledge.SEEN, land_only := false, start := BASE) -> Array[Vector2i]:
	var route: Array[Vector2i] = []
	var tile: Tile = tiles.get(target)
	if tile == null or tile.knowledge != knowledge:
		return route
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var costs := {start: 0.0}
	while not queue.is_empty():
		var current: Vector2i = queue[0]
		for candidate: Vector2i in queue:
			if costs[candidate] < costs[current]:
				current = candidate
		queue.erase(current)
		if current == target:
			while current != start:
				route.push_front(current)
				current = previous[current]
			return route
		for direction: Vector2i in DIRECTIONS:
			var next := current + direction
			var neighbor: Tile = tiles.get(next)
			if neighbor == null:
				continue
			if is_water(neighbor) and not bridge_ready(next) and (land_only or next != target):
				continue
			if next == target or neighbor.knowledge == Tile.Knowledge.SURVEYED:
				var tentative: float = costs[current] + cell_position(current).distance_to(cell_position(next)) * (
					travel_factor(current) + travel_factor(next)) * 0.5 * SECONDS_PER_HEX / sqrt(3.0)
				if tentative < costs.get(next, INF):
					costs[next] = tentative
					previous[next] = current
					if next not in queue:
						queue.append(next)
	return route


func available_worker(skill := -1) -> Node3D:
	if is_instance_valid(assigned_worker) and not assigned_worker.visible:
		return assigned_worker
	var best: Node3D
	for worker in workers:
		if not worker.visible:
			if skill < 0:
				return worker
			if best == null or resident_rate(worker, skill) > resident_rate(best, skill):
				best = worker
	return best


func dispatch_scout() -> void:
	var target := selected
	var worker := available_worker(4)
	var route := find_route(target, Tile.Knowledge.SEEN, false, resident_cell(worker))
	if night_open or commands <= 0 or worker == null or route.is_empty() or open_scouts.has(target):
		return
	var home := resident_start(worker)
	open_scouts[target] = worker
	register_order(worker, "scout", target, route, home)
	commands -= 1
	begin_assignment(worker)
	show_feedback("勘探员已出发。抵达后会公开资源。")
	update_hud()
	move_along(worker, outbound_points(route, Vector3.ZERO), scouting_arrival.bind(target, worker, route, home))


func scouting_arrival(target: Vector2i, worker: Node3D, route: Array[Vector2i], home: Vector3, remaining := -1.0) -> void:
	var timer := order_timer(worker)
	timer.timeout.connect(finish_survey.bind(target, worker, route, home, timer))
	timer.start(remaining if remaining > 0.0 else 3.0 / resident_rate(worker, 4))


func register_order(worker: Node3D, kind: String, target: Vector2i, route: Array[Vector2i], home: Vector3) -> void:
	orders[worker] = {"kind": kind, "target": target, "route": route, "home": home, "phase": "out"}


func order_timer(worker: Node3D) -> Timer:
	var timer := Timer.new()
	timer.one_shot = true
	worker.add_child(timer)
	orders[worker].phase = "work"
	orders[worker].timer = timer
	return timer


func finish_survey(target: Vector2i, worker: Node3D, route: Array[Vector2i], home: Vector3, timer: Timer) -> void:
	timer.queue_free()
	survey(target)
	refresh_station_roads()
	campaign.explored += 1
	earn_experience(2, reward_origin(target))
	show_feedback("已查清%s的资源，并揭开周围地形。" % NAMES[(tiles[target] as Tile).terrain])
	update_hud()
	orders[worker].phase = "return"
	move_along(worker, return_points(route, home), scouting_return.bind(target, worker))


func scouting_return(target: Vector2i, worker: Node3D) -> void:
	worker.hide()
	resident_start(worker)
	open_scouts.erase(target)
	orders.erase(worker)
	update_hud()


func is_water(tile: Tile) -> bool:
	return tile.terrain == "river" or tile.terrain == "lake"


func bridge_ready(cell: Vector2i) -> bool:
	var site: Dictionary = facilities.get(cell, {})
	return not site.is_empty() and site.kind == Facility.BRIDGE and site.ready


func bridge_plot(cell: Vector2i) -> bool:
	var tile: Tile = tiles.get(cell)
	if tile == null or tile.terrain != "river" or tile.knowledge != Tile.Knowledge.SURVEYED or facilities.has(cell):
		return false
	if layout != null and layout.river_links[cell].has("tributaries"):
		return false
	for index in 3:
		var first: Tile = tiles.get(cell + DIRECTIONS[index])
		var second: Tile = tiles.get(cell + DIRECTIONS[index + 3])
		if first != null and second != null and not is_water(first) and not is_water(second):
			return true
	return false


func find_shore_route(target: Vector2i, start := BASE) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	var best_seconds := INF
	for direction: Vector2i in DIRECTIONS:
		var shore := target + direction
		var tile: Tile = tiles.get(shore)
		if tile == null or tile.knowledge != Tile.Knowledge.SURVEYED or is_water(tile):
			continue
		var route := job_route(shore, Tile.Knowledge.SURVEYED, true, start)
		if route.is_empty():
			continue
		var key := Vector3i(target.x, target.y, Gather.WATER)
		var seconds := route_seconds(cell_position(start), outbound_points(route, pickup_offset(key, route)))
		if seconds < best_seconds:
			best_seconds = seconds
			best = route
	return best


func unreserved_resource(tile: Tile, kind: Gather, reserved: int) -> int:
	var site: Dictionary = facilities.get(nearest_cell(tile.position), {})
	var operating := int(site.kind) if site.get("ready", false) else -1
	var level: int = site.get("level", 1)
	match kind:
		Gather.WOOD:
			if operating == Facility.TREE_FARM:
				return PER_TRIP[kind] + level - 1
			return tile.wood - reserved
		Gather.FOOD:
			if operating == Facility.PASTURE:
				return PER_TRIP[kind] + level - 1
			return tile.prey - reserved
		Gather.WATER:
			return PER_TRIP[Gather.WATER] if is_water(tile) else 0
		Gather.STONE:
			return tile.stone - reserved
		Gather.ORE:
			return tile.ore - reserved if operating == Facility.MINE else 0
		Gather.CROPS:
			return PER_TRIP[kind] + level - 1 if operating == Facility.FARM else 0
		Gather.FISH:
			return PER_TRIP[kind] + level - 1 if operating == Facility.FISHERY else 0
		Gather.IRON, Gather.PART:
			var expected := Facility.SMITHY if kind == Gather.IRON else Facility.MAGIC
			return 1 if operating == expected and can_pay(RECIPES[kind]) else 0
	return 0


func renewable_food(cell: Vector2i) -> bool:
	var site: Dictionary = facilities.get(cell, {})
	return site.get("ready", false) and site.kind == Facility.PASTURE


func gather_skill(kind: Gather, cell: Vector2i) -> int:
	return 1 if kind == Gather.FOOD and not renewable_food(cell) else (2 if kind in [Gather.IRON, Gather.PART] else 0)


func dispatch_gatherer(kind: Gather) -> void:
	var target := selected
	var key := Vector3i(target.x, target.y, kind)
	var crew: GatheringCrew = crews.get(key)
	var tile: Tile = tiles[target]
	var worker := available_worker(gather_skill(kind, target))
	var remaining := unreserved_resource(tile, kind, crew.reserved if crew != null else 0)
	if night_open or tile.knowledge != Tile.Knowledge.SURVEYED or remaining <= 0 or commands <= 0 or worker == null:
		return
	if crew != null and (crew.finishing or crew.jobs.size() >= GATHER_POSITIONS.size()):
		return
	var from := resident_cell(worker)
	var route := find_shore_route(target, from) if kind == Gather.WATER else job_route(target, Tile.Knowledge.SURVEYED, true, from)
	if route.is_empty():
		return
	if crew == null:
		crew = GatheringCrew.new()
		crews[key] = crew
	var job := GatheringJob.new()
	job.worker = worker
	job.route = route
	job.home = resident_start(worker)
	job.timer = Timer.new()
	job.timer.one_shot = true
	worker.add_child(job.timer)
	var slot := crew.jobs.size()
	var offset: Vector3 = GATHER_POSITIONS[slot]
	if kind == Gather.WATER:
		var bank_to_water := (tile.position - (tiles[route.back()] as Tile).position).normalized()
		offset = bank_to_water * 0.71 + bank_to_water.cross(Vector3.UP) * (slot - 1) * 0.19
	job.offset = offset
	job.timer.timeout.connect(complete_load.bind(tile, key, crew, job))
	crew.jobs.append(job)
	commands -= 1
	begin_assignment(worker)
	var work: String = GATHER_NAMES[kind]
	show_feedback("村民已出发%s，物资会留在作业地。" % work)
	update_hud()
	move_along(worker, outbound_points(job.route, job.offset), begin_load.bind(tile, key, crew, job))


func request_gathering_stop(kind: Gather) -> void:
	var crew: GatheringCrew = crews.get(Vector3i(selected.x, selected.y, kind))
	if crew != null:
		crew.finishing = true
		update_hud()


func gathering_return(tile: Tile, key: Vector3i, crew: GatheringCrew, job: GatheringJob) -> void:
	var kind: Gather = key.z as Gather
	job.timer.queue_free()
	job.worker.hide()
	resident_start(job.worker)
	crew.jobs.erase(job)
	if crew.jobs.is_empty():
		crews.erase(key)
		if kind == Gather.WOOD and tile.wood == 0 and not facilities.has(Vector2i(key.x, key.y)):
			show_feedback("林地已采尽，地块变为空地。")
		elif kind == Gather.FOOD and tile.prey == 0 and not renewable_food(Vector2i(key.x, key.y)):
			show_feedback("这片地的猎物已耗尽。可勘探新的草原或林地。")
		elif kind == Gather.STONE and tile.stone == 0:
			show_feedback("本格石料已采尽。")
		elif kind == Gather.ORE and tile.ore == 0:
			show_feedback("本格铁矿已采尽。")
		else:
			show_feedback("负责%s的村民已返回营地。" % GATHER_NAMES[kind])
	update_hud()


func batch_limit(kind: int, cell: Vector2i) -> int:
	var site: Dictionary = facilities.get(cell, {})
	var extra := maxi(0, int(site.get("level", 1)) - 1) if not RECIPES.has(kind) else 0
	if kind == Gather.STONE and site.get("ready", false) and site.kind == Facility.QUARRY:
		extra += 1
	return PER_TRIP[kind] + extra


func begin_load(tile: Tile, key: Vector3i, crew: GatheringCrew, job: GatheringJob) -> void:
	var kind: Gather = key.z as Gather
	job.load = maxi(0, mini(unreserved_resource(tile, kind, crew.reserved), batch_limit(kind, Vector2i(key.x, key.y))))
	if job.load == 0 or crew.finishing:
		job.load = 0
		job.returning = true
		if kind == Gather.STONE:
			refresh_quarry(Vector2i(key.x, key.y))
		move_along(job.worker, return_points(job.route, job.home), gathering_return.bind(tile, key, crew, job))
		update_hud()
		return
	crew.reserved += job.load
	if RECIPES.has(kind):
		pay(RECIPES[kind])
	job.timer.start(load_duration(job, kind))
	if kind == Gather.STONE:
		refresh_quarry(Vector2i(key.x, key.y))
	update_hud()


func load_duration(job: GatheringJob, kind: int) -> float:
	var skill := gather_skill(kind, job.route.back())
	var site: Dictionary = facilities.get(job.route.back(), {})
	var speed := 1.0 + 0.20 * maxi(0, int(site.get("level", 1)) - 1)
	return job.load * SECONDS_PER_UNIT[kind] / (gathering_rate * resident_rate(job.worker, skill) * speed)


func complete_load(tile: Tile, key: Vector3i, crew: GatheringCrew, job: GatheringJob) -> void:
	crew.reserved -= job.load
	var amount := job.load
	match key.z:
		Gather.WOOD:
			if not facilities.has(Vector2i(key.x, key.y)):
				amount = tile.harvest_wood(job.load)
		Gather.FOOD:
			if not renewable_food(Vector2i(key.x, key.y)):
				amount = tile.harvest_prey(job.load)
		Gather.STONE:
			amount = mini(tile.stone, job.load)
			tile.stone -= amount
		Gather.ORE:
			amount = mini(tile.ore, job.load)
			tile.ore -= amount
	job.load = 0
	if amount > 0:
		add_site_stock(key, amount)
		show_world_gain(job.worker.position, key.z, amount)
	begin_load(tile, key, crew, job)


func add_site_stock(key: Vector3i, amount: int) -> void:
	site_stock[key] = int(site_stock.get(key, 0)) + amount


func warehouse_available() -> int:
	var available := warehouse_capacity() - stock_total()
	for trip: Pickup in pickups.values():
		available -= trip.amount
	return maxi(0, available)


func warehouse_capacity() -> int:
	var capacity := WAREHOUSE_CAPACITY
	for site: Dictionary in facilities.values():
		if site.ready and site.kind == Facility.WAREHOUSE:
			capacity += 120 + 60 * (site.level - 1)
	return capacity


func stock_total() -> int:
	var total := 0
	for amount in stock:
		total += amount
	return total


func carry_limit(worker: Node3D) -> int:
	return 12 + (int(worker.get_meta("stats")[3]) - 3) * 2 + (6 if campaign.learned[Campaign.Spell.SATCHEL] else 0)


func pickup_route(key: Vector3i, start := BASE) -> Array[Vector2i]:
	var cell := Vector2i(key.x, key.y)
	return find_shore_route(cell, start) if key.z == Gather.WATER else job_route(cell, Tile.Knowledge.SURVEYED, true, start)


func warehouse_route(start: Vector2i) -> Array[Vector3]:
	return outbound_points(job_route(BASE, Tile.Knowledge.SURVEYED, true, start), Vector3.ZERO)


func pickup_offset(key: Vector3i, route: Array[Vector2i]) -> Vector3:
	if key.z != Gather.WATER:
		return Vector3.ZERO
	var cell := Vector2i(key.x, key.y)
	return (cell_position(cell) - cell_position(route.back())).slide(Vector3.UP).normalized() * 0.71


func dispatch_pickup() -> void:
	if night_open or selected_resource < 0:
		return
	var key := Vector3i(selected.x, selected.y, selected_resource)
	var available: int = site_stock.get(key, 0)
	var worker := available_worker(3)
	var amount := mini(available, mini(warehouse_available(), carry_limit(worker))) if worker != null else 0
	var route := pickup_route(key, resident_cell(worker))
	if amount <= 0 or worker == null or route.is_empty():
		return
	var trip := Pickup.new()
	trip.key = key
	trip.amount = amount
	trip.worker = worker
	trip.home = resident_start(worker)
	trip.route = route
	var id := worker.get_instance_id()
	if amount == available:
		site_stock.erase(key)
	else:
		site_stock[key] = available - amount
	pickups[id] = trip
	begin_assignment(worker)
	var points := outbound_points(route, pickup_offset(key, route))
	trip.motion = move_along(worker, points, collect_pickup.bind(id))
	show_feedback("已派人取回 %d %s。" % [amount, RESOURCE_NAMES[key.z]])
	update_hud()


func collect_pickup(id: int) -> void:
	var trip: Pickup = pickups[id]
	trip.loaded = true
	draw_cargo(trip)
	trip.motion = move_along(trip.worker, warehouse_route(trip.route.back()), deposit_pickup.bind(id))
	update_hud()


func draw_cargo(trip: Pickup) -> void:
	trip.cargo = scenery.box(trip.worker, Vector3(0.15, 0.29, 0.05), Vector3(0.18, 0.17, 0.17), CARGO_COLORS[trip.key.z])


func deposit_pickup(id: int) -> void:
	var trip: Pickup = pickups[id]
	stock[trip.key.z] += trip.amount
	update_center()
	delivered_today[trip.key.z] += trip.amount
	status_hud.fly_reward(ResourceIcon.RESOURCES[trip.key.z], trip.amount, reward_origin(BASE))
	pickups.erase(id)
	var worker := trip.worker
	var cell := resident_cell(worker)
	if cell == BASE:
		restore_carrier(trip)
	else:
		if trip.cargo != null:
			trip.cargo.queue_free()
		var route := job_route(cell, Tile.Knowledge.SURVEYED, true, BASE)
		register_order(worker, "carrier", cell, route, trip.home)
		orders[worker].phase = "return"
		move_along(worker, outbound_points(route, trip.home - cell_position(cell)), builder_return.bind(worker))
	show_feedback("%d %s已入库。" % [trip.amount, RESOURCE_NAMES[trip.key.z]])
	update_hud()


func restore_carrier(trip: Pickup) -> void:
	if trip.cargo != null:
		trip.cargo.hide()
		trip.cargo.queue_free()
	trip.motion = null
	trip.worker.position = trip.home
	var sprite := trip.worker.get_child(0) as Sprite3D
	sprite.frame = 0
	trip.worker.hide()


func show_world_gain(location: Vector3, kind: int, amount: int) -> void:
	var burst := Label3D.new()
	burst.text = "+%d %s" % [amount, RESOURCE_NAMES[kind]]
	burst.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	burst.no_depth_test = true
	burst.font = BODY_FONT
	burst.font_size = 39
	burst.pixel_size = 0.0045
	burst.modulate = ResourceIcon.COLORS[kind].lightened(0.35)
	burst.outline_size = 8
	burst.position = location + Vector3.UP * 1.2
	add_child(burst)
	var effect := burst.create_tween().set_parallel()
	effect.tween_property(burst, "position:y", burst.position.y + 0.70, 1.15)
	effect.tween_property(burst, "modulate:a", 0.0, 0.45).set_delay(0.70)
	effect.chain().tween_callback(burst.queue_free)


func outbound_points(route: Array[Vector2i], destination_offset: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for cell in route:
		points.append(cell_position(cell))
	points[-1] += destination_offset
	var destination: Tile = tiles[route.back()]
	points[-1].y = destination.surface_height(points[-1])
	return points


func return_points(route: Array[Vector2i], home: Vector3) -> Array[Vector3]:
	var points: Array[Vector3] = []
	for index in range(route.size() - 2, -1, -1):
		points.append(cell_position(route[index]))
	points.append(home)
	return points


func cell_position(cell: Vector2i) -> Vector3:
	var tile: Tile = tiles[cell]
	return tile.position + Vector3.UP * tile.elevation


func riverbank(cell: Vector2i) -> bool:
	var tile: Tile = tiles[cell]
	if tile.terrain not in ["grassland", "cleared"]:
		return false
	for direction: Vector2i in DIRECTIONS:
		var neighbor: Tile = tiles.get(cell + direction)
		if neighbor != null and neighbor.terrain == "river":
			return true
	return false


func travel_factor(cell: Vector2i) -> float:
	var factor: float = Tile.TRAVEL_FACTORS[tiles[cell].terrain]
	if bridge_ready(cell):
		factor = 1.0 - 0.15 * (int(facilities[cell].get("level", 1)) - 1)
	elif town_cells.has(cell):
		factor = 0.60
	elif riverbank(cell):
		factor = 1.20
	if station_roads.has(cell):
		factor *= 0.80
	return factor * 0.65 if cell in charm_cells else factor


func refresh_town() -> void:
	var occupied := {BASE: true}
	for cell: Vector2i in houses:
		if houses[cell].level > 0:
			occupied[cell] = true
	for cell: Vector2i in facilities:
		if facilities[cell].ready:
			occupied[cell] = true
	var connected := {BASE: true}
	var queue: Array[Vector2i] = [BASE]
	var index := 0
	while index < queue.size():
		var cell := queue[index]
		index += 1
		for direction: Vector2i in DIRECTIONS:
			var next := cell + direction
			if occupied.has(next) and not connected.has(next):
				connected[next] = true
				queue.append(next)
	for cell: Vector2i in town_cells:
		if not connected.has(cell):
			tiles[cell].set_town_ground(null)
	town_cells = connected
	var paving: Texture2D = Tile.PAVING if center_stage >= 1 else Tile.TEXTURES["cleared"]
	for cell: Vector2i in town_cells:
		var tile: Tile = tiles[cell]
		if is_water(tile):
			continue
		var site: Dictionary = facilities.get(cell, {})
		var preserve_field: bool = not site.is_empty() and site.kind in [Facility.FARM, Facility.PASTURE, Facility.TREE_FARM]
		tile.set_town_ground(null if preserve_field else paving)


func refresh_ground_transitions() -> void:
	for cell: Vector2i in tiles:
		var tile: Tile = tiles[cell]
		if tile.knowledge == Tile.Knowledge.HIDDEN:
			continue
		var kinds := PackedInt32Array()
		var brightness := PackedFloat32Array()
		for direction: Vector2i in DIRECTIONS:
			var neighbor: Tile = tiles.get(cell + direction)
			kinds.append(neighbor.ground_class() if neighbor != null else -1)
			brightness.append(neighbor.ground_brightness() if neighbor != null else 1.0)
		tile.set_ground_neighbors(kinds, brightness)


func leg_parts(from: Vector3, to: Vector3) -> Array:
	var a := nearest_cell(from)
	var b := nearest_cell(to)
	var scale := SECONDS_PER_HEX / sqrt(3.0)
	if a == b:
		return [[to, maxf(0.001, from.distance_to(to) * scale * travel_factor(a))]]
	var start: Tile = tiles[a]
	var end: Tile = tiles[b]
	var normal := end.position - start.position
	var middle := (start.position + end.position) * 0.5
	var fraction := clampf((middle - from).dot(normal) / (to - from).dot(normal), 0.0, 1.0)
	var border := from.lerp(to, fraction)
	var first := maxf(0.001, from.distance_to(border) * scale * travel_factor(a))
	var second := maxf(0.001, border.distance_to(to) * scale * travel_factor(b))
	border.y = start.surface_height(border)
	if is_equal_approx(from.y, border.y) and is_equal_approx(border.y, to.y):
		return [[border, first], [to, second]]
	var slope_start := from.lerp(border, 0.72)
	var slope_end := border.lerp(to, 0.28)
	slope_start.y = start.surface_height(slope_start)
	slope_end.y = end.surface_height(slope_end)
	return [[slope_start, first * 0.72], [border, first * 0.28],
		[slope_end, second * 0.28], [to, second * 0.72]]


func nearest_cell(position: Vector3) -> Vector2i:
	var closest := INF
	var result := BASE
	for cell: Vector2i in tiles:
		var tile: Tile = tiles[cell]
		var distance := Vector2(position.x, position.z).distance_squared_to(Vector2(tile.position.x, tile.position.z))
		if distance < closest:
			closest = distance
			result = cell
	return result


func draw_selected_charm() -> void:
	plant_charm(selected)
	update_hud()


func plant_charm(cell: Vector2i) -> void:
	var tile: Tile = tiles.get(cell)
	if not campaign.learned[Campaign.Spell.ROAD] or cell in charm_cells or tile == null or tile.knowledge != Tile.Knowledge.SURVEYED or is_water(tile):
		return
	if charm_cells.size() >= charm_limit():
		var oldest: Vector2i = charm_cells.pop_front()
		tiles[oldest].set_rune_glow(false)
	charm_cells.append(cell)
	tile.set_rune_glow(true)
	refresh_station_roads()
	show_feedback("绘路符已布置。本格移动耗时减少 35%。")


func charm_limit() -> int:
	return 3 if campaign.learned[Campaign.Spell.ROAD_ARRAY] else 1


func route_seconds(from: Vector3, points: Array[Vector3]) -> float:
	var duration := 0.0
	for point in points:
		for part: Array in leg_parts(from, point):
			duration += part[1]
		from = point
	return duration


func move_along(worker: Node3D, points: Array[Vector3], on_arrival: Callable, saved_times: Array = []) -> Tween:
	var sprite := worker.get_child(0) as Sprite3D
	var previous := worker.position
	var motion := worker.create_tween()
	var destinations: Array[Vector3] = []
	var times: Array[float] = []
	if saved_times.is_empty():
		for point in points:
			for part: Array in leg_parts(previous, point):
				destinations.append(part[0])
				times.append(part[1])
			previous = point
	else:
		destinations = points
		times.assign(saved_times)
	previous = worker.position
	var walked := 0.0
	for index in destinations.size():
		var point := destinations[index]
		var travel := times[index]
		var step := point - previous
		var distance := Vector2(step.x, step.z).length()
		var start := walked
		motion.tween_property(worker, "position", point, travel)
		if distance > 0.0001:
			motion.parallel().tween_method(func(progress: float) -> void:
				sprite.flip_h = step.dot(camera.basis.x) < 0
				sprite.frame = 1 + floori(progress / VILLAGER_STRIDE * VILLAGER_WALK_FRAMES) % VILLAGER_WALK_FRAMES,
				start, start + distance, travel)
		walked += distance
		previous = point
	motion.tween_callback(sprite.set_frame.bind(0))
	travelling[worker] = {"points": destinations, "times": times, "tween": motion}
	motion.finished.connect(func() -> void:
		travelling.erase(worker)
		on_arrival.call())
	return motion


func update_outlines() -> void:
	var preview: bool = menu == Menu.FIELD and selected_resource < 0 and not preview_route.is_empty() and tiles[selected].knowledge == Tile.Knowledge.SEEN
	for cell: Vector2i in tiles:
		var color := Color.TRANSPARENT
		var tile: Tile = tiles[cell]
		if cell == selected and menu != Menu.CLOSED:
			color = ACCENT
		elif planning and (cell == drop_cell or (dragged_house != null and relocation_plot(cell))):
			color = Color("#94d999") if cell == drop_cell else Color("#638a6b")
		elif open_scouts.has(cell) or has_gatherers(cell):
			color = Color("#e3ad69")
		elif preview and tile.knowledge == Tile.Knowledge.HIDDEN and cell - selected in DIRECTIONS:
			color = Color("#78968a")
		elif cell == hovered:
			color = SOFT_OUTLINE
		elif menu == Menu.FIELD and cell != BASE and cell in preview_route:
			color = Color("#a6bfa5")
		tile.mark(color)


func has_gatherers(cell: Vector2i) -> bool:
	for kind in Gather.size():
		if crews.has(Vector3i(cell.x, cell.y, kind)):
			return true
	return false


func pile_counts() -> Dictionary:
	var counts: Dictionary = {}
	for key: Vector3i in site_stock:
		counts[key] = Vector3i(site_stock[key], 0, 0)
	for trip: Pickup in pickups.values():
		var existing: Vector3i = counts.get(trip.key, Vector3i.ZERO)
		if trip.loaded:
			existing.z += trip.amount
		else:
			existing.y += trip.amount
		counts[trip.key] = existing
	return counts


func field_total() -> Array[int]:
	var total := empty_resources()
	var counts := pile_counts()
	for key: Vector3i in counts:
		var amount: Vector3i = counts[key]
		total[key.z] += amount.x + amount.y
	return total


func select_pile(key: Vector3i, recenter := false) -> void:
	action_group = ""
	if night_open:
		return
	selected = Vector2i(key.x, key.y)
	selected_resource = key.z
	menu = Menu.FIELD
	if recenter:
		map_focus = cell_position(selected)
		map_focus.y = 0
		move_camera()
	update_hud()
	pop_tile_actions()


func load_progress(key: Vector3i) -> float:
	var crew: GatheringCrew = crews.get(key)
	var value := -1.0
	if crew != null:
		for job in crew.jobs:
			if not job.timer.is_stopped() and job.load > 0:
				var duration := load_duration(job, key.z)
				value = maxf(value, clampf(1.0 - job.timer.time_left / duration, 0.0, 1.0))
	return value


func refresh_badges(counts: Dictionary) -> void:
	var showing := counts.duplicate()
	for key: Vector3i in crews:
		if load_progress(key) >= 0.0 and not showing.has(key):
			showing[key] = Vector3i.ZERO
	for key: Vector3i in badges.keys():
		var amount: Vector3i = showing.get(key, Vector3i.ZERO)
		if amount.x + amount.y == 0 and load_progress(key) < 0.0:
			badges[key].hide()
			badges[key].queue_free()
			badges.erase(key)
	for key: Vector3i in showing:
		var amount: Vector3i = showing[key]
		if amount.x + amount.y == 0 and load_progress(key) < 0.0:
			continue
		if not badges.has(key):
			var badge := FieldBadge.new()
			badge_layer.add_child(badge)
			badge.build(key.z)
			badge.pressed.connect(select_pile.bind(key))
			badge.modulate.a = 0.0
			badge.create_tween().tween_property(badge, "modulate:a", 1.0, 0.19)
			badges[key] = badge
		var badge: FieldBadge = badges[key]
		badge.set_amount(amount.x, amount.y)
		badge.tooltip_text = "%s %d 待取 · %d 已预留" % [RESOURCE_NAMES[key.z], amount.x, amount.y]
	update_badge_positions()


func update_badge_positions(delta := 0.0) -> void:
	var occupied: Array[Rect2] = []
	for key: Vector3i in badges:
		var cell := Vector2i(key.x, key.y)
		var tile: Tile = tiles[cell]
		var height := 1.45 if tile.terrain == "forest" else 0.70
		var world := cell_position(cell) + Vector3.UP * height
		var badge: FieldBadge = badges[key]
		var index := 0
		var total := 0
		for kind in Gather.size():
			if badges.has(Vector3i(cell.x, cell.y, kind)):
				total += 1
				index += int(kind < key.z)
		var screen := camera.unproject_position(world)
		var shift := (index - (total - 1) * 0.5) * 54.0
		badge.position = screen + Vector2(shift - badge.size.x * 0.5, -badge.size.y)
		badge.set_progress(load_progress(key), delta)
		occupied.append(Rect2(badge.position + Vector2(5, 5), badge.size - Vector2(10, 10)))
	var anchor: Variant = hovered
	if menu == Menu.FIELD:
		anchor = selected
	elif menu != Menu.CLOSED and anchor != BASE and not houses.has(anchor) and not facilities.has(anchor):
		anchor = selected
	var priority: Node3D
	if anchor == BASE:
		priority = camp
	elif houses.has(anchor):
		priority = houses[anchor].visual
	elif facilities.has(anchor):
		priority = facilities[anchor].visual
	var plates := building_plates.values()
	if building_plates.has(priority):
		var first = building_plates[priority]
		plates.erase(first)
		plates.push_front(first)
	for plate: BuildingPlate in plates:
		if not is_instance_valid(plate.building) or not plate.building.visible:
			plate.hide()
			continue
		if menu == Menu.FIELD and tile_action_bar.visible:
			var offset := nearest_cell(plate.building.position) - selected
			if offset in DIRECTIONS:
				plate.hide()
				continue
		var screen := camera.unproject_position(plate.building.to_global(Vector3(0, 0, 0.35)))
		var bounds := Rect2(screen + Vector2(-plate.size.x * 0.5, 7.0), plate.size)
		plate.position = bounds.position
		if plate.upgrade_hint.visible:
			bounds.size.x += 20.0
		if tile_action_bar.visible and bounds.intersects(tile_action_bar.get_global_rect().grow(4.0)):
			plate.hide()
			continue
		var obstructed := false
		for used in occupied:
			if used.intersects(bounds):
				obstructed = true
				break
		plate.visible = not obstructed or plate.building == priority
		if plate.visible:
			occupied.append(bounds)


func refresh_building_plates() -> void:
	var current := {camp: "议事厅 · %d级" % (center_stage + 1)}
	var upgrade_ready := {}
	if trader_visual != null:
		current[trader_visual] = "三花的行商摊"
	if ruin_visual != null:
		current[ruin_visual] = "古驿站 · 废弃"
	for cell: Vector2i in houses:
		var house: Housing = houses[cell]
		var status := "施工中" if house.level == 0 else ("%d级 · 升级中" % house.level if house.building else "%d级" % house.level)
		current[house.visual] = "住房 · " + status
		upgrade_ready[house.visual] = upgrade_materials_ready(cell)
	for cell: Vector2i in facilities:
		var site: Dictionary = facilities[cell]
		current[site.visual] = FACILITY_NAMES[site.kind] + (" · %d级" % site.level if site.ready else " · 施工中")
		upgrade_ready[site.visual] = upgrade_materials_ready(cell)
	for model in building_plates.keys():
		if not current.has(model):
			building_plates[model].hide()
			building_plates[model].queue_free()
			building_plates.erase(model)
	for model: Node3D in current:
		var plate: BuildingPlate = building_plates.get(model)
		if plate == null:
			plate = BuildingPlate.new()
			plate.building = model
			building_plate_layer.add_child(plate)
			building_plates[model] = plate
		plate.set_caption(current[model])
		plate.set_upgrade_ready(upgrade_ready.get(model, false))


func show_pickup_details(counts: Dictionary) -> void:
	var key := Vector3i(selected.x, selected.y, selected_resource)
	var amount: Vector3i = counts.get(key, Vector3i.ZERO)
	var worker := available_worker(3)
	var route := pickup_route(key, resident_cell(worker))
	var room := warehouse_available()
	intel_label.text = "地块物资"
	hud_title.text = "取回%s" % RESOURCE_NAMES[key.z]
	details_label.text = "待取  %d\n已预留  %d\n带货回程  %d" % [amount.x, amount.y, amount.z]
	pickup_button.visible = true
	pickup_button.disabled = night_open or amount.x <= 0 or room <= 0 or worker == null or route.is_empty()
	if amount.x <= 0:
		pickup_button.text = "暂时没有可派人取的货"
	elif room == 0:
		pickup_button.text = "仓库暂无可用空间"
	elif worker == null:
		pickup_button.text = "需要一名空闲村民"
	elif route.is_empty():
		pickup_button.text = "暂无可通行路线"
	else:
		var points := outbound_points(route, pickup_offset(key, route))
		var arrival := route_seconds(worker.position, points)
		var delivery := arrival + route_seconds(points[-1], warehouse_route(route.back()))
		details_label.text += "\n\n约 %d 秒取到 · %d 秒回营" % [ceili(arrival), ceili(delivery)]
		var time_left := DAY_SECONDS - day_elapsed
		if arrival >= time_left:
			details_label.text += "\n这趟来不及在天黑前取到。"
		elif delivery >= time_left:
			details_label.text += "\n天黑前可取到，夜间结算入库。"
		var take := mini(amount.x, mini(room, carry_limit(worker)))
		pickup_button.text = "派人取回 %d %s  ·  0 行动点" % [take, RESOURCE_NAMES[key.z]]
		if amount.x > take:
			details_label.text += "\n其余 %d 留在地块。" % (amount.x - take)


func refresh_journal(counts: Dictionary) -> void:
	journal.book.set_open(menu == Menu.TOWN)
	if menu != Menu.TOWN:
		return
	var idle := 0
	var assignments: Dictionary = {}
	for scout: Node3D in open_scouts.values():
		assignments[scout] = "正在勘探"
	for worker in builders:
		assignments[worker] = "正在建造"
	for key: Vector3i in crews:
		var crew: GatheringCrew = crews[key]
		for job in crew.jobs:
			var work: String = GATHER_NAMES[key.z]
			if key.z == Gather.FOOD and renewable_food(Vector2i(key.x, key.y)):
				work = "生产食物"
			assignments[job.worker] = "负责%s" % work
	for trip: Pickup in pickups.values():
		assignments[trip.worker] = "带货回营" if trip.loaded else "去取%s" % RESOURCE_NAMES[trip.key.z]
	var resident_list := PackedStringArray()
	for index in workers.size():
		var activity: String = assignments.get(workers[index], "住处休息")
		if not workers[index].visible:
			idle += 1
		var worker := workers[index]
		var specialty: int = worker.get_meta("specialty")
		resident_list.append("%s  ·  %s%s" % [worker.get_meta("resident_name"), activity,
			"  ·  擅长" + GATHER_NAMES[specialty] if specialty >= 0 else ""])
	var intake := empty_resources()
	var staging := empty_resources()
	var entries: Array = []
	for key: Vector3i in counts:
		var amounts: Vector3i = counts[key]
		intake[key.z] += amounts.z
		staging[key.z] += amounts.x + amounts.y
		var tile: Tile = tiles[Vector2i(key.x, key.y)]
		entries.append({"key": key, "label": "%s · %s %d　(%d, %d)" % [
			NAMES[tile.terrain], RESOURCE_NAMES[key.z], amounts.x + amounts.y + amounts.z, key.x, key.y]})
	var title := "%s第 %d 天  ·  %s\n居民 %d  ·  空闲 %d\n仓库可用 %d / %d\n%s" % [
		campaign.season(day), season_day(), CENTER_NAMES[center_stage], workers.size(), idle, warehouse_available(), warehouse_capacity(), supply_status]
	var housing_list := "议事厅床位  ·  %d / %d" % [camp_resident_count(), CAMP_SLOTS.size()]
	for cell: Vector2i in houses:
		var house: Housing = houses[cell]
		var names := PackedStringArray()
		for resident in house.residents:
			names.append(resident.get_meta("resident_name"))
		housing_list += "\n\n住房 (%d, %d)  ·  %d / %d 已入住" % [cell.x, cell.y, names.size(), house.level]
		if not names.is_empty():
			housing_list += "\n" + "、".join(names)
		if house.building:
			housing_list += "\n施工中"
	for cell: Vector2i in facilities:
		if not station_ready(cell):
			continue
		var stationed := PackedStringArray()
		for worker: Node3D in post_residents:
			if post_residents[worker] == cell:
				stationed.append(worker.get_meta("resident_name"))
		housing_list += "\n\n%s (%d, %d) · 驻站 %d / %d" % [FACILITY_NAMES[facilities[cell].kind], cell.x, cell.y, stationed.size(), station_capacity(cell)]
		if not stationed.is_empty():
			housing_list += "\n" + "、".join(stationed)
	journal.refresh_book(title, resident_list, housing_list, has_bed(), candidates, stock, staging, intake, entries)
	journal.refresh_residents(workers, requirements())


func requirements() -> String:
	var completed := 0
	for house: Housing in houses.values():
		completed += int(house.level > 0)
	if center_stage == 0:
		return "村庄条件 · 人口 %d/7 · 住房 %d/1 · 农田 %d/1" % [workers.size(), completed, facility_count(Facility.FARM)]
	if center_stage == 1:
		return "城镇条件 · 人口 %d/9 · 住房 %d/2\n牧场或作坊 %d/1" % [workers.size(), completed, facility_count(Facility.PASTURE) + facility_count(Facility.WORKSHOP)]
	return "议事厅已升至城镇"


func open_progression(magic: bool) -> void:
	if (night_open and magic) or skipping or trade_window.visible or progression.closing:
		return
	if not progression.visible:
		pause_before_progression = get_tree().paused
	get_tree().paused = true
	refresh_speed_glow()
	panning = false
	progression.open(magic)
	update_progression()


func dismiss_progression() -> void:
	if not progression.visible or progression.closing:
		return
	await progression.slide_out()
	get_tree().paused = pause_before_progression
	refresh_speed_glow()
	if night_open:
		journal.next_button.grab_focus()

func learn_magic(index: int) -> void:
	if night_open or not campaign.can_learn(index, center_stage):
		return
	campaign.points -= 1
	campaign.learned[index] = true
	update_hud()


func reward_origin(cell: Vector2i) -> Vector2:
	var point := camera.unproject_position(cell_position(cell) + Vector3.UP * 0.65)
	return point.clamp(Vector2.ZERO, get_viewport().get_visible_rect().size)


func claim_task(index: int, origin: Vector2) -> void:
	if index < 0 or index >= campaign.targets.size() or campaign.claimed[index]:
		return
	if campaign.task_totals(delivered_today)[index] < campaign.targets[index]:
		return
	campaign.claimed[index] = true
	earn_experience(Campaign.QUEST_XP, origin)
	var wood := mini(Campaign.QUEST_WOOD, warehouse_available())
	if wood > 0:
		stock[Gather.WOOD] += wood
		status_hud.fly_reward("wood", wood, origin + Vector2(52, 0))
	if wood < Campaign.QUEST_WOOD:
		add_site_stock(Vector3i(0, 0, Gather.WOOD), Campaign.QUEST_WOOD - wood)
		progression.notice.text = "仓库已满，放不下的奖励木头留在议事厅地块待取。"
	if night_open:
		journal.update_night_stock(stock, field_total())
		update_night_claims()
	update_hud()


func update_night_claims() -> void:
	journal.set_unclaimed(campaign.pending_tasks(delivered_today))


func quarterly_goals(goal_stage: int) -> Array:
	var homes := 0
	for house: Housing in houses.values():
		homes += int(house.level > 0)
	var goals := [
		["城镇人口", "journal", workers.size(), 7 if goal_stage == 1 else 9, ""],
		["已完工住房", HOUSE_ART[goal_stage - 1], homes, goal_stage, ""],
	]
	var kinds := [Facility.FARM] if goal_stage == 1 else [Facility.PASTURE, Facility.WORKSHOP]
	for kind: int in kinds:
		var count := facility_count(kind)
		var state := "已完工" if count > 0 else ("待建造" if facility_unlocked(kind) else "待研习")
		if count == 0:
			for site: Dictionary in facilities.values():
				if site.kind == kind:
					state = "施工中"
					break
		goals.append([FACILITY_NAMES[kind], FACILITY_ART[kind], count, 1, state])
	return goals


func update_progression() -> void:
	if not progression.visible:
		return
	var totals := campaign.task_totals(delivered_today)
	var names := [campaign.daily_resource, 3, 4]
	var titles := []
	for index in campaign.targets.size():
		titles.append(Campaign.DAILY_NAMES[names[index]] % campaign.targets[index])
	var goal_stage := 1 if day <= Campaign.SEASON_DAYS else 2
	var achieved := maxi(center_stage, pending_stage) >= goal_stage
	var quarterly := "异变已解除" if restored else "%s第 %d 天入夜结算 · 剩余 %d 天" % [
		campaign.season(day), Campaign.SEASON_DAYS, campaign.deadline(day) - day + 1]
	if not restored and day > Campaign.SEASON_DAYS * 2:
		quarterly = "城镇考核通过 · 修复古驿站以解除异变"
	progression.set_tasks(titles, totals, campaign.targets, campaign.claimed, night_open)
	progression.set_quarter(quarterly, goal_stage, quarterly_goals(goal_stage), achieved, restored)
	progression.set_magic(campaign, center_stage)

func locate_task(index: int) -> void:
	if night_open:
		return
	if index == 0:
		for key: Vector3i in site_stock:
			if key.z == campaign.daily_resource or (campaign.daily_resource == Gather.FOOD and RATION_VALUES.has(key.z)):
				dismiss_progression()
				select_pile(key, true)
				return
	else:
		for cell: Vector2i in tiles:
			if (index == 1 and not find_route(cell).is_empty()) or (
				index == 2 and relocation_plot(cell)):
				dismiss_progression()
				select_tile(cell)
				map_focus = cell_position(cell).slide(Vector3.UP)
				move_camera()
				return
	progression.notice.text = "目前没有可定位的目标。"


func update_worker_picker() -> void:
	field_workers.visible = menu == Menu.FIELD
	if not field_workers.visible:
		return
	var idle: Array[Node3D] = []
	for worker in workers:
		if not worker.visible:
			idle.append(worker)
	if idle != field_roster or field_workers.item_count == 0:
		field_roster = idle
		field_workers.clear()
		field_workers.add_item("自动 · 按工作推荐")
		field_workers.get_popup().set_item_tooltip(0, "根据你点下的命令，选对应能力最高的空闲居民。")
		for worker in idle:
			var stats: Array = worker.get_meta("stats")
			var titles := ["采集", "狩猎", "建造", "搬运", "勘探"]
			var best := stats.find(stats.max())
			field_workers.add_item("%s  ·  %s %d/5" % [worker.get_meta("resident_name"), titles[best], stats[best]])
			field_workers.get_popup().set_item_tooltip(field_workers.item_count - 1,
				"采集 %d/5 · 狩猎 %d/5 · 建造 %d/5 · 搬运 %d/5 · 勘探 %d/5" % stats)
	field_workers.select(field_roster.find(assigned_worker) + 1)


func field_worker_selected(index: int) -> void:
	assigned_worker = field_roster[index - 1] if index > 0 else null
	update_hud()


func show_work_recommendation(button: Button, skill: int) -> void:
	var worker := available_worker(skill)
	if worker == null:
		button.tooltip_text = "暂无空闲居民"
		return
	var stats: Array = worker.get_meta("stats")
	var skills := ["采集", "狩猎", "建造", "搬运", "勘探"]
	button.tooltip_text = "%s · %s · %s %d/5" % [
		"已选" if is_instance_valid(assigned_worker) else "推荐",
		worker.get_meta("resident_name"), skills[skill], stats[skill]]


func upgrade_level(cell: Vector2i) -> int:
	var house: Housing = houses.get(cell)
	if house != null:
		return house.level if house.level in [1, 2] else 0
	var site: Dictionary = facilities.get(cell, {})
	var level: int = site.get("level", 0)
	return level if site.get("ready", false) and site.kind != Facility.RUIN and level in [1, 2] else 0


func upgrade_cost(cell: Vector2i, level: int) -> Dictionary:
	return {Gather.WOOD: building_cost(HOUSING_COSTS[level])} if houses.has(cell) else site_cost(facilities[cell].kind, level)


func upgrade_requirement(cell: Vector2i, level: int) -> String:
	var house: Housing = houses.get(cell)
	if (house != null and house.building) or facilities.get(cell, {}).get("upgrading", false):
		return "升级施工中"
	if level > center_stage:
		return "议事厅升阶后可升级"
	if house != null and not housing_unlocked(level):
		return "需要研习%s" % Campaign.RESEARCH[Campaign.Spell.COTTAGE if level == 1 else Campaign.Spell.TOWNHOUSE][0]
	var costs := upgrade_cost(cell, level)
	var missing := {}
	for kind: int in costs:
		if stock[kind] < costs[kind]:
			missing[kind] = costs[kind] - stock[kind]
	return "缺少 %s" % cost_text(missing) if not missing.is_empty() else ""


func upgrade_materials_ready(cell: Vector2i) -> bool:
	var level := upgrade_level(cell)
	return level > 0 and upgrade_requirement(cell, level).is_empty()


func refresh_upgrade_shortcut(cell: Vector2i, enabled: bool, builder: Node3D) -> void:
	var level := upgrade_level(cell)
	upgrade_button.visible = enabled and level > 0
	if not upgrade_button.visible:
		return
	var reason := upgrade_requirement(cell, level)
	if reason.is_empty():
		var site: Dictionary = facilities.get(cell, {})
		var origin := resident_cell(builder)
		var route := find_shore_route(cell, origin) if site.get("kind") == Facility.BRIDGE else job_route(cell, Tile.Knowledge.SURVEYED, true, origin)
		if commands <= 0:
			reason = "行动点已用完"
		elif builder == null:
			reason = "暂无空闲施工居民"
		elif route.is_empty():
			reason = "尚无可施工的通路"
	upgrade_button.disabled = not reason.is_empty()
	upgrade_button.queue_redraw()
	upgrade_button.tooltip_text = reason if not reason.is_empty() else "升到 %d 级 · %s + 1 行动点" % [level + 1, cost_text(upgrade_cost(cell, level))]
	upgrade_confirm.disabled = upgrade_button.disabled
	upgrade_confirm.text = "确认升级到 %d 级" % (level + 1)
	upgrade_confirm.tooltip_text = upgrade_button.tooltip_text


func action_panel_style() -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = Color("#1a2720fa")
	box.border_color = Color("#b29965")
	box.set_border_width_all(1)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, 6)
	return box


func toggle_tile_actions(group: String) -> void:
	action_group = "" if action_group == group else group
	tile_action_scroll.scroll_vertical = 0
	update_hud()


func refresh_tile_actions() -> void:
	var active := menu == Menu.FIELD and not night_open and not planning and not trade_window.visible
	var town := selected == BASE and selected_resource < 0
	var has_work := pickup_button.visible or scout_button.visible or charm_button.visible or tool_button.visible or post_roster.visible
	for button: Button in gather_buttons + stop_buttons:
		has_work = has_work or button.visible
	for shortcut in town_shortcuts:
		shortcut.visible = active and town
	build_shortcut.visible = active and not town and build_button.visible
	for button in facility_buttons:
		build_shortcut.visible = build_shortcut.visible or (active and not town and button.visible)
	work_shortcut.visible = active and not town and has_work and not trade_button.visible
	work_shortcut.set_title("取货" if selected_resource >= 0 else ("入住" if houses.has(selected) else ("驻扎" if station_ready(selected) else "工作")))
	field_workers.visible = scout_button.visible or pickup_button.visible
	for button: Button in gather_buttons:
		field_workers.visible = field_workers.visible or button.visible
	build_choices.visible = build_shortcut.visible and action_group == "build"
	work_choices.visible = work_shortcut.visible and action_group == "work"
	upgrade_choices.visible = upgrade_button.visible and action_group == "upgrade"
	tile_action_bar.visible = active and (town or build_shortcut.visible or work_shortcut.visible or upgrade_button.visible or trade_button.visible)
	tile_action_panel.visible = tile_action_bar.visible and (build_choices.visible or work_choices.visible or upgrade_choices.visible)
	position_tile_actions()
	update_badge_positions()


func pop_tile_actions() -> void:
	if action_motion != null:
		action_motion.kill()
	if not tile_action_bar.visible:
		return
	tile_action_bar.modulate.a = 0.12
	action_rise = 56.0
	position_tile_actions()
	action_motion = create_tween().set_parallel().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	action_motion.tween_property(tile_action_bar, "modulate:a", 1.0, 0.24)
	action_motion.tween_method(func(offset: float) -> void:
		action_rise = offset
		position_tile_actions(), 56.0, 0.0, 0.30)


func selected_action_anchor() -> Vector3:
	var model: Node3D = null
	if selected == BASE:
		model = camp
	elif facilities.has(selected):
		model = facilities[selected].visual
	elif houses.has(selected):
		model = houses[selected].visual
	elif selected == trader_cell:
		model = trader_visual
	elif selected == ruin_cell:
		model = ruin_visual
	if model != null:
		for child: Node in model.get_children():
			if child is Sprite3D:
				var rect: AABB = child.get_aabb()
				return child.to_global(Vector3(0, rect.end.y, 0))
	var tile: Tile = tiles[selected]
	if tile.peak != null and tile.knowledge != Tile.Knowledge.HIDDEN:
		return tile.peak.to_global(Vector3(0, tile.peak.get_aabb().end.y, 0))
	return cell_position(selected) + Vector3.UP * (1.1 if tile.terrain == "forest" else 0.2)


func position_tile_actions() -> void:
	var screen_size := get_viewport().get_visible_rect().size
	var edge := screen_size.x - 16.0
	if menu == Menu.FIELD:
		edge -= tile_card.panel_width + 22.0
	var focus := camera.unproject_position(cell_position(selected) + Vector3(0, 0, 0.35))
	if tile_action_bar.visible:
		tile_action_bar.reset_size()
		var bar_size := tile_action_bar.size
		var above := camera.unproject_position(selected_action_anchor())
		var x := clampf(above.x - bar_size.x / 2.0, 78.0, maxf(78.0, edge - bar_size.x))
		var y := clampf(above.y - bar_size.y - 9.0 + action_rise, 115.0, screen_size.y - bar_size.y - 18.0)
		tile_action_bar.position = Vector2(x, y)
	if feedback_plate.visible:
		feedback_plate.reset_size()
		feedback_plate.position = Vector2(clampf(focus.x - feedback_plate.size.x / 2.0, 78.0, maxf(78.0, edge - feedback_plate.size.x)),
			clampf(focus.y - 56.0, 107.0, screen_size.y - feedback_plate.size.y - 18))


func show_feedback(text: String) -> void:
	feedback.text = text
	if feedback_fade != null:
		feedback_fade.kill()
	feedback_plate.modulate.a = 1.0
	feedback_plate.show()
	feedback_fade = create_tween()
	feedback_fade.tween_interval(2.0)
	feedback_fade.tween_property(feedback_plate, "modulate:a", 0.0, 0.22)
	feedback_fade.tween_callback(feedback_plate.hide)


func update_hud() -> void:
	refresh_season()
	refresh_town()
	refresh_ground_transitions()
	var tile: Tile = tiles[selected]
	var needed := workers.size()
	var lacking := food_rations() < needed or stock[Gather.WATER] < needed
	supply_status = "今晚需要  %d 口粮 · %d 水  ·  现有口粮 %d" % [needed, needed, food_rations()]
	if lacking:
		supply_status += "  ·  库存不足"
	if gathering_rate < 1.0:
		supply_status += "  ·  采集效率 -25%"
	status_hud.set_status(commands, command_limit(), stock, warehouse_available(), warehouse_capacity(),
		surveyed_count, tiles.size(), coins)
	status_hud.set_experience(campaign.level, campaign.experience, campaign.threshold(), campaign.points)
	status_hud.set_pending_tasks(campaign.pending_tasks(delivered_today))
	status_hud.set_speed_buttons(speed_mode, commands == 0, night_open)
	status_hud.set_clock(season_day(), DAY_SECONDS - day_elapsed, DAY_SECONDS, campaign.season(day))
	update_progression()
	var route := find_route(selected, Tile.Knowledge.SEEN, false, resident_cell(available_worker(4)))
	preview_route = route
	if menu == Menu.FIELD:
		if selected_resource >= 0:
			preview_route = pickup_route(Vector3i(selected.x, selected.y, selected_resource), resident_cell(available_worker(3)))
		elif tile.knowledge == Tile.Knowledge.SURVEYED:
			var building := houses.has(selected) or residential_plot(selected)
			preview_route = find_shore_route(selected) if is_water(tile) else find_route(selected, Tile.Knowledge.SURVEYED, building)
	var counts := pile_counts()
	refresh_building_plates()
	refresh_badges(counts)
	tile_card.set_open(menu == Menu.FIELD)
	update_portrait()
	update_worker_picker()
	refresh_journal(counts)
	pickup_button.hide()
	scout_button.visible = selected_resource < 0 and not route.is_empty()
	scout_button.disabled = commands == 0 or available_worker() == null or open_scouts.has(selected)
	show_work_recommendation(scout_button, 4)
	var gathering_details := update_gather_actions(tile)
	var house: Housing = houses.get(selected)
	var site: Dictionary = facilities.get(selected, {})
	var field_menu := menu == Menu.FIELD and selected_resource < 0
	var builder := available_worker(2)
	var builder_home := resident_cell(builder)
	for kind in facility_buttons.size():
		var button := facility_buttons[kind]
		button.visible = field_menu and facility_plot(kind, selected) and (facility_unlocked(kind) or kind == Facility.BRIDGE)
		if not button.visible:
			continue
		var costs := site_cost(kind, 0)
		var path := find_shore_route(selected, builder_home) if kind == Facility.BRIDGE else job_route(selected, Tile.Knowledge.SURVEYED, true, builder_home)
		button.disabled = not facility_unlocked(kind) or commands <= 0 or not can_pay(costs) or builder == null or path.is_empty()
		var label := "修复" if kind == Facility.RUIN else "建造"
		button.text = "%s%s · %s + 1 行动点" % [label, FACILITY_NAMES[kind], cost_text(costs)]
		if kind == Facility.BRIDGE and not facility_unlocked(kind):
			button.text = "木桥需要先研习绘路符"
		show_work_recommendation(button, 2)
	refresh_upgrade_shortcut(selected, field_menu, builder)
	trade_button.visible = field_menu and (trader_cell == selected or (site.get("ready", false) and site.get("kind") == Facility.SHOP))
	tool_button.visible = field_menu and ((trade_tools.has(-1) and ruin_cell != null and tiles[ruin_cell].knowledge == Tile.Knowledge.HIDDEN) or trade_tools.has(-2))
	post_roster.visible = field_menu and (station_ready(selected) or (house != null and house.level > 0))
	if post_roster.visible:
		refresh_post_roster()
	charm_button.visible = menu == Menu.FIELD and selected_resource < 0 and campaign.learned[Campaign.Spell.ROAD] and tile.knowledge == Tile.Knowledge.SURVEYED and not is_water(tile)
	charm_button.text = "在本格绘制道路符  ·  %d / %d" % [charm_cells.size(), charm_limit()]
	if selected in charm_cells:
		charm_button.text = "本格已有道路符"
	elif charm_cells.size() >= charm_limit():
		charm_button.text = "将最早绘制的道路符移到本格"
	charm_button.disabled = selected in charm_cells
	build_button.visible = field_menu and residential_plot(selected)
	if build_button.visible:
		show_work_recommendation(build_button, 2)
		var cost := building_cost(HOUSING_COSTS[0])
		build_button.text = "建造住房 · %d 木头 + 1 行动点" % cost
		build_button.disabled = commands <= 0 or builder == null or stock[Gather.WOOD] < cost or job_route(selected, Tile.Knowledge.SURVEYED, true, builder_home).is_empty()
	if selected_resource >= 0:
		show_pickup_details(counts)
	elif selected == BASE:
		intel_label.text = "等级 %d" % (center_stage + 1)
		hud_title.text = "议事厅"
		details_label.text = "%s\n居民 %d  ·  仓库余量 %d\n%s" % [
			CENTER_NAMES[center_stage], workers.size(), warehouse_available(), supply_status]
	elif house != null:
		intel_label.text = "施工中" if house.building else "住宅"
		hud_title.text = "住房"
		var names := PackedStringArray()
		for resident in house.residents:
			names.append(resident.get_meta("resident_name"))
		details_label.text = "等级 %d  ·  入住 %d / %d\n%s" % [house.level, names.size(), house.level,
			"、".join(names) if not names.is_empty() else "暂无住户"]
	elif not site.is_empty():
		intel_label.text = ("等级 %d" % site.level) if site.ready else "施工中"
		hud_title.text = FACILITY_NAMES[site.kind]
		var description: String = FACILITY_DESCRIPTIONS[site.kind]
		if site.kind == Facility.BRIDGE and not site.ready:
			description = "施工期间仍无法过河。"
		elif site.kind == Facility.MINE:
			description += "  ·  剩余铁矿 %d" % tile.ore
		elif station_ready(selected):
			description += "\n驻站 %d / %d 人" % [post_residents.values().count(selected), station_capacity(selected)]
			var residents := PackedStringArray()
			for resident: Node3D in post_residents:
				if post_residents[resident] == selected:
					residents.append(resident.get_meta("resident_name"))
			if not residents.is_empty():
				description += "\n" + "、".join(residents)
		for worker: Node3D in builders:
			if builders[worker] == selected and orders.get(worker, {}).get("phase") != "return":
				description += "\n施工人员  %s" % worker.get_meta("resident_name")
		details_label.text = description + gathering_details
	elif selected == trader_cell:
		intel_label.text = "停留至今晚"
		hud_title.text = "三花的行商摊"
		details_label.text = "本次来访带来了特殊货品，可以购买或查看收购需求。"
	elif selected == ruin_cell and tile.knowledge != Tile.Knowledge.HIDDEN:
		intel_label.text = "遗迹"
		hud_title.text = "废弃古驿站"
		details_label.text = "勘探后可以安排施工修复这处驿站。"
	elif tile.knowledge == Tile.Knowledge.HIDDEN:
		intel_label.text = "迷雾"
		hud_title.text = "未知地块"
		details_label.text = "勘探附近的地块后，这里的地形才会显露。"
	else:
		hud_title.text = NAMES[tile.terrain]
		if tile.knowledge == Tile.Knowledge.SURVEYED:
			intel_label.text = "资源已探明"
			if tile.terrain == "forest":
				details_label.text = "木头  %d / %d\n猎物  %d / %d" % [tile.wood, tile.initial_wood, tile.prey, tile.initial_prey]
			elif tile.terrain == "grassland":
				details_label.text = "猎物  %d / %d" % [tile.prey, tile.initial_prey]
			elif tile.terrain == "mountains":
				details_label.text = "石头  %d / %d\n%s" % [tile.stone, tile.initial_stone, tile.resources]
				if tile.ore > 0:
					details_label.text += "\n铁矿  %d" % tile.ore
			else:
				details_label.text = tile.resources
			details_label.text += gathering_details
		elif open_scouts.has(selected):
			intel_label.text = "正在勘探"
			details_label.text = "勘探员抵达后，会查清本格资源。"
		else:
			intel_label.text = "地形已见 · 尚未勘探"
			details_label.text = "勘探本格后可查看资源，并揭开邻格地形。"
	if menu == Menu.FIELD and selected_resource < 0 and tile.knowledge != Tile.Knowledge.HIDDEN:
		var bonuses := PackedStringArray()
		if town_cells.has(selected):
			bonuses.append("镇区通行")
		elif riverbank(selected):
			bonuses.append("河岸地形")
		if station_roads.has(selected):
			bonuses.append("驿路加成")
		if selected in charm_cells:
			bonuses.append("道路符加成")
		details_label.text += "\n\n通行耗时 %.1f 秒 / 格" % (SECONDS_PER_HEX * travel_factor(selected))
		if not bonuses.is_empty():
			details_label.text += "\n" + " · ".join(bonuses)
	update_outlines()
	refresh_tile_actions()
	back_to_tile.visible = tile_action_panel.visible
	if tile_action_panel.visible:
		match action_group:
			"upgrade":
				intel_label.text = "建筑升级"
				var level := upgrade_level(selected)
				details_label.text = "%d 级 → %d 级\n所需材料  %s\n行动点  1" % [
					level, level + 1, cost_text(upgrade_cost(selected, level))]
				if upgrade_confirm.disabled:
					details_label.text += "\n" + upgrade_confirm.tooltip_text
			"work":
				intel_label.text = "工作与调配"
			"build":
				intel_label.text = "施工选项"


func update_gather_actions(tile: Tile) -> String:
	var details := ""
	var surveyed := tile.knowledge == Tile.Knowledge.SURVEYED
	var can_issue := commands > 0 and available_worker() != null
	var site: Dictionary = facilities.get(selected, {})
	for kind in Gather.size():
		var start := gather_buttons[kind]
		var stop := stop_buttons[kind]
		var crew: GatheringCrew = crews.get(Vector3i(selected.x, selected.y, kind))
		var recipe_facility := Facility.SMITHY if kind == Gather.IRON else Facility.MAGIC
		var recipe_here: bool = RECIPES.has(kind) and site.get("ready", false) and site.kind == recipe_facility
		start.visible = selected_resource < 0 and surveyed and (recipe_here or unreserved_resource(tile, kind, 0) > 0)
		stop.visible = selected_resource < 0 and crew != null
		if not start.visible and crew == null:
			continue
		var name_of_job: String = GATHER_NAMES[kind]
		var skill := gather_skill(kind, selected)
		show_work_recommendation(start, skill)
		var from := resident_cell(available_worker(skill))
		var shore_missing := kind == Gather.WATER and find_shore_route(selected, from).is_empty()
		var land_missing := kind != Gather.WATER and job_route(selected, Tile.Knowledge.SURVEYED, true, from).is_empty()
		start.text = "持续%s  ·  1 行动点" % name_of_job if crew == null else "%s加派 1 人  ·  1 行动点" % name_of_job
		start.disabled = not can_issue or shore_missing or land_missing or (crew != null and (
			crew.finishing or crew.jobs.size() >= GATHER_POSITIONS.size() or unreserved_resource(tile, kind, crew.reserved) <= 0))
		if shore_missing:
			start.text = "需先勘探可从营地抵达的岸边"
		elif land_missing:
			start.text = "营地与本格尚未连通"
		elif recipe_here and not can_pay(RECIPES[kind]):
			start.disabled = true
			start.text = "本批需要 %s" % cost_text(RECIPES[kind])
		if start.visible:
			var available := unreserved_resource(tile, kind, 0)
			var batch := batch_limit(kind, selected) if recipe_here else mini(batch_limit(kind, selected), available)
			if batch > 0:
				details += "\n%s · 单批 %d %s" % [name_of_job, batch, RESOURCE_NAMES[kind]]
		if crew == null:
			continue
		stop.disabled = crew.finishing
		stop.text = "%s收工中" % name_of_job if crew.finishing else "%s完成本批后收工" % name_of_job
		for job in crew.jobs:
			var status := "返回住处" if job.returning else "前往地块"
			if not job.timer.is_stopped():
				var full_time := load_duration(job, kind)
				status = "%s中 · 本批 %d%%" % [name_of_job, roundi(clampf(1.0 - job.timer.time_left / full_time, 0.0, 1.0) * 100)]
			details += "\n%s  ·  %s" % [job.worker.get_meta("resident_name"), status]
	return details


func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	var theme := Theme.new()
	theme.default_font = BODY_FONT
	theme.default_font_size = 17
	root.theme = theme
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	building_plate_layer = Control.new()
	building_plate_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(building_plate_layer)
	badge_layer = Control.new()
	badge_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(badge_layer)
	badge_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	speed_glow = SpeedGlow.new()
	root.add_child(speed_glow)
	Session.settings_changed.connect(refresh_speed_glow)

	marisa = TextureRect.new()
	marisa.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	marisa.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	marisa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(marisa)
	marisa.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	marisa.offset_right = -18
	marisa.hide()

	tile_card = SidePanel.new()
	var card := tile_card
	root.add_child(card)
	card.arrange(367, 550)
	var paper := StyleBoxTexture.new()
	paper.texture = QUEST_BOARD
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		paper.set_content_margin(side, 40 if side == SIDE_BOTTOM or side == SIDE_TOP else 35)
	card.add_theme_stylebox_override("panel", paper)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	intel_label = make_label("", 16, Color("#86482c"))
	column.add_child(intel_label)
	hud_title = make_label("", 32, PAPER_INK)
	hud_title.add_theme_font_override("font", TITLE_FONT)
	column.add_child(hud_title)
	var divider := ColorRect.new()
	divider.color = Color("#947344")
	divider.custom_minimum_size.y = 1
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)
	details_label = make_label("", 17, PAPER_INK)
	details_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details_label.custom_minimum_size.y = 56
	column.add_child(details_label)
	tile_action_bar = PanelContainer.new()
	tile_action_bar.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.add_child(tile_action_bar)
	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 5)
	tile_action_bar.add_child(action_row)
	build_shortcut = hex_action("建造", "build")
	build_shortcut.pressed.connect(toggle_tile_actions.bind("build"))
	action_row.add_child(build_shortcut)
	work_shortcut = hex_action("工作", "work")
	work_shortcut.pressed.connect(toggle_tile_actions.bind("work"))
	action_row.add_child(work_shortcut)
	for page in [1, 2]:
		var shortcut := hex_action("居民" if page == 1 else "仓库", "people" if page == 1 else "stock")
		shortcut.pressed.connect(open_town_page.bind(page))
		action_row.add_child(shortcut)
		town_shortcuts.append(shortcut)
	tile_action_panel = PanelContainer.new()
	tile_action_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	tile_action_scroll = scroll
	back_to_tile = make_action_button("返回地块概况", true)
	back_to_tile.pressed.connect(func() -> void:
		action_group = ""
		tile_action_scroll.scroll_vertical = 0
		update_hud())
	column.add_child(back_to_tile)
	column.add_child(tile_action_panel)
	var choices := VBoxContainer.new()
	choices.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile_action_panel.add_child(choices)
	build_choices = VBoxContainer.new()
	work_choices = VBoxContainer.new()
	upgrade_choices = VBoxContainer.new()
	choices.add_child(build_choices)
	choices.add_child(work_choices)
	choices.add_child(upgrade_choices)
	upgrade_confirm = make_action_button("确认升级")
	upgrade_confirm.pressed.connect(order_upgrade)
	upgrade_choices.add_child(upgrade_confirm)
	field_workers = OptionButton.new()
	field_workers.fit_to_longest_item = false
	field_workers.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	field_workers.item_selected.connect(field_worker_selected)
	work_choices.add_child(field_workers)
	pickup_button = make_action_button("")
	work_choices.add_child(pickup_button)
	pickup_button.pressed.connect(dispatch_pickup)
	build_button = make_action_button("")
	build_choices.add_child(build_button)
	build_button.pressed.connect(order_housing)
	for kind in FACILITY_NAMES.size():
		var facility := make_action_button("")
		facility.pressed.connect(order_facility.bind(kind))
		build_choices.add_child(facility)
		facility_buttons.append(facility)
	upgrade_button = hex_action("升级", "upgrade")
	upgrade_button.pressed.connect(toggle_tile_actions.bind("upgrade"))
	action_row.add_child(upgrade_button)
	trade_button = hex_action("交易", "trade")
	trade_button.pressed.connect(open_trade)
	action_row.add_child(trade_button)
	tool_button = make_action_button("使用购买的线索或罗盘", true)
	tool_button.pressed.connect(use_trade_tool)
	work_choices.add_child(tool_button)
	post_roster = OptionButton.new()
	post_roster.fit_to_longest_item = false
	post_roster.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	post_roster.item_selected.connect(set_station_resident)
	work_choices.add_child(post_roster)
	charm_button = make_action_button("在本格绘制道路符", true)
	charm_button.pressed.connect(draw_selected_charm)
	work_choices.add_child(charm_button)
	scout_button = make_action_button("派遣勘探  ·  1 行动点")
	work_choices.add_child(scout_button)
	scout_button.pressed.connect(dispatch_scout)
	for kind in Gather.size():
		var start := make_action_button("")
		work_choices.add_child(start)
		start.pressed.connect(dispatch_gatherer.bind(kind))
		gather_buttons.append(start)
		var stop := make_action_button("", true)
		work_choices.add_child(stop)
		stop.pressed.connect(request_gathering_stop.bind(kind))
		stop_buttons.append(stop)
	feedback_plate = PanelContainer.new()
	feedback_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_plate.add_theme_stylebox_override("panel", action_panel_style())
	root.add_child(feedback_plate)
	feedback = make_label("", 15, ACCENT)
	feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback.custom_minimum_size.x = 222
	feedback_plate.add_child(feedback)
	feedback_plate.hide()

	status_hud = GameHud.new()
	root.add_child(status_hud)
	status_hud.speed_requested.connect(time_control)
	status_hud.progression_requested.connect(open_progression)
	journal = Journal.new()
	root.add_child(journal)
	journal.pickup_selected.connect(func(key: Vector3i) -> void: select_pile(key, true))
	journal.next_day_requested.connect(start_next_day)
	journal.resident_requested.connect(recruit)
	journal.assignment_requested.connect(choose_worker)
	journal.planning_requested.connect(set_planning.bind(true))
	journal.claims_requested.connect(open_progression.bind(false))
	progression = ProgressionWindow.new()
	root.add_child(progression)
	progression.dismissed.connect(dismiss_progression)
	progression.locate_requested.connect(locate_task)
	progression.claim_requested.connect(claim_task)
	progression.learn_requested.connect(learn_magic)
	trade_window = TradeWindow.new()
	root.add_child(trade_window)
	trade_window.dismissed.connect(close_trade)
	trade_window.mode_changed.connect(func(_selling: bool) -> void: refresh_trade())
	trade_window.traded.connect(exchange_goods)
	pause_menu = PauseMenu.new()
	pause_menu.game = self
	root.add_child(pause_menu)
	planning_hint = make_label("重新规划  ·  拖动住房到空地  ·  Esc 退出", 20, ACCENT)
	root.add_child(planning_hint)
	planning_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	planning_hint.offset_left = -238
	planning_hint.offset_right = 238
	planning_hint.offset_top = -116
	planning_hint.offset_bottom = -75
	planning_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	planning_hint.hide()
	skip_dialog = ConfirmationDialog.new()
	skip_dialog.process_mode = Node.PROCESS_MODE_ALWAYS
	skip_dialog.title = "跳过剩余白天"
	skip_dialog.ok_button_text = "推进到入夜"
	skip_dialog.confirmed.connect(skip_day)
	add_child(skip_dialog)


func make_label(content: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = content
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func update_portrait() -> void:
	var art: Texture2D = PORTRAITS[Campaign.SEASONS.find(campaign.season(day))]
	if marisa.texture != art:
		marisa.texture = art
		var ratio := float(art.get_width()) / art.get_height()
		var width := minf(399.0, 572.0 * ratio)
		marisa.offset_left = marisa.offset_right - width
		marisa.offset_top = -width / ratio
	var show_portrait := menu == Menu.CLOSED and not planning
	if show_portrait == portrait_visible:
		return
	portrait_visible = show_portrait
	if portrait_motion:
		portrait_motion.kill()
	if show_portrait:
		if not marisa.visible:
			marisa.modulate.a = 0.0
		marisa.show()
	portrait_motion = marisa.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	portrait_motion.tween_property(marisa, "modulate:a", 1.0 if show_portrait else 0.0, 0.21)
	if not show_portrait:
		portrait_motion.tween_callback(marisa.hide)


func make_action_button(title: String, secondary := false) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(60, 34 if secondary else 40)
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var ink := Color("#f5e6c2")
	for property in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(property, ink)
	button.add_theme_color_override("font_disabled_color", Color("#aaa5a0"))
	var fill := Color("#3a3326") if secondary else Color("#354b3b")
	var edge := Color("#a48a60") if secondary else Color("#c6a66a")
	for state in ["normal", "hover", "pressed"]:
		var shade := fill
		if state == "hover":
			shade = fill.lightened(0.12)
		elif state == "pressed":
			shade = fill.darkened(0.14)
		var face := style(shade, edge, 1, 8)
		button.add_theme_stylebox_override(state, face)
	button.add_theme_stylebox_override("disabled", style(Color("#303635"), Color("#737670"), 1, 8))
	return button


func hex_action(title: String, symbol: String) -> HexAction:
	var button := HexAction.new()
	button.title = title
	button.symbol = symbol
	return button


func style(background: Color, border: Color, radius: int, pad: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		box.set_content_margin(side, pad)
	return box
