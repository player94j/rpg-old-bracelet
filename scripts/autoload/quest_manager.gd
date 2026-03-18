extends Node
## QuestManager - Tracks main story, side quests, and quest objectives

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective_id: String)
signal quest_completed(quest_id: String)
signal quest_failed(quest_id: String)

# Quest status
enum QuestStatus { AVAILABLE, ACTIVE, COMPLETED, FAILED }

# All quests in the game
var quest_database: Dictionary = {}
# Player's active/completed quests
var player_quests: Dictionary = {}

func _ready() -> void:
	_init_quests()

func _init_quests() -> void:
	# === MAIN QUESTLINE ===
	_add_quest({
		"id": "mq_01_awakening",
		"name": "The Awakening",
		"type": "main",
		"description": "You awaken in the Ashen Wastes with no memory. Find the Old Hermit for guidance.",
		"objectives": [
			{"id": "find_hermit", "description": "Find the Old Hermit in the Ashen Wastes", "type": "interact", "target": "npc_hermit", "count": 1, "current": 0},
		],
		"rewards": {"xp": 50, "gold": 25},
		"next_quest": "mq_02_first_trial",
		"region": "ashen_wastes",
	})
	_add_quest({
		"id": "mq_02_first_trial",
		"name": "The First Trial",
		"type": "main",
		"description": "The Hermit speaks of a darkness spreading. Defeat the Hollow Knight in the Ashen Ruins.",
		"objectives": [
			{"id": "kill_hollows", "description": "Slay 5 Hollow Soldiers", "type": "kill", "target": "hollow_soldier", "count": 5, "current": 0},
			{"id": "defeat_hollow_knight", "description": "Defeat the Hollow Knight", "type": "kill", "target": "boss_hollow_knight", "count": 1, "current": 0},
		],
		"rewards": {"xp": 200, "gold": 100, "item": "iron_sword"},
		"next_quest": "mq_03_crimson_path",
		"region": "ashen_wastes",
	})
	_add_quest({
		"id": "mq_03_crimson_path",
		"name": "The Crimson Path",
		"type": "main",
		"description": "Travel to the Crimson Mire. The source of corruption festers there.",
		"objectives": [
			{"id": "reach_mire", "description": "Enter the Crimson Mire", "type": "region", "target": "crimson_mire", "count": 1, "current": 0},
			{"id": "find_witch", "description": "Find the Swamp Witch", "type": "interact", "target": "npc_witch", "count": 1, "current": 0},
		],
		"rewards": {"xp": 150, "gold": 75},
		"next_quest": "mq_04_swamp_terror",
		"region": "crimson_mire",
	})
	_add_quest({
		"id": "mq_04_swamp_terror",
		"name": "Terror of the Mire",
		"type": "main",
		"description": "The Swamp Witch reveals a great beast guards the corruption's heart. Slay the Bog Hydra.",
		"objectives": [
			{"id": "collect_venom", "description": "Collect 3 Venom Glands from Mire Beasts", "type": "collect", "target": "venom_gland", "count": 3, "current": 0},
			{"id": "defeat_hydra", "description": "Defeat the Bog Hydra", "type": "kill", "target": "boss_bog_hydra", "count": 1, "current": 0},
		],
		"rewards": {"xp": 400, "gold": 200, "item": "hydra_fang_blade"},
		"next_quest": "mq_05_frozen_ascent",
		"region": "crimson_mire",
	})
	_add_quest({
		"id": "mq_05_frozen_ascent",
		"name": "The Frozen Ascent",
		"type": "main",
		"description": "The corruption leads to the Frozen Peaks. Climb to the summit and face the Storm Titan.",
		"objectives": [
			{"id": "reach_peaks", "description": "Enter the Frozen Peaks", "type": "region", "target": "frozen_peaks", "count": 1, "current": 0},
			{"id": "defeat_titan", "description": "Defeat the Storm Titan", "type": "kill", "target": "boss_storm_titan", "count": 1, "current": 0},
		],
		"rewards": {"xp": 600, "gold": 350, "item": "titan_armor"},
		"next_quest": "mq_06_shadow_throne",
		"region": "frozen_peaks",
	})
	_add_quest({
		"id": "mq_06_shadow_throne",
		"name": "The Shadow Throne",
		"type": "main",
		"description": "Enter the Shadow Citadel and confront the Dark Sovereign, source of all corruption.",
		"objectives": [
			{"id": "reach_citadel", "description": "Enter the Shadow Citadel", "type": "region", "target": "shadow_citadel", "count": 1, "current": 0},
			{"id": "defeat_sovereign", "description": "Defeat the Dark Sovereign", "type": "kill", "target": "boss_dark_sovereign", "count": 1, "current": 0},
		],
		"rewards": {"xp": 1000, "gold": 500},
		"next_quest": "",
		"region": "shadow_citadel",
		"is_final": true,
	})
	
	# === SIDE QUESTS ===
	_add_quest({
		"id": "sq_lost_pendant",
		"name": "The Lost Pendant",
		"type": "side",
		"description": "A ghost in the Ashen Wastes begs you to find her lost pendant deep in the ruins.",
		"objectives": [
			{"id": "find_pendant", "description": "Find the Silver Pendant in the ruins", "type": "collect", "target": "silver_pendant", "count": 1, "current": 0},
			{"id": "return_pendant", "description": "Return the pendant to the Ghost", "type": "interact", "target": "npc_ghost", "count": 1, "current": 0},
		],
		"rewards": {"xp": 80, "gold": 50, "item": "ghost_ring"},
		"region": "ashen_wastes",
	})
	_add_quest({
		"id": "sq_herb_gather",
		"name": "Herbal Remedy",
		"type": "side",
		"description": "The Hermit needs rare herbs to brew medicine for the afflicted.",
		"objectives": [
			{"id": "gather_herbs", "description": "Collect 5 Moonpetal Herbs", "type": "collect", "target": "moonpetal_herb", "count": 5, "current": 0},
		],
		"rewards": {"xp": 60, "gold": 30, "item": "health_potion_large"},
		"region": "ashen_wastes",
	})
	_add_quest({
		"id": "sq_bounty_hunter",
		"name": "Bounty: The Blood Stalker",
		"type": "side",
		"description": "A bounty has been placed on a dangerous elite creature roaming the Crimson Mire.",
		"objectives": [
			{"id": "kill_stalker", "description": "Slay the Blood Stalker", "type": "kill", "target": "elite_blood_stalker", "count": 1, "current": 0},
		],
		"rewards": {"xp": 250, "gold": 200},
		"region": "crimson_mire",
	})
	_add_quest({
		"id": "sq_frozen_relic",
		"name": "Relic of the Ancients",
		"type": "side",
		"description": "Ancient ruins in the Frozen Peaks hold a powerful relic. Retrieve it before the darkness claims it.",
		"objectives": [
			{"id": "find_relic", "description": "Find the Ancient Relic", "type": "collect", "target": "ancient_relic", "count": 1, "current": 0},
		],
		"rewards": {"xp": 300, "gold": 150, "item": "ancient_staff"},
		"region": "frozen_peaks",
	})
	_add_quest({
		"id": "sq_merchant_escort",
		"name": "Merchant's Plea",
		"type": "side",
		"description": "A traveling merchant needs protection from bandits. Escort him safely.",
		"objectives": [
			{"id": "kill_bandits", "description": "Defeat 3 Bandit Ambushers", "type": "kill", "target": "bandit", "count": 3, "current": 0},
			{"id": "talk_merchant", "description": "Report back to the Merchant", "type": "interact", "target": "npc_merchant_quest", "count": 1, "current": 0},
		],
		"rewards": {"xp": 120, "gold": 150},
		"region": "ashen_wastes",
	})

