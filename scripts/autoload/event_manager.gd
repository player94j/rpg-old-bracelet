extends Node
## EventManager - Procedural / dynamic event system
## Spawns random encounters, roaming elites, merchants, ambushes

signal event_triggered(event: Dictionary)
signal event_completed(event_id: String)

var event_timer: float = 0.0
var event_interval_min: float = 30.0
var event_interval_max: float = 60.0
var next_event_time: float = 45.0  # First event delayed to let player explore
var active_events: Array[Dictionary] = []
var completed_event_ids: Array[String] = []
var event_counter: int = 0

# Event templates per region
var event_templates: Dictionary = {
	"ashen_wastes": [
		{"type": "ambush", "name": "Hollow Ambush", "enemies": ["hollow_soldier", "hollow_soldier", "hollow_archer"], "min_level": 1},
		{"type": "elite", "name": "Roaming Revenant", "enemies": ["elite_revenant"], "min_level": 3},
		{"type": "merchant", "name": "Wandering Peddler", "npc": "event_merchant", "min_level": 1},
		{"type": "treasure", "name": "Hidden Cache", "loot_tier": "common", "min_level": 1},
		{"type": "rescue", "name": "Prisoner Rescue", "enemies": ["hollow_soldier", "hollow_soldier"], "reward_npc": "freed_prisoner", "min_level": 2},
	],
	"crimson_mire": [
		{"type": "ambush", "name": "Mire Beast Pack", "enemies": ["mire_beast", "mire_beast", "mire_beast"], "min_level": 5},
		{"type": "elite", "name": "Blood Stalker Hunt", "enemies": ["elite_blood_stalker"], "min_level": 7},
		{"type": "merchant", "name": "Swamp Trader", "npc": "event_merchant_swamp", "min_level": 5},
		{"type": "treasure", "name": "Sunken Chest", "loot_tier": "uncommon", "min_level": 5},
		{"type": "ambush", "name": "Poison Trap", "enemies": ["mire_spitter", "mire_spitter", "mire_beast"], "min_level": 6},
	],
	"frozen_peaks": [
		{"type": "ambush", "name": "Frost Wolf Pack", "enemies": ["frost_wolf", "frost_wolf", "frost_wolf", "frost_wolf"], "min_level": 10},
		{"type": "elite", "name": "Ice Wraith Encounter", "enemies": ["elite_ice_wraith"], "min_level": 12},
		{"type": "merchant", "name": "Mountain Hermit", "npc": "event_merchant_mountain", "min_level": 10},
		{"type": "treasure", "name": "Frozen Relic", "loot_tier": "rare", "min_level": 10},
	],
	"shadow_citadel": [
		{"type": "ambush", "name": "Shadow Legion", "enemies": ["shadow_knight", "shadow_knight", "shadow_mage"], "min_level": 15},
		{"type": "elite", "name": "Abyssal Champion", "enemies": ["elite_abyssal_champion"], "min_level": 17},
		{"type": "treasure", "name": "Dark Reliquary", "loot_tier": "epic", "min_level": 15},
	],
}

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	event_timer += delta
	if event_timer >= next_event_time:
		event_timer = 0.0
		next_event_time = randf_range(event_interval_min, event_interval_max)
		_try_trigger_event()

func _try_trigger_event() -> void:
	var region = GameManager.current_region
	if not event_templates.has(region):
		return
	var templates = event_templates[region]
	var valid = templates.filter(func(e): return e.min_level <= GameManager.player_stats.level)
	if valid.is_empty():
		return
	var template = valid[randi() % valid.size()]
	var event = template.duplicate(true)
	event_counter += 1
	event["id"] = "event_%d" % event_counter
	event["region"] = region
	event["ng_scale"] = GameManager.ng_plus_scaling_enemy()
	active_events.append(event)
	event_triggered.emit(event)

func complete_event(event_id: String) -> void:
	for i in range(active_events.size() - 1, -1, -1):
		if active_events[i].id == event_id:
			completed_event_ids.append(event_id)
			active_events.remove_at(i)
			event_completed.emit(event_id)
			break

func get_save_data() -> Dictionary:
	return {
		"completed_event_ids": completed_event_ids.duplicate(),
		"event_counter": event_counter,
	}

func load_save_data(data: Dictionary) -> void:
	completed_event_ids.assign(data.get("completed_event_ids", []))
	event_counter = data.get("event_counter", 0)
