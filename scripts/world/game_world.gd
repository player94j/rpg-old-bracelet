extends Node2D
## GameWorld - Main game scene, manages regions, spawning, and events
## Shows tutorial sequence before enemies activate

@onready var player: CharacterBody2D = $Player
@onready var ui: CanvasLayer = $GameUI
@onready var tilemap: Node2D = $WorldMap

var event_spawn_nodes: Array[Node2D] = []
var enemies_active: bool = false

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.PLAYING)
	GameManager.player_node = player
	
	# Connect event system
	EventManager.event_triggered.connect(_on_event_triggered)
	
	# Start first quest if new game
	if QuestManager.player_quests.is_empty():
		QuestManager.start_quest("mq_01_awakening")
	
	# Load player position from save
	var pos = GameManager._get_player_pos()
	if pos.x != 0 or pos.y != 0:
		player.global_position = Vector2(pos.x, pos.y)
	
	# Play music for current region
	AudioManager.play_music(GameManager.current_region)
	
	# Start tutorial intro sequence
	TutorialManager.intro_tutorial_complete.connect(_on_intro_complete)
	TutorialManager.start_intro_sequence()

func _on_intro_complete() -> void:
	enemies_active = true

func _on_event_triggered(event: Dictionary) -> void:
	# Don't spawn events during tutorial
	if not enemies_active:
		return
	
	# Spawn event near player
	if not player or not is_instance_valid(player):
		return
	
	var spawn_offset = Vector2(randf_range(-300, 300), randf_range(-300, 300))
	if spawn_offset.length() < 150:
		spawn_offset = spawn_offset.normalized() * 150
	var spawn_pos = player.global_position + spawn_offset
	
	match event.get("type", ""):
		"ambush", "elite":
			_spawn_combat_event(event, spawn_pos)
		"merchant":
			_spawn_merchant_event(event, spawn_pos)
		"treasure":
			_spawn_treasure_event(event, spawn_pos)
		"rescue":
			_spawn_combat_event(event, spawn_pos)

func _spawn_combat_event(event: Dictionary, pos: Vector2) -> void:
	var enemies = event.get("enemies", [])
	var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
	
	for enemy_id in enemies:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		var data = _get_enemy_data(enemy_id)
		enemy.setup_from_data(data)
		add_child(enemy)
	
	EventManager.complete_event(event.id)

func _spawn_merchant_event(event: Dictionary, pos: Vector2) -> void:
	var npc_scene = preload("res://scenes/npcs/npc.tscn")
	var merchant = npc_scene.instantiate()
	merchant.global_position = pos
	merchant.npc_id = event.get("npc", "event_merchant")
	merchant.npc_name = "Wandering Merchant"
	merchant.is_merchant = true
	merchant.dialogue_lines = ["Greetings, traveler! Care to trade?"]
	merchant.shop_items = [
		LootTable.get_item_by_id("health_potion"),
		LootTable.get_item_by_id("mana_potion"),
		LootTable.get_item_by_id("health_potion_large"),
	]
	for item in merchant.shop_items:
		if not item.is_empty():
			item["price"] = item.get("value", 30)
	add_child(merchant)
	EventManager.complete_event(event.id)

func _spawn_treasure_event(event: Dictionary, pos: Vector2) -> void:
	var tier = event.get("loot_tier", "common")
	var loot = LootTable.generate_loot(tier, GameManager.player_stats.level)
	var pickup_scene = preload("res://scenes/world/loot_pickup.tscn")
	for item in loot:
		if item.type == "gold":
			GameManager.add_gold(item.value)
		else:
			var pickup = pickup_scene.instantiate()
			pickup.global_position = pos + Vector2(randf_range(-15, 15), randf_range(-15, 15))
			pickup.item_data = item
			add_child(pickup)
	EventManager.complete_event(event.id)

