extends Node
## SaveManager - Handles save/load with multiple slots

const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 3

signal save_completed(slot: int)
signal load_completed(slot: int)
signal save_error(message: String)

func _ready() -> void:
	var dir = DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")

func save_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		save_error.emit("Invalid slot")
		return false
	
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"game_manager": GameManager.get_save_data(),
		"quest_manager": QuestManager.get_save_data(),
		"skill_manager": SkillManager.get_save_data(),
		"event_manager": EventManager.get_save_data(),
	}
	
	var path = SAVE_DIR + "slot_%d.sav" % slot
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		save_error.emit("Cannot open save file")
		return false
	
	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()
	
	save_completed.emit(slot)
	return true

func load_game(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SLOTS:
		save_error.emit("Invalid slot")
		return false
	
	var path = SAVE_DIR + "slot_%d.sav" % slot
	if not FileAccess.file_exists(path):
		save_error.emit("No save file in slot %d" % slot)
		return false
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		save_error.emit("Cannot read save file")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		save_error.emit("Corrupted save file")
		return false
	
	var data = json.data
	if not data is Dictionary:
		save_error.emit("Invalid save data")
		return false
	
	GameManager.load_save_data(data.get("game_manager", {}))
	QuestManager.load_save_data(data.get("quest_manager", {}))
	SkillManager.load_save_data(data.get("skill_manager", {}))
	EventManager.load_save_data(data.get("event_manager", {}))
	
	load_completed.emit(slot)
	return true

func has_save(slot: int) -> bool:
	var path = SAVE_DIR + "slot_%d.sav" % slot
	return FileAccess.file_exists(path)

func get_save_info(slot: int) -> Dictionary:
	if not has_save(slot):
		return {}
	var path = SAVE_DIR + "slot_%d.sav" % slot
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json_string = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}
	var data = json.data
	if not data is Dictionary:
		return {}
	var gm = data.get("game_manager", {})
	var ps = gm.get("player_stats", {})
	return {
		"slot": slot,
		"timestamp": data.get("timestamp", "Unknown"),
		"level": ps.get("level", 1),
		"play_time": ps.get("play_time", 0.0),
		"region": gm.get("current_region", "Unknown"),
		"ng_plus": gm.get("ng_plus_cycle", 0),
	}

func delete_save(slot: int) -> void:
	var path = SAVE_DIR + "slot_%d.sav" % slot
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
