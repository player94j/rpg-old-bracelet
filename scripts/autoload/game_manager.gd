extends Node
## GameManager - Central game state singleton
## Manages player stats, game state, NG+ mode, and global signals

# Signals
signal player_died
signal player_leveled_up(new_level: int)
signal xp_gained(amount: int)
signal gold_changed(new_amount: int)
signal ng_plus_started(cycle: int)
signal game_state_changed(new_state: String)
signal region_entered(region_name: String)
signal enemy_killed(enemy_data: Dictionary)
signal boss_defeated(boss_id: String)
signal item_acquired(item: Dictionary)

# Game states
enum GameState { MENU, PLAYING, PAUSED, DIALOGUE, INVENTORY, DEAD, LOADING, CUTSCENE }
var current_state: GameState = GameState.MENU

# New Game+ tracking
var ng_plus_cycle: int = 0
var ng_plus_scaling: float = 1.0
var defeated_bosses: Array[String] = []

# Player core stats
var player_stats: Dictionary = {
	"name": "John the Baptist",
	"level": 1,
	"xp": 0,
	"xp_to_next": 100,
	"gold": 50,
	"max_hp": 100,
	"hp": 100,
	"max_stamina": 100,
	"stamina": 100,
	"max_mana": 80,
	"mana": 80,
	"strength": 10,
	"dexterity": 10,
	"intelligence": 10,
	"vitality": 10,
	"endurance": 10,
	"faith": 10,
	"skill_points": 0,
	"total_kills": 0,
	"play_time": 0.0,
}

# Equipment slots
var equipped: Dictionary = {
	"weapon": null,
	"armor": null,
	"accessory": null,
	"spell_1": null,
	"spell_2": null,
	"spell_3": null,
}

# Currently selected spell/weapon indices
var current_spell_index: int = 0
var current_weapon_index: int = 0
var weapon_inventory: Array[Dictionary] = []
var spell_inventory: Array[Dictionary] = []

# Current region
var current_region: String = "ashen_wastes"
var discovered_regions: Array[String] = ["ashen_wastes"]
var discovered_secrets: Array[String] = []

# Tutorial flags
var tutorials_shown: Dictionary = {}

# Inventory
var inventory: Array[Dictionary] = []
var max_inventory_size: int = 40

# Player node reference
var player_node: Node2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_starting_gear()

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		player_stats.play_time += delta

func _init_starting_gear() -> void:
	# Starting weapon - Rusty Sword
	var starter_sword = {
		"id": "rusty_sword",
		"name": "Rusty Sword",
		"type": "weapon",
		"subtype": "sword",
		"damage": 12,
		"speed": 1.0,
		"description": "A worn blade, but still deadly.",
		"rarity": "common",
		"level_req": 1,
		"value": 10,
	}
	weapon_inventory.append(starter_sword)
	equipped.weapon = starter_sword
	current_weapon_index = 0
	
	# Starting spell - Holy Spark
	var starter_spell = {
		"id": "holy_spark",
		"name": "Holy Spark",
		"type": "spell",
		"subtype": "projectile",
		"damage": 15,
		"mana_cost": 12,
		"cooldown": 0.8,
		"description": "A spark of divine light that burns the unholy.",
		"rarity": "common",
		"level_req": 1,
	}
	spell_inventory.append(starter_spell)
	equipped.spell_1 = starter_spell
	current_spell_index = 0
	
	# Starting consumables
	add_item({"id": "health_potion", "name": "Health Potion", "type": "consumable", "subtype": "heal", "value": 40, "description": "Restores 40 HP.", "stack": 3, "max_stack": 10, "sell_value": 15})
	add_item({"id": "mana_potion", "name": "Mana Potion", "type": "consumable", "subtype": "mana", "value": 30, "description": "Restores 30 Mana.", "stack": 2, "max_stack": 10, "sell_value": 15})

func set_state(new_state: GameState) -> void:
	var old_state = current_state
	current_state = new_state
	match new_state:
		GameState.PAUSED, GameState.INVENTORY, GameState.DIALOGUE:
			get_tree().paused = true
		GameState.PLAYING:
			get_tree().paused = false
		GameState.DEAD:
			get_tree().paused = false
	game_state_changed.emit(GameState.keys()[new_state])

func add_xp(amount: int) -> void:
	var scaled = int(amount * (1.0 + ng_plus_cycle * 0.15))
	player_stats.xp += scaled
	xp_gained.emit(scaled)
	while player_stats.xp >= player_stats.xp_to_next:
		_level_up()

