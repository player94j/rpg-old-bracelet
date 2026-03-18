extends CharacterBody2D
## Base Enemy AI - Foundation for all enemy types
## Supports patrol, chase, attack, flee, and death behaviors

signal enemy_died(enemy_data: Dictionary)
signal health_changed(current: float, maximum: float)

# Enemy data
@export var enemy_id: String = "hollow_soldier"
@export var enemy_name: String = "Hollow Soldier"
@export var max_hp: float = 50.0
@export var damage: float = 10.0
@export var move_speed: float = 100.0
@export var chase_speed: float = 140.0
@export var attack_range: float = 30.0
@export var detect_range: float = 200.0
@export var attack_cooldown: float = 1.0
@export var xp_reward: int = 25
@export var gold_reward: int = 10
@export var loot_tier: String = "common"
@export var is_elite: bool = false

# State
enum AIState { IDLE, PATROL, CHASE, ATTACK, HURT, FLEE, DEAD }
var ai_state: AIState = AIState.IDLE
var hp: float = 50.0
var target: Node2D = null
var patrol_points: Array[Vector2] = []
var patrol_index: int = 0
var home_position: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0
var hurt_timer: float = 0.0
var state_timer: float = 0.0
var idle_time: float = 2.0
var wander_dir: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var flash_timer: float = 0.0
var ng_scale: float = 1.0

@onready var sprite: Polygon2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var detection_area: Area2D = $DetectionArea
@onready var health_bar: ProgressBar = $HealthBar

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	home_position = global_position
	ng_scale = GameManager.ng_plus_scaling_enemy()
	max_hp *= ng_scale
	hp = max_hp
	damage *= ng_scale
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp
		health_bar.visible = false
	_generate_patrol_points()
	state_timer = randf_range(0.5, 2.0)

func _generate_patrol_points() -> void:
	for i in range(3):
		var angle = randf() * TAU
		var dist = randf_range(50, 150)
		patrol_points.append(home_position + Vector2(cos(angle), sin(angle)) * dist)

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		velocity = Vector2.ZERO
		return
	
	_update_timers(delta)
	
	match ai_state:
		AIState.IDLE:
			_ai_idle(delta)
		AIState.PATROL:
			_ai_patrol(delta)
		AIState.CHASE:
			_ai_chase(delta)
		AIState.ATTACK:
			_ai_attack(delta)
		AIState.HURT:
			_ai_hurt(delta)
		AIState.FLEE:
			_ai_flee(delta)
		AIState.DEAD:
			return
	
	# Apply knockback
	if knockback_velocity.length() > 5:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * delta)
	
	move_and_slide()
	_update_visuals(delta)

func _update_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
	if flash_timer > 0:
		flash_timer -= delta
	state_timer -= delta

func _ai_idle(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	if state_timer <= 0:
		ai_state = AIState.PATROL
		state_timer = randf_range(3, 6)
	_check_for_player()

func _ai_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		ai_state = AIState.IDLE
		state_timer = idle_time
		return
	var target_pos = patrol_points[patrol_index]
	var dir = (target_pos - global_position).normalized()
	velocity = dir * move_speed * 0.5
	
	if global_position.distance_to(target_pos) < 10:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		ai_state = AIState.IDLE
		state_timer = randf_range(1, 3)
	
	if state_timer <= 0:
		ai_state = AIState.IDLE
		state_timer = idle_time
	
	_check_for_player()

func _check_for_player() -> void:
	var player = _find_player()
	if player and global_position.distance_to(player.global_position) < detect_range:
		target = player
		ai_state = AIState.CHASE

func _ai_chase(delta: float) -> void:
	if not _valid_target():
		ai_state = AIState.PATROL
		return
	
	var dist = global_position.distance_to(target.global_position)
	
	# Return home if too far
	if dist > detect_range * 3:
		target = null
		ai_state = AIState.PATROL
		return
	
	if dist <= attack_range:
		ai_state = AIState.ATTACK
		state_timer = 0.2  # Wind-up
		velocity = Vector2.ZERO
		return
	
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * chase_speed
	_face_direction(dir)

func _ai_attack(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 300 * delta)
	
	if state_timer <= 0 and attack_timer <= 0:
		_perform_attack()
		attack_timer = attack_cooldown
		ai_state = AIState.CHASE

func _perform_attack() -> void:
	if not _valid_target():
		return
	var dist = global_position.distance_to(target.global_position)
	if dist <= attack_range * 1.5 and target.has_method("take_damage"):
		var knockback_dir = (target.global_position - global_position).normalized()
		target.take_damage(damage, knockback_dir * 100)
	# Visual lunge
	if _valid_target():
		var lunge_dir = (target.global_position - global_position).normalized()
		velocity = lunge_dir * 100

func _ai_hurt(delta: float) -> void:
	hurt_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 400 * delta)
	if hurt_timer <= 0:
		if hp < max_hp * 0.2 and not is_elite:
			ai_state = AIState.FLEE
			state_timer = 2.0
		else:
			ai_state = AIState.CHASE

