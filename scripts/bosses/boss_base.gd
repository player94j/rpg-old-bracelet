extends CharacterBody2D
## Boss Base - Multi-phase boss system
## Supports multiple phases, attack patterns, and phase transitions

signal boss_phase_changed(phase: int)
signal boss_defeated_signal(boss_id: String)
signal boss_health_changed(current: float, maximum: float)

@export var boss_id: String = "boss_hollow_knight"
@export var boss_name: String = "Hollow Knight"
@export var max_hp: float = 500.0
@export var phase_count: int = 2
@export var base_damage: float = 20.0
@export var move_speed: float = 80.0
@export var attack_range: float = 50.0

enum BossState { INTRO, IDLE, CHASE, ATTACK, PHASE_TRANSITION, SPECIAL, DEAD }
var boss_state: BossState = BossState.INTRO
var hp: float = 500.0
var current_phase: int = 1
var target: Node2D = null
var attack_timer: float = 0.0
var state_timer: float = 0.0
var attack_pattern_index: int = 0
var knockback_velocity: Vector2 = Vector2.ZERO
var flash_timer: float = 0.0
var ng_scale: float = 1.0
var intro_done: bool = false

# Phase thresholds (hp percentage to trigger next phase)
var phase_thresholds: Array[float] = [0.5]  # Default: phase 2 at 50% HP

# Attack patterns per phase
var attack_patterns: Dictionary = {
	1: ["slash", "slam", "charge"],
	2: ["slash", "slam", "charge", "aoe", "summon"],
}

@onready var sprite: Polygon2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var boss_health_bar: ProgressBar = $BossHealthBar

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	ng_scale = GameManager.ng_plus_scaling_enemy()
	
	# NG+ boss enhancements
	if GameManager.ng_plus_cycle > 0:
		max_hp *= ng_scale
		base_damage *= ng_scale
		move_speed *= 1.0 + GameManager.ng_plus_cycle * 0.1
		# Add extra patterns in NG+
		if GameManager.ng_plus_cycle >= 1:
			attack_patterns[1].append("aoe")
			attack_patterns[2].append("rapid_slash")
	
	hp = max_hp
	_setup_phase_thresholds()
	
	if boss_health_bar:
		boss_health_bar.max_value = max_hp
		boss_health_bar.value = hp
	
	TutorialManager.show_tutorial("boss")
	
	# Intro delay
	state_timer = 2.0

func _setup_phase_thresholds() -> void:
	phase_thresholds.clear()
	for i in range(1, phase_count):
		phase_thresholds.append(1.0 - (float(i) / float(phase_count)))

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	_update_timers(delta)
	
	match boss_state:
		BossState.INTRO:
			_boss_intro(delta)
		BossState.IDLE:
			_boss_idle(delta)
		BossState.CHASE:
			_boss_chase(delta)
		BossState.ATTACK:
			_boss_attack(delta)
		BossState.PHASE_TRANSITION:
			_boss_phase_transition(delta)
		BossState.SPECIAL:
			_boss_special(delta)
		BossState.DEAD:
			return
	
	if knockback_velocity.length() > 5:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 300 * delta)
	
	move_and_slide()
	_update_visuals(delta)

func _update_timers(delta: float) -> void:
	if attack_timer > 0:
		attack_timer -= delta
	if flash_timer > 0:
		flash_timer -= delta
	state_timer -= delta

func _boss_intro(delta: float) -> void:
	velocity = Vector2.ZERO
	if state_timer <= 0:
		intro_done = true
		boss_state = BossState.IDLE
		target = _find_player()