func _level_up() -> void:
	player_stats.xp -= player_stats.xp_to_next
	player_stats.level += 1
	player_stats.xp_to_next = int(100 * pow(1.15, player_stats.level - 1))
	player_stats.skill_points += 2
	# Stat increases on level
	player_stats.max_hp += 5
	player_stats.hp = player_stats.max_hp
	player_stats.max_stamina += 3
	player_stats.stamina = player_stats.max_stamina
	player_stats.max_mana += 3
	player_stats.mana = player_stats.max_mana
	player_leveled_up.emit(player_stats.level)

func add_gold(amount: int) -> void:
	player_stats.gold += amount
	gold_changed.emit(player_stats.gold)

func spend_gold(amount: int) -> bool:
	if player_stats.gold >= amount:
		player_stats.gold -= amount
		gold_changed.emit(player_stats.gold)
		return true
	return false

func add_item(item: Dictionary) -> bool:
	# Try to stack consumables
	if item.has("stack"):
		for inv_item in inventory:
			if inv_item.id == item.id and inv_item.has("stack"):
				var space = inv_item.max_stack - inv_item.stack
				if space > 0:
					var to_add = min(item.stack, space)
					inv_item.stack += to_add
					item.stack -= to_add
					if item.stack <= 0:
						item_acquired.emit(inv_item)
						return true
	if inventory.size() < max_inventory_size:
		inventory.append(item.duplicate(true))
		item_acquired.emit(item)
		return true
	return false

func remove_item(item_id: String, count: int = 1) -> bool:
	for i in range(inventory.size() - 1, -1, -1):
		if inventory[i].id == item_id:
			if inventory[i].has("stack"):
				inventory[i].stack -= count
				if inventory[i].stack <= 0:
					inventory.remove_at(i)
			else:
				inventory.remove_at(i)
			return true
	return false

func get_item_count(item_id: String) -> int:
	var total = 0
	for item in inventory:
		if item.id == item_id:
			total += item.get("stack", 1)
	return total

func equip_weapon(weapon: Dictionary) -> void:
	equipped.weapon = weapon
	if weapon not in weapon_inventory:
		weapon_inventory.append(weapon)

func equip_spell(spell: Dictionary, slot: int = -1) -> void:
	if spell not in spell_inventory:
		spell_inventory.append(spell)
	if slot < 0:
		slot = current_spell_index
	var slot_key = "spell_%d" % (slot + 1)
	if equipped.has(slot_key):
		equipped[slot_key] = spell

func get_current_spell() -> Dictionary:
	if spell_inventory.is_empty():
		return {}
	current_spell_index = clampi(current_spell_index, 0, spell_inventory.size() - 1)
	return spell_inventory[current_spell_index]

func get_current_weapon() -> Dictionary:
	if weapon_inventory.is_empty():
		return {}
	current_weapon_index = clampi(current_weapon_index, 0, weapon_inventory.size() - 1)
	return weapon_inventory[current_weapon_index]

func cycle_spell() -> Dictionary:
	if spell_inventory.size() <= 1:
		return get_current_spell()
	current_spell_index = (current_spell_index + 1) % spell_inventory.size()
	return spell_inventory[current_spell_index]

func cycle_weapon() -> Dictionary:
	if weapon_inventory.size() <= 1:
		return get_current_weapon()
	current_weapon_index = (current_weapon_index + 1) % weapon_inventory.size()
	equipped.weapon = weapon_inventory[current_weapon_index]
	return weapon_inventory[current_weapon_index]

func on_enemy_killed(enemy_data: Dictionary) -> void:
	player_stats.total_kills += 1
	add_xp(enemy_data.get("xp", 10))
	add_gold(enemy_data.get("gold", 5))
	enemy_killed.emit(enemy_data)

func on_boss_defeated(boss_id: String) -> void:
	if boss_id not in defeated_bosses:
		defeated_bosses.append(boss_id)
	boss_defeated.emit(boss_id)

func heal_player(amount: int) -> void:
	player_stats.hp = mini(player_stats.hp + amount, player_stats.max_hp)

func restore_mana(amount: int) -> void:
	player_stats.mana = mini(player_stats.mana + amount, player_stats.max_mana)

func use_consumable(item_id: String) -> bool:
	for item in inventory:
		if item.id == item_id and item.type == "consumable":
			match item.subtype:
				"heal":
					heal_player(item.value)
				"mana":
					restore_mana(item.value)
				"buff_str":
					player_stats.strength += item.value
					# Could add timed buff here
			remove_item(item_id)
			return true
	return false