func _ai_flee(delta: float) -> void:
	if not _valid_target():
		ai_state = AIState.PATROL
		return
	var away = (global_position - target.global_position).normalized()
	velocity = away * move_speed
	if state_timer <= 0:
		ai_state = AIState.CHASE

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if ai_state == AIState.DEAD:
		return
	hp -= amount
	knockback_velocity = knockback
	flash_timer = 0.15
	
	if health_bar:
		health_bar.value = hp
		health_bar.visible = true
	health_changed.emit(hp, max_hp)
	
	if hp <= 0:
		_die()
	else:
		ai_state = AIState.HURT
		hurt_timer = 0.3
		# Aggro on attacker
		var player = _find_player()
		if player:
			target = player

func _die() -> void:
	ai_state = AIState.DEAD
	hp = 0
	velocity = Vector2.ZERO
	
	var data = {
		"id": enemy_id,
		"name": enemy_name,
		"xp": xp_reward,
		"gold": gold_reward,
		"is_elite": is_elite,
	}
	
	GameManager.on_enemy_killed(data)
	QuestManager.notify_kill(enemy_id)
	enemy_died.emit(data)
	
	# Drop loot
	_drop_loot()
	
	# Death animation
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _drop_loot() -> void:
	var loot = LootTable.generate_loot(loot_tier, GameManager.player_stats.level)
	for item in loot:
		if item.type == "gold":
			GameManager.add_gold(item.value)
		else:
			# Spawn loot pickup in world
			var pickup_scene = preload("res://scenes/world/loot_pickup.tscn")
			var pickup = pickup_scene.instantiate()
			pickup.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
			pickup.item_data = item
			get_tree().current_scene.call_deferred("add_child", pickup)

func _valid_target() -> bool:
	return target and is_instance_valid(target) and target.current_state != target.State.DEAD

func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	return null

func _face_direction(dir: Vector2) -> void:
	if sprite:
		sprite.rotation = dir.angle() + PI/2

func _update_visuals(_delta: float) -> void:
	if not sprite:
		return
	if flash_timer > 0:
		sprite.color = Color.WHITE
	else:
		sprite.color = _get_enemy_color()

func _get_enemy_color() -> Color:
	if is_elite:
		return Color(0.9, 0.2, 0.9)  # Purple for elites
	match enemy_id:
		"hollow_soldier": return Color(0.6, 0.5, 0.4)
		"hollow_archer": return Color(0.5, 0.6, 0.4)
		"mire_beast": return Color(0.3, 0.6, 0.2)
		"mire_spitter": return Color(0.4, 0.7, 0.1)
		"frost_wolf": return Color(0.7, 0.8, 0.95)
		"shadow_knight": return Color(0.3, 0.1, 0.3)
		"shadow_mage": return Color(0.4, 0.1, 0.5)
		"bandit": return Color(0.6, 0.4, 0.3)
		_: return Color(0.7, 0.3, 0.3)

func setup_from_data(data: Dictionary) -> void:
	enemy_id = data.get("id", enemy_id)
	enemy_name = data.get("name", enemy_name)
	max_hp = data.get("max_hp", max_hp)
	damage = data.get("damage", damage)
	move_speed = data.get("move_speed", move_speed)
	chase_speed = data.get("chase_speed", chase_speed)
	attack_range = data.get("attack_range", attack_range)
	detect_range = data.get("detect_range", detect_range)
	xp_reward = data.get("xp_reward", xp_reward)
	gold_reward = data.get("gold_reward", gold_reward)
	loot_tier = data.get("loot_tier", loot_tier)
	is_elite = data.get("is_elite", is_elite)