func _boss_idle(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	if not target or not is_instance_valid(target):
		target = _find_player()
	if target:
		boss_state = BossState.CHASE
	if state_timer <= 0:
		state_timer = 1.0

func _boss_chase(delta: float) -> void:
	if not target or not is_instance_valid(target):
		boss_state = BossState.IDLE
		return
	
	var dist = global_position.distance_to(target.global_position)
	if dist <= attack_range:
		boss_state = BossState.ATTACK
		state_timer = 0.4  # Wind-up
		velocity = Vector2.ZERO
		return
	
	var dir = (target.global_position - global_position).normalized()
	velocity = dir * move_speed * (1.0 + (current_phase - 1) * 0.2)
	_face_direction(dir)

func _boss_attack(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, 200 * delta)
	if state_timer <= 0 and attack_timer <= 0:
		var patterns = attack_patterns.get(current_phase, attack_patterns[1])
		var pattern = patterns[attack_pattern_index % patterns.size()]
		_execute_attack(pattern)
		attack_pattern_index += 1
		attack_timer = 1.5 / (1.0 + (current_phase - 1) * 0.2)
		boss_state = BossState.CHASE

func _execute_attack(pattern: String) -> void:
	if not target or not is_instance_valid(target):
		return
	var dir = (target.global_position - global_position).normalized()
	
	match pattern:
		"slash":
			_attack_slash(dir)
		"slam":
			_attack_slam()
		"charge":
			_attack_charge(dir)
		"aoe":
			_attack_aoe()
		"summon":
			_attack_summon()
		"rapid_slash":
			_attack_rapid_slash(dir)

func _attack_slash(dir: Vector2) -> void:
	if target and target.has_method("take_damage"):
		var dist = global_position.distance_to(target.global_position)
		if dist < attack_range * 2:
			target.take_damage(base_damage, dir * 150)
	velocity = dir * 100

func _attack_slam() -> void:
	# AoE ground slam
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if global_position.distance_to(p.global_position) < attack_range * 2.5:
			var dir = (p.global_position - global_position).normalized()
			p.take_damage(base_damage * 1.3, dir * 200)
	# Visual effect
	_spawn_aoe_effect(global_position, attack_range * 2.5)

func _attack_charge(dir: Vector2) -> void:
	velocity = dir * move_speed * 4
	# Damage on contact handled by collision
	await get_tree().create_timer(0.5).timeout
	if target and is_instance_valid(target):
		if global_position.distance_to(target.global_position) < attack_range * 2:
			var kdir = (target.global_position - global_position).normalized()
			target.take_damage(base_damage * 1.5, kdir * 250)

func _attack_aoe() -> void:
	# Delayed AoE
	_spawn_aoe_effect(global_position, 80)
	await get_tree().create_timer(0.8).timeout
	var players = get_tree().get_nodes_in_group("player")
	for p in players:
		if global_position.distance_to(p.global_position) < 80:
			var dir = (p.global_position - global_position).normalized()
			p.take_damage(base_damage * 1.8, dir * 180)

func _attack_summon() -> void:
	# Spawn minions
	var enemy_scene = preload("res://scenes/enemies/enemy.tscn")
	for i in range(2):
		var minion = enemy_scene.instantiate()
		var offset = Vector2(randf_range(-60, 60), randf_range(-60, 60))
		minion.global_position = global_position + offset
		minion.max_hp = 30 * ng_scale
		minion.damage = 5 * ng_scale
		minion.enemy_id = "boss_minion"
		minion.enemy_name = "Summoned Hollow"
		minion.xp_reward = 10
		minion.gold_reward = 5
		get_tree().current_scene.call_deferred("add_child", minion)

func _attack_rapid_slash(dir: Vector2) -> void:
	for i in range(3):
		await get_tree().create_timer(0.2).timeout
		if target and is_instance_valid(target):
			if global_position.distance_to(target.global_position) < attack_range * 2:
				target.take_damage(base_damage * 0.6, dir * 80)

func _boss_phase_transition(delta: float) -> void:
	velocity = Vector2.ZERO
	if state_timer <= 0:
		current_phase += 1
		boss_phase_changed.emit(current_phase)
		# Heal slightly on phase change
		hp += max_hp * 0.1
		hp = minf(hp, max_hp)
		boss_health_changed.emit(hp, max_hp)
		if boss_health_bar:
			boss_health_bar.value = hp
		boss_state = BossState.CHASE
		# Burst of speed after transition
		move_speed *= 1.15

func _boss_special(delta: float) -> void:
	velocity = Vector2.ZERO
	if state_timer <= 0:
		boss_state = BossState.CHASE

func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if boss_state == BossState.DEAD or boss_state == BossState.PHASE_TRANSITION:
		return
	if boss_state == BossState.INTRO:
		return
	
	hp -= amount
	knockback_velocity = knockback * 0.3  # Bosses resist knockback
	flash_timer = 0.15
	
	boss_health_changed.emit(hp, max_hp)
	if boss_health_bar:
		boss_health_bar.value = hp
	
	if hp <= 0:
		_die()
	else:
		_check_phase_transition()

func _check_phase_transition() -> void:
	var hp_pct = hp / max_hp
	if current_phase <= phase_thresholds.size():
		if hp_pct <= phase_thresholds[current_phase - 1]:
			boss_state = BossState.PHASE_TRANSITION
			state_timer = 2.0
			# Invulnerable during transition
			flash_timer = 2.0

func _die() -> void:
	boss_state = BossState.DEAD
	hp = 0
	velocity = Vector2.ZERO
	
	GameManager.on_boss_defeated(boss_id)
	GameManager.on_enemy_killed({
		"id": boss_id,
		"name": boss_name,
		"xp": xp_reward_calc(),
		"gold": gold_reward_calc(),
		"is_elite": true,
	})
	QuestManager.notify_kill(boss_id)
	boss_defeated_signal.emit(boss_id)
	
	# Drop epic loot
	_drop_boss_loot()
	
	# Death animation
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.5)
		tw.parallel().tween_property(sprite, "modulate:a", 0.0, 1.0)
		tw.tween_callback(queue_free)