func _add_quest(data: Dictionary) -> void:
	quest_database[data.id] = data

func start_quest(quest_id: String) -> bool:
	if not quest_database.has(quest_id):
		return false
	if player_quests.has(quest_id):
		return false
	var quest = quest_database[quest_id].duplicate(true)
	quest["status"] = QuestStatus.ACTIVE
	player_quests[quest_id] = quest
	quest_started.emit(quest_id)
	return true

func update_objective(quest_id: String, objective_id: String, amount: int = 1) -> void:
	if not player_quests.has(quest_id):
		return
	var quest = player_quests[quest_id]
	if quest.status != QuestStatus.ACTIVE:
		return
	for obj in quest.objectives:
		if obj.id == objective_id:
			obj.current = mini(obj.current + amount, obj.count)
			quest_updated.emit(quest_id, objective_id)
			_check_quest_completion(quest_id)
			break

func notify_kill(target_id: String) -> void:
	for quest_id in player_quests:
		var quest = player_quests[quest_id]
		if quest.status != QuestStatus.ACTIVE:
			continue
		for obj in quest.objectives:
			if obj.type == "kill" and obj.target == target_id and obj.current < obj.count:
				obj.current += 1
				quest_updated.emit(quest_id, obj.id)
				_check_quest_completion(quest_id)

