extends Node
## LootTable - Item database and loot generation

var item_database: Dictionary = {}

func _ready() -> void:
	_init_items()

func _init_items() -> void:
	# === WEAPONS ===
	_add("rusty_sword", {"id": "rusty_sword", "name": "Rusty Sword", "type": "weapon", "subtype": "sword", "damage": 12, "speed": 1.0, "description": "A worn blade, still deadly.", "rarity": "common", "level_req": 1, "value": 10})
	_add("iron_sword", {"id": "iron_sword", "name": "Iron Sword", "type": "weapon", "subtype": "sword", "damage": 20, "speed": 1.0, "description": "A solid iron blade.", "rarity": "uncommon", "level_req": 3, "value": 50})
	_add("battle_axe", {"id": "battle_axe", "name": "Battle Axe", "type": "weapon", "subtype": "axe", "damage": 28, "speed": 0.7, "description": "Slow but devastating.", "rarity": "uncommon", "level_req": 5, "value": 80})
	_add("twin_daggers", {"id": "twin_daggers", "name": "Twin Daggers", "type": "weapon", "subtype": "dagger", "damage": 10, "speed": 1.8, "description": "Fast strikes, death by a thousand cuts.", "rarity": "uncommon", "level_req": 4, "value": 60})
	_add("war_hammer", {"id": "war_hammer", "name": "War Hammer", "type": "weapon", "subtype": "hammer", "damage": 35, "speed": 0.5, "description": "Crushes armor and bones alike.", "rarity": "rare", "level_req": 8, "value": 150})
	_add("hydra_fang_blade", {"id": "hydra_fang_blade", "name": "Hydra Fang Blade", "type": "weapon", "subtype": "sword", "damage": 32, "speed": 0.9, "description": "Forged from the fang of the Bog Hydra. Drips with venom.", "rarity": "rare", "level_req": 8, "value": 200})
	_add("frost_cleaver", {"id": "frost_cleaver", "name": "Frost Cleaver", "type": "weapon", "subtype": "axe", "damage": 38, "speed": 0.65, "description": "Coated in eternal frost.", "rarity": "rare", "level_req": 12, "value": 250})
	_add("shadow_katana", {"id": "shadow_katana", "name": "Shadow Katana", "type": "weapon", "subtype": "sword", "damage": 42, "speed": 1.2, "description": "A blade forged in the abyss.", "rarity": "epic", "level_req": 15, "value": 400})
	_add("divine_greatsword", {"id": "divine_greatsword", "name": "Divine Greatsword", "type": "weapon", "subtype": "greatsword", "damage": 55, "speed": 0.4, "description": "A holy weapon of immense power.", "rarity": "legendary", "level_req": 18, "value": 800})
	_add("scythe_of_endings", {"id": "scythe_of_endings", "name": "Scythe of Endings", "type": "weapon", "subtype": "scythe", "damage": 48, "speed": 0.8, "description": "Reaps souls from the living.", "rarity": "legendary", "level_req": 20, "value": 1000})
	
	# === ARMOR ===
	_add("leather_armor", {"id": "leather_armor", "name": "Leather Armor", "type": "armor", "defense": 5, "description": "Basic protection.", "rarity": "common", "level_req": 1, "value": 20})
	_add("chainmail", {"id": "chainmail", "name": "Chainmail", "type": "armor", "defense": 12, "description": "Linked rings of iron.", "rarity": "uncommon", "level_req": 5, "value": 80})
	_add("plate_armor", {"id": "plate_armor", "name": "Plate Armor", "type": "armor", "defense": 22, "description": "Heavy but effective.", "rarity": "rare", "level_req": 10, "value": 200})
	_add("titan_armor", {"id": "titan_armor", "name": "Titan Armor", "type": "armor", "defense": 30, "description": "Forged from Titan scales.", "rarity": "epic", "level_req": 14, "value": 400})
	_add("sovereign_mantle", {"id": "sovereign_mantle", "name": "Sovereign's Mantle", "type": "armor", "defense": 40, "description": "Worn by the Dark Sovereign.", "rarity": "legendary", "level_req": 18, "value": 800})
	
	# === ACCESSORIES ===
	_add("ghost_ring", {"id": "ghost_ring", "name": "Ghost Ring", "type": "accessory", "bonus": {"vitality": 3, "intelligence": 2}, "description": "A spectral ring. Cold to the touch.", "rarity": "uncommon", "level_req": 2, "value": 60})
	_add("ring_of_vigor", {"id": "ring_of_vigor", "name": "Ring of Vigor", "type": "accessory", "bonus": {"max_hp": 25}, "description": "Pulses with life force.", "rarity": "uncommon", "level_req": 5, "value": 80})
	_add("mana_pendant", {"id": "mana_pendant", "name": "Mana Pendant", "type": "accessory", "bonus": {"max_mana": 30}, "description": "Hums with arcane energy.", "rarity": "rare", "level_req": 8, "value": 150})
	
	# === CONSUMABLES ===
	_add("health_potion", {"id": "health_potion", "name": "Health Potion", "type": "consumable", "subtype": "heal", "value": 40, "description": "Restores 40 HP.", "stack": 1, "max_stack": 10, "sell_value": 15, "rarity": "common"})
	_add("health_potion_large", {"id": "health_potion_large", "name": "Large Health Potion", "type": "consumable", "subtype": "heal", "value": 80, "description": "Restores 80 HP.", "stack": 1, "max_stack": 10, "sell_value": 30, "rarity": "uncommon"})
	_add("mana_potion", {"id": "mana_potion", "name": "Mana Potion", "type": "consumable", "subtype": "mana", "value": 30, "description": "Restores 30 Mana.", "stack": 1, "max_stack": 10, "sell_value": 15, "rarity": "common"})
	_add("mana_potion_large", {"id": "mana_potion_large", "name": "Large Mana Potion", "type": "consumable", "subtype": "mana", "value": 60, "description": "Restores 60 Mana.", "stack": 1, "max_stack": 10, "sell_value": 30, "rarity": "uncommon"})
	
	# === QUEST ITEMS ===
	_add("silver_pendant", {"id": "silver_pendant", "name": "Silver Pendant", "type": "quest_item", "description": "A beautiful silver pendant. A ghost is looking for this.", "rarity": "quest", "value": 0})
	_add("moonpetal_herb", {"id": "moonpetal_herb", "name": "Moonpetal Herb", "type": "quest_item", "description": "A luminescent herb with healing properties.", "rarity": "quest", "value": 0, "stack": 1, "max_stack": 10})
	_add("venom_gland", {"id": "venom_gland", "name": "Venom Gland", "type": "quest_item", "description": "Toxic organ from a Mire Beast.", "rarity": "quest", "value": 0, "stack": 1, "max_stack": 10})
	_add("ancient_relic", {"id": "ancient_relic", "name": "Ancient Relic", "type": "quest_item", "description": "A relic from a forgotten age.", "rarity": "quest", "value": 0})
	
	# === SPELLS ===
	_add("holy_spark", {"id": "holy_spark", "name": "Holy Spark", "type": "spell", "subtype": "projectile", "damage": 15, "mana_cost": 12, "cooldown": 0.8, "description": "A divine spark that burns the unholy.", "rarity": "common", "level_req": 1})
	_add("flame_wave", {"id": "flame_wave", "name": "Flame Wave", "type": "spell", "subtype": "area", "damage": 25, "mana_cost": 20, "cooldown": 1.5, "description": "A wave of fire that scorches all nearby.", "rarity": "uncommon", "level_req": 5})
	_add("ice_lance", {"id": "ice_lance", "name": "Ice Lance", "type": "spell", "subtype": "projectile", "damage": 30, "mana_cost": 18, "cooldown": 1.0, "description": "A piercing shard of ice.", "rarity": "uncommon", "level_req": 8})
	_add("lightning_bolt", {"id": "lightning_bolt", "name": "Lightning Bolt", "type": "spell", "subtype": "projectile", "damage": 40, "mana_cost": 25, "cooldown": 1.2, "description": "Calls down divine lightning.", "rarity": "rare", "level_req": 10})
	_add("dark_nova", {"id": "dark_nova", "name": "Dark Nova", "type": "spell", "subtype": "area", "damage": 50, "mana_cost": 35, "cooldown": 2.0, "description": "An explosion of shadow energy.", "rarity": "rare", "level_req": 14})
	_add("divine_wrath", {"id": "divine_wrath", "name": "Divine Wrath", "type": "spell", "subtype": "area", "damage": 70, "mana_cost": 50, "cooldown": 3.0, "description": "The ultimate holy spell. Devastates all enemies.", "rarity": "epic", "level_req": 18})
	_add("ancient_staff", {"id": "ancient_staff", "name": "Ancient Staff", "type": "spell", "subtype": "beam", "damage": 35, "mana_cost": 22, "cooldown": 1.0, "description": "Channels a continuous beam of energy.", "rarity": "rare", "level_req": 12})