func _drop_boss_loot() -> void:
	var loot = LootTable.generate_loot("epic", GameManager.player_stats.level)
	for item in loot:
		if item.type == "gold":
			GameManager.add_gold(item.value * 3)
		else:
			var pickup_scene = preload("res://scenes/world/loot_pickup.tscn")
			var pickup = pickup_scene.instantiate()
			pickup.global_position = global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
			pickup.item_data = item
			get_tree().current_scene.call_deferred("add_child", pickup)

func xp_reward_calc() -> int:
	return int(200 * current_phase * ng_scale)

func gold_reward_calc() -> int:
	return int(100 * current_phase * ng_scale)

func _find_player() -> Node2D:
	var players = get_tree().get_nodes_in_group("player")
	return players[0] if players.size() > 0 else null

func _face_direction(dir: Vector2) -> void:
	if sprite:
		sprite.rotation = dir.angle() + PI/2

func _spawn_aoe_effect(pos: Vector2, radius: float) -> void:
	var effect = preload("res://scenes/effects/aoe_effect.tscn").instantiate()
	effect.global_position = pos
	effect.setup(radius)
	get_tree().current_scene.add_child(effect)

func _update_visuals(_delta: float) -> void:
	if not sprite:
		return
	if flash_timer > 0:
		sprite.color = Color.WHITE
	else:
		match current_phase:
			1: sprite.color = Color(0.8, 0.2, 0.2)
			2: sprite.color = Color(0.9, 0.1, 0.5)
			3: sprite.color = Color(0.6, 0.1, 0.8)
			_: sprite.color = Color(0.3, 0.0, 0.1)
	# Pulsing effect in phase transition
	if boss_state == BossState.PHASE_TRANSITION:
		var pulse = (sin(Time.get_ticks_msec() * 0.01) + 1) * 0.5
		sprite.color = sprite.color.lerp(Color.WHITE, pulse)

func setup_boss(id: String, data: Dictionary) -> void:
	boss_id = id
	boss_name = data.get("name", boss_name)
	max_hp = data.get("max_hp", max_hp)
	base_damage = data.get("damage", base_damage)
	phase_count = data.get("phases", phase_count)
	attack_range = data.get("attack_range", attack_range)
	move_speed = data.get("move_speed", move_speed)
	if data.has("patterns"):
		attack_patterns = data.patterns