func get_total_attack() -> float:
	var base = player_stats.strength * 1.5
	var weapon = equipped.weapon
	if weapon:
		base += weapon.get("damage", 0)
	base *= ng_plus_scaling_player()
	return base

func get_total_defense() -> float:
	var base = player_stats.vitality * 0.8
	var armor = equipped.armor
	if armor:
		base += armor.get("defense", 0)
	return base

func get_spell_power() -> float:
	var base = player_stats.intelligence * 2.0 + player_stats.faith * 1.0
	base *= ng_plus_scaling_player()
	return base

func ng_plus_scaling_player() -> float:
	return 1.0 + ng_plus_cycle * 0.1

func ng_plus_scaling_enemy() -> float:
	return 1.0 + ng_plus_cycle * 0.35

func start_new_game_plus() -> void:
	ng_plus_cycle += 1
	ng_plus_scaling = ng_plus_scaling_enemy()
	defeated_bosses.clear()
	discovered_secrets.clear()
	QuestManager.reset_quests_for_ng_plus()
	current_region = "ashen_wastes"
	discovered_regions = ["ashen_wastes"]
	player_stats.hp = player_stats.max_hp
	player_stats.mana = player_stats.max_mana
	player_stats.stamina = player_stats.max_stamina
	ng_plus_started.emit(ng_plus_cycle)

func start_new_game() -> void:
	ng_plus_cycle = 0
	ng_plus_scaling = 1.0
	defeated_bosses.clear()
	discovered_secrets.clear()
	discovered_regions = ["ashen_wastes"]
	current_region = "ashen_wastes"
	tutorials_shown.clear()
	inventory.clear()
	weapon_inventory.clear()
	spell_inventory.clear()
	equipped = {"weapon": null, "armor": null, "accessory": null, "spell_1": null, "spell_2": null, "spell_3": null}
	player_stats = {
		"name": "John the Baptist", "level": 1, "xp": 0, "xp_to_next": 100,
		"gold": 50, "max_hp": 100, "hp": 100, "max_stamina": 100, "stamina": 100,
		"max_mana": 80, "mana": 80, "strength": 10, "dexterity": 10,
		"intelligence": 10, "vitality": 10, "endurance": 10, "faith": 10,
		"skill_points": 0, "total_kills": 0, "play_time": 0.0,
	}
	SkillManager.reset_skills()
	QuestManager.reset_all_quests()
	_init_starting_gear()

func get_save_data() -> Dictionary:
	return {
		"player_stats": player_stats.duplicate(true),
		"equipped": _serialize_equipped(),
		"inventory": inventory.duplicate(true),
		"weapon_inventory": weapon_inventory.duplicate(true),
		"spell_inventory": spell_inventory.duplicate(true),
		"current_spell_index": current_spell_index,
		"current_weapon_index": current_weapon_index,
		"ng_plus_cycle": ng_plus_cycle,
		"defeated_bosses": defeated_bosses.duplicate(),
		"current_region": current_region,
		"discovered_regions": discovered_regions.duplicate(),
		"discovered_secrets": discovered_secrets.duplicate(),
		"tutorials_shown": tutorials_shown.duplicate(),
		"player_position": _get_player_pos(),
	}

func load_save_data(data: Dictionary) -> void:
	player_stats = data.get("player_stats", player_stats)
	inventory = data.get("inventory", [])
	weapon_inventory = data.get("weapon_inventory", [])
	spell_inventory = data.get("spell_inventory", [])
	current_spell_index = data.get("current_spell_index", 0)
	current_weapon_index = data.get("current_weapon_index", 0)
	ng_plus_cycle = data.get("ng_plus_cycle", 0)
	ng_plus_scaling = ng_plus_scaling_enemy()
	defeated_bosses.assign(data.get("defeated_bosses", []))
	current_region = data.get("current_region", "ashen_wastes")
	discovered_regions.assign(data.get("discovered_regions", ["ashen_wastes"]))
	discovered_secrets.assign(data.get("discovered_secrets", []))
	tutorials_shown = data.get("tutorials_shown", {})
	_deserialize_equipped(data.get("equipped", {}))

func _serialize_equipped() -> Dictionary:
	var result = {}
	for key in equipped:
		result[key] = equipped[key]
	return result

func _deserialize_equipped(data: Dictionary) -> void:
	for key in data:
		equipped[key] = data[key]

func _get_player_pos() -> Dictionary:
	if player_node and is_instance_valid(player_node):
		return {"x": player_node.global_position.x, "y": player_node.global_position.y}
	return {"x": 0, "y": 0}