func _get_enemy_data(enemy_id: String) -> Dictionary:
	var ng = GameManager.ng_plus_scaling_enemy()
	match enemy_id:
		"hollow_soldier":
			return {"id": "hollow_soldier", "name": "Hollow Soldier", "max_hp": 40 * ng, "damage": 8 * ng, "move_speed": 80, "chase_speed": 120, "xp_reward": 20, "gold_reward": 8, "loot_tier": "common", "detect_range": 180, "attack_range": 28}
		"hollow_archer":
			return {"id": "hollow_archer", "name": "Hollow Archer", "max_hp": 30 * ng, "damage": 12 * ng, "move_speed": 60, "chase_speed": 80, "xp_reward": 25, "gold_reward": 10, "loot_tier": "common", "detect_range": 250, "attack_range": 35}
		"mire_beast":
			return {"id": "mire_beast", "name": "Mire Beast", "max_hp": 70 * ng, "damage": 14 * ng, "move_speed": 90, "chase_speed": 130, "xp_reward": 40, "gold_reward": 15, "loot_tier": "uncommon", "detect_range": 200, "attack_range": 30}
		"mire_spitter":
			return {"id": "mire_spitter", "name": "Mire Spitter", "max_hp": 50 * ng, "damage": 18 * ng, "move_speed": 60, "chase_speed": 70, "xp_reward": 45, "gold_reward": 18, "loot_tier": "uncommon", "detect_range": 220, "attack_range": 40}
		"frost_wolf":
			return {"id": "frost_wolf", "name": "Frost Wolf", "max_hp": 60 * ng, "damage": 16 * ng, "move_speed": 130, "chase_speed": 180, "xp_reward": 50, "gold_reward": 20, "loot_tier": "uncommon", "detect_range": 250, "attack_range": 25}
		"shadow_knight":
			return {"id": "shadow_knight", "name": "Shadow Knight", "max_hp": 120 * ng, "damage": 25 * ng, "move_speed": 90, "chase_speed": 140, "xp_reward": 80, "gold_reward": 40, "loot_tier": "rare", "detect_range": 200, "attack_range": 35}
		"shadow_mage":
			return {"id": "shadow_mage", "name": "Shadow Mage", "max_hp": 80 * ng, "damage": 30 * ng, "move_speed": 70, "chase_speed": 90, "xp_reward": 90, "gold_reward": 45, "loot_tier": "rare", "detect_range": 250, "attack_range": 45}
		"bandit":
			return {"id": "bandit", "name": "Bandit", "max_hp": 45 * ng, "damage": 10 * ng, "move_speed": 100, "chase_speed": 140, "xp_reward": 20, "gold_reward": 15, "loot_tier": "common", "detect_range": 180, "attack_range": 28}
		"elite_revenant":
			return {"id": "elite_revenant", "name": "Revenant", "max_hp": 150 * ng, "damage": 20 * ng, "move_speed": 100, "chase_speed": 160, "xp_reward": 100, "gold_reward": 60, "loot_tier": "rare", "detect_range": 250, "attack_range": 35, "is_elite": true}
		"elite_blood_stalker":
			return {"id": "elite_blood_stalker", "name": "Blood Stalker", "max_hp": 200 * ng, "damage": 25 * ng, "move_speed": 120, "chase_speed": 180, "xp_reward": 150, "gold_reward": 80, "loot_tier": "rare", "detect_range": 300, "attack_range": 35, "is_elite": true}
		"elite_ice_wraith":
			return {"id": "elite_ice_wraith", "name": "Ice Wraith", "max_hp": 180 * ng, "damage": 28 * ng, "move_speed": 90, "chase_speed": 150, "xp_reward": 160, "gold_reward": 90, "loot_tier": "rare", "detect_range": 280, "attack_range": 40, "is_elite": true}
		"elite_abyssal_champion":
			return {"id": "elite_abyssal_champion", "name": "Abyssal Champion", "max_hp": 300 * ng, "damage": 35 * ng, "move_speed": 100, "chase_speed": 160, "xp_reward": 250, "gold_reward": 120, "loot_tier": "epic", "detect_range": 280, "attack_range": 40, "is_elite": true}
		_:
			return {"id": enemy_id, "name": enemy_id, "max_hp": 40 * ng, "damage": 8 * ng, "xp_reward": 15, "gold_reward": 5}