func _add(id: String, data: Dictionary) -> void:
	item_database[id] = data

func get_item_by_id(id: String) -> Dictionary:
	if item_database.has(id):
		return item_database[id].duplicate(true)
	return {}

func generate_loot(tier: String = "common", player_level: int = 1) -> Array[Dictionary]:
	var loot: Array[Dictionary] = []
	var num_items = randi_range(1, 3)
	var rarity_weights = _get_rarity_weights(tier)
	
	for _i in num_items:
		var rarity = _roll_rarity(rarity_weights)
		var candidates = []
		for id in item_database:
			var item = item_database[id]
			if item.get("rarity", "common") == rarity and item.get("level_req", 1) <= player_level + 3:
				if item.type != "quest_item":
					candidates.append(item)
		if not candidates.is_empty():
			var chosen = candidates[randi() % candidates.size()].duplicate(true)
			loot.append(chosen)
	
	# Always drop some gold
	loot.append({"id": "gold_drop", "name": "Gold", "type": "gold", "value": randi_range(5, 15 + player_level * 5)})
	return loot

func _get_rarity_weights(tier: String) -> Dictionary:
	match tier:
		"common": return {"common": 60, "uncommon": 30, "rare": 9, "epic": 1}
		"uncommon": return {"common": 30, "uncommon": 45, "rare": 20, "epic": 5}
		"rare": return {"common": 10, "uncommon": 30, "rare": 45, "epic": 15}
		"epic": return {"common": 5, "uncommon": 15, "rare": 40, "epic": 35, "legendary": 5}
		_: return {"common": 70, "uncommon": 25, "rare": 5}

func _roll_rarity(weights: Dictionary) -> String:
	var total = 0
	for w in weights.values():
		total += w
	var roll = randi() % total
	var cumulative = 0
	for rarity in weights:
		cumulative += weights[rarity]
		if roll < cumulative:
			return rarity
	return "common"

func get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.8, 0.8, 0.8)
		"uncommon": return Color(0.3, 0.8, 0.3)
		"rare": return Color(0.3, 0.5, 1.0)
		"epic": return Color(0.7, 0.3, 0.9)
		"legendary": return Color(1.0, 0.7, 0.1)
		"quest": return Color(1.0, 1.0, 0.3)
		_: return Color.WHITE