func notify_collect(item_id: String) -> void:
	for quest_id in player_quests:
		var quest = player_quests[quest_id]
		if quest.status != QuestStatus.ACTIVE:
			continue
		for obj in quest.objectives:
			if obj.type == "collect" and obj.target == item_id and obj.current < obj.count:
				obj.current += 1
				quest_updated.emit(quest_id, obj.id)
				_check_quest_completion(quest_id)

func notify_interact(npc_id: String) -> void:
	for quest_id in player_quests:
		var quest = player_quests[quest_id]
		if quest.status != QuestStatus.ACTIVE:
			continue
		for obj in quest.objectives:
			if obj.type == "interact" and obj.target == npc_id and obj.current < obj.count:
				obj.current += 1
				quest_updated.emit(quest_id, obj.id)
				_check_quest_completion(quest_id)

func notify_region_entered(region_id: String) -> void:
	for quest_id in player_quests:
		var quest = player_quests[quest_id]
		if quest.status != QuestStatus.ACTIVE:
			continue
		for obj in quest.objectives:
			if obj.type == "region" and obj.target == region_id and obj.current < obj.count:
				obj.current += 1
				quest_updated.emit(quest_id, obj.id)
				_check_quest_completion(quest_id)

func _check_quest_completion(quest_id: String) -> void:
	var quest = player_quests[quest_id]
	var all_done = true
	for obj in quest.objectives:
		if obj.current < obj.count:
			all_done = false
			break
	if all_done:
		complete_quest(quest_id)

func complete_quest(quest_id: String) -> void:
	if not player_quests.has(quest_id):
		return
	var quest = player_quests[quest_id]
	quest.status = QuestStatus.COMPLETED
	# Grant rewards
	var rewards = quest.get("rewards", {})
	if rewards.has("xp"):
		GameManager.add_xp(rewards.xp)
	if rewards.has("gold"):
		GameManager.add_gold(rewards.gold)
	if rewards.has("item"):
		var item = LootTable.get_item_by_id(rewards.item)
		if not item.is_empty():
			GameManager.add_item(item)
	quest_completed.emit(quest_id)
	# Auto-start next quest in main questline
	if quest.has("next_quest") and quest.next_quest != "":
		start_quest(quest.next_quest)
	# Check for game ending
	if quest.get("is_final", false):
		_handle_game_ending()

func _handle_game_ending() -> void:
	# Trigger NG+ option
	await get_tree().create_timer(2.0).timeout
	GameManager.set_state(GameManager.GameState.CUTSCENE)

func get_active_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in player_quests:
		if player_quests[quest_id].status == QuestStatus.ACTIVE:
			result.append(player_quests[quest_id])
	return result

func get_completed_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in player_quests:
		if player_quests[quest_id].status == QuestStatus.COMPLETED:
			result.append(player_quests[quest_id])
	return result

func is_quest_active(quest_id: String) -> bool:
	return player_quests.has(quest_id) and player_quests[quest_id].status == QuestStatus.ACTIVE

func is_quest_completed(quest_id: String) -> bool:
	return player_quests.has(quest_id) and player_quests[quest_id].status == QuestStatus.COMPLETED

func get_save_data() -> Dictionary:
	return {"player_quests": player_quests.duplicate(true)}

func load_save_data(data: Dictionary) -> void:
	player_quests = data.get("player_quests", {})

func reset_quests_for_ng_plus() -> void:
	# Keep completed quest record but reset active ones for NG+
	for quest_id in player_quests:
		player_quests[quest_id].status = QuestStatus.AVAILABLE
		for obj in player_quests[quest_id].objectives:
			obj.current = 0
	player_quests.clear()

func reset_all_quests() -> void:
	player_quests.clear()
