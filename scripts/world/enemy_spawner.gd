extends Node2D
## EnemySpawner - Spawns enemies in regions at startup and respawns them

const ENEMY_SCENE = preload("res://scenes/enemies/enemy.tscn")

# Spawn definitions per region
var spawn_data: Dictionary = {
	"ashen_wastes": {
		"origin": Vector2(0, 0),
		"size": Vector2(1600, 1600),
		"enemies": [
			{"id": "hollow_soldier", "count": 8},
			{"id": "hollow_archer", "count": 4},
			{"id": "bandit", "count": 3},
		]
	},
	"crimson_mire": {
		"origin": Vector2(1760, 0),
		"size": Vector2(1600, 1600),
		"enemies": [
			{"id": "mire_beast", "count": 6},
			{"id": "mire_spitter", "count": 4},
		]
	},
	"frozen_peaks": {
		"origin": Vector2(0, -1760),
		"size": Vector2(1600, 1600),
		"enemies": [
			{"id": "frost_wolf", "count": 8},
		]
	},
	"shadow_citadel": {
		"origin": Vector2(1760, -1760),
		"size": Vector2(1600, 1600),
		"enemies": [
			{"id": "shadow_knight", "count": 5},
			{"id": "shadow_mage", "count": 3},
		]
	},
}

func _ready() -> void:
	_spawn_all_regions()

func _spawn_all_regions() -> void:
	for region_id in spawn_data:
		var data = spawn_data[region_id]
		var origin = data.origin
		var size = data.size
		for enemy_def in data.enemies:
			for _i in range(enemy_def.count):
				var enemy = ENEMY_SCENE.instantiate()
				var pos = origin + Vector2(
					randf_range(64, size.x - 64),
					randf_range(64, size.y - 64)
				)
				enemy.global_position = pos
				var edata = _get_enemy_data(enemy_def.id)
				call_deferred("_setup_enemy", enemy, edata)
				add_child(enemy)

func _setup_enemy(enemy: CharacterBody2D, data: Dictionary) -> void:
	if enemy.has_method("setup_from_data"):
		enemy.setup_from_data(data)

func _get_enemy_data(enemy_id: String) -> Dictionary:
	var ng = GameManager.ng_plus_scaling_enemy()
	var world = get_parent()
	if world and world.has_method("_get_enemy_data"):
		return world._get_enemy_data(enemy_id)
	# Fallback
	match enemy_id:
		"hollow_soldier":
			return {"id": "hollow_soldier", "name": "Hollow Soldier", "max_hp": 40 * ng, "damage": 8 * ng, "move_speed": 80, "chase_speed": 120, "xp_reward": 20, "gold_reward": 8, "detect_range": 180, "attack_range": 28}
		"hollow_archer":
			return {"id": "hollow_archer", "name": "Hollow Archer", "max_hp": 30 * ng, "damage": 12 * ng, "move_speed": 60, "chase_speed": 80, "xp_reward": 25, "gold_reward": 10, "detect_range": 250, "attack_range": 35}
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
			return {"id": "bandit", "name": "Bandit", "max_hp": 45 * ng, "damage": 10 * ng, "move_speed": 100, "chase_speed": 140, "xp_reward": 20, "gold_reward": 15, "detect_range": 180, "attack_range": 28}
		_:
			return {"id": enemy_id, "name": enemy_id, "max_hp": 40 * ng, "damage": 8 * ng}
