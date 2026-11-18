extends Node

signal settings_changed

const TITLE := "res://title.tscn"
const MAP := "res://main.tscn"
const SLOTS := ["auto", "slot-1", "slot-2", "slot-3"]
const VERSION := 1
const DIGEST_BYTES := 32
const CONFIG := "user://settings.cfg"

var pending: Dictionary = {}
var volume := 1.0
var fullscreen := false
var glow := true


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG) == OK:
		volume = clampf(config.get_value("settings", "volume", 1.0), 0.0, 1.0)
		fullscreen = config.get_value("settings", "fullscreen", false)
		glow = config.get_value("settings", "glow", true)
	apply_settings()


func apply_settings() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master, is_zero_approx(volume))
	AudioServer.set_bus_volume_db(master, linear_to_db(maxf(volume, 0.001)))
	if DisplayServer.get_name() != "headless":
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	settings_changed.emit()


func save_settings() -> Error:
	apply_settings()
	var config := ConfigFile.new()
	config.set_value("settings", "volume", volume)
	config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("settings", "glow", glow)
	return config.save(CONFIG)


func slot_path(slot: int) -> String:
	return "user://settlement-%s.save" % SLOTS[slot]


func read_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() <= DIGEST_BYTES or file.get_length() > 2_000_000:
		return {}
	var digest := file.get_buffer(DIGEST_BYTES)
	var data := file.get_buffer(file.get_length() - DIGEST_BYTES)
	if digest != checksum(data):
		return {}
	var state: Variant = bytes_to_var(data)
	if not state is Dictionary or state.get("version") != VERSION:
		return {}
	if not state.get("summary") is Dictionary or not state.get("world") is Dictionary:
		return {}
	var world: Dictionary = state.world
	for key in ["day", "day_elapsed", "commands", "center_stage", "stock", "campaign", "tiles", "workers",
			"houses", "facilities", "jobs", "crews", "pickups", "site_stock"]:
		if not world.has(key):
			return {}
	return state


func checksum(data: PackedByteArray) -> PackedByteArray:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(data)
	return context.finish()


func read_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	var save := read_file(path)
	return read_file(path + ".bak") if save.is_empty() else save


func write_slot(slot: int, state: Dictionary, summary: Dictionary) -> Error:
	var path := slot_path(slot)
	var temporary := path + ".tmp"
	var backup := path + ".bak"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var timestamp := Time.get_unix_time_from_system()
	summary["timestamp"] = timestamp
	summary["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var data := var_to_bytes({"version": VERSION, "world": state, "summary": summary})
	file.store_buffer(checksum(data))
	file.store_buffer(data)
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK or read_file(temporary).is_empty():
		return ERR_CANT_CREATE
	if FileAccess.file_exists(path) and not read_file(path).is_empty():
		error = DirAccess.rename_absolute(path, backup)
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, path)


func latest_slot() -> int:
	var recent := -1
	var latest := -1.0
	for slot in SLOTS.size():
		var state := read_slot(slot)
		if not state.is_empty() and float(state.summary.get("timestamp", 0.0)) > latest:
			latest = state.summary.timestamp
			recent = slot
	return recent


func start_new() -> void:
	open_map({})


func load_slot(slot: int) -> Error:
	if slot < 0 or slot >= SLOTS.size():
		return ERR_DOES_NOT_EXIST
	var state := read_slot(slot)
	if state.is_empty():
		return ERR_FILE_CORRUPT
	return open_map(state.world)


func open_map(world: Dictionary) -> Error:
	var error := get_tree().change_scene_to_file(MAP)
	if error == OK:
		pending = world
	return error


func open_title() -> Error:
	return get_tree().change_scene_to_file(TITLE)


func take_pending() -> Dictionary:
	var state := pending
	pending = {}
	return state
