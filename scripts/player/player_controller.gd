extends CharacterBody2D
## Player Controller - John the Baptist
## Handles movement, combat, dodge, magic, and all player interactions
## Polished with distinct visuals and full audio integration

# Signals
signal hp_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal mana_changed(current: int, maximum: int)
signal player_died_signal
signal combo_changed(combo_count: int)
signal weapon_changed(weapon: Dictionary)
signal spell_changed(spell: Dictionary)
signal damage_dealt(amount: float)

# Movement
const MOVE_SPEED: float = 200.0
const DODGE_SPEED: float = 400.0
const DODGE_DURATION: float = 0.3
const DODGE_COOLDOWN: float = 0.5
const DODGE_STAMINA_COST: float = 20.0
const STAMINA_REGEN: float = 25.0
const MANA_REGEN: float = 5.0

# Combat
const LIGHT_ATTACK_DAMAGE_MULT: float = 1.0
const HEAVY_ATTACK_DAMAGE_MULT: float = 1.8
const COMBO_WINDOW: float = 0.5
const COMBO_MAX: int = 3
const LIGHT_ATTACK_STAMINA: float = 10.0
const HEAVY_ATTACK_STAMINA: float = 20.0
const ATTACK_KNOCKBACK: float = 150.0

# State machine
enum State { IDLE, MOVING, ATTACKING, DODGING, CASTING, STUNNED, DEAD, INTERACTING }
var current_state: State = State.IDLE

# Internal vars
var move_dir: Vector2 = Vector2.ZERO
var face_dir: Vector2 = Vector2.DOWN
var is_invulnerable: bool = false
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0
var attack_duration: float = 0.3
var combo_count: int = 0
var combo_timer: float = 0.0
var is_heavy_attack: bool = false
var cast_timer: float = 0.0
var spell_cooldown_timer: float = 0.0
var stun_timer: float = 0.0
var interact_target: Node2D = null
var nearby_interactables: Array[Node2D] = []

# Visual flash for damage
var flash_timer: float = 0.0
# Trail effect
var trail_timer: float = 0.0

# Node references (set in _ready)
@onready var sprite: Polygon2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var interact_area: Area2D = $InteractArea
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var spell_spawn: Marker2D = $SpellSpawn

func _ready() -> void:
	GameManager.player_node = self
	add_to_group("player")
	attack_area.monitoring = false
	_emit_all_stats()
	_build_player_visual()
	# Show movement tutorial on first play
	TutorialManager.show_tutorial("movement")

func _emit_all_stats() -> void:
	hp_changed.emit(GameManager.player_stats.hp, GameManager.player_stats.max_hp)
	stamina_changed.emit(GameManager.player_stats.stamina, GameManager.player_stats.max_stamina)
	mana_changed.emit(GameManager.player_stats.mana, GameManager.player_stats.max_mana)
	weapon_changed.emit(GameManager.get_current_weapon())
	spell_changed.emit(GameManager.get_current_spell())

func _build_player_visual() -> void:
	if not sprite:
		return
	# Distinct knight/crusader silhouette - clearly different from enemies
	sprite.polygon = PackedVector2Array([
		Vector2(-6, -14), Vector2(-2, -18), Vector2(2, -18), Vector2(6, -14),  # helmet
		Vector2(8, -10), Vector2(10, -6),  # right shoulder
		Vector2(8, -2), Vector2(10, 4),  # right arm
		Vector2(7, 8), Vector2(4, 13), Vector2(2, 14),  # right leg
		Vector2(0, 12),  # center
		Vector2(-2, 14), Vector2(-4, 13), Vector2(-7, 8),  # left leg
		Vector2(-10, 4), Vector2(-8, -2),  # left arm
		Vector2(-10, -6), Vector2(-8, -10),  # left shoulder
	])
	sprite.color = Color(0.15, 0.5, 0.85)  # Bright blue - very distinct

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.PLAYING:
		return
	
	_update_timers(delta)
	_regen_stats(delta)
	
	match current_state:
		State.IDLE, State.MOVING:
			_handle_movement(delta)
			_handle_combat_input()
			_handle_other_input()
		State.ATTACKING:
			_process_attack(delta)
		State.DODGING:
			_process_dodge(delta)
		State.CASTING:
			_process_cast(delta)
		State.STUNNED:
			_process_stun(delta)
		State.DEAD:
			pass
	
	move_and_slide()
	_update_visuals(delta)

func _update_timers(delta: float) -> void:
	if dodge_cooldown_timer > 0:
		dodge_cooldown_timer -= delta
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0
			combo_changed.emit(0)
	if spell_cooldown_timer > 0:
		spell_cooldown_timer -= delta
	if flash_timer > 0:
		flash_timer -= delta

func _regen_stats(delta: float) -> void:
	if current_state == State.DEAD:
		return
	# Stamina regen
	var stam_regen = STAMINA_REGEN * SkillManager.get_stamina_regen_multiplier()
	if current_state != State.ATTACKING and current_state != State.DODGING:
		GameManager.player_stats.stamina = minf(
			GameManager.player_stats.stamina + stam_regen * delta,
			GameManager.player_stats.max_stamina
		)
		stamina_changed.emit(GameManager.player_stats.stamina, GameManager.player_stats.max_stamina)
	# Mana regen
	var mana_regen = MANA_REGEN * SkillManager.get_mana_regen_multiplier()
	GameManager.player_stats.mana = mini(
		GameManager.player_stats.mana + int(mana_regen * delta),
		GameManager.player_stats.max_mana
	)
	mana_changed.emit(GameManager.player_stats.mana, GameManager.player_stats.max_mana)

func _handle_movement(_delta: float) -> void:
	move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir.length() > 0.1:
		face_dir = move_dir.normalized()
		velocity = move_dir * MOVE_SPEED
		current_state = State.MOVING
		_update_face_direction()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, MOVE_SPEED * 0.3)
		if velocity.length() < 10:
			current_state = State.IDLE

func _handle_combat_input() -> void:
	# Dodge
	if Input.is_action_just_pressed("dodge") and dodge_cooldown_timer <= 0:
		if GameManager.player_stats.stamina >= DODGE_STAMINA_COST:
			_start_dodge()
			TutorialManager.show_tutorial("dodge")
			return
	
	# Light attack
	if Input.is_action_just_pressed("light_attack"):
		if GameManager.player_stats.stamina >= LIGHT_ATTACK_STAMINA:
			_start_attack(false)
			TutorialManager.show_tutorial("combat")
			return
	
	# Heavy attack
	if Input.is_action_just_pressed("heavy_attack"):
		if GameManager.player_stats.stamina >= HEAVY_ATTACK_STAMINA:
			_start_attack(true)
			return
	
	# Cast spell
	if Input.is_action_just_pressed("cast_spell"):
		_start_cast()
		TutorialManager.show_tutorial("magic")
		return
	
	# Cycle spell
	if Input.is_action_just_pressed("cycle_spell"):
		var spell = GameManager.cycle_spell()
		spell_changed.emit(spell)
		AudioManager.play_sfx("equip")
	
	# Cycle weapon
	if Input.is_action_just_pressed("cycle_weapon"):
		var weapon = GameManager.cycle_weapon()
		weapon_changed.emit(weapon)
		AudioManager.play_sfx("equip")

func _handle_other_input() -> void:
	# Interact
	if Input.is_action_just_pressed("interact"):
		_try_interact()
		TutorialManager.show_tutorial("interact")
	
	# Use healing item
	if Input.is_action_just_pressed("use_item"):
		if GameManager.player_stats.hp < GameManager.player_stats.max_hp:
			if GameManager.use_consumable("health_potion") or GameManager.use_consumable("health_potion_large"):
				hp_changed.emit(GameManager.player_stats.hp, GameManager.player_stats.max_hp)
				AudioManager.play_sfx("heal")
		elif GameManager.player_stats.mana < GameManager.player_stats.max_mana:
			if GameManager.use_consumable("mana_potion") or GameManager.use_consumable("mana_potion_large"):
				mana_changed.emit(GameManager.player_stats.mana, GameManager.player_stats.max_mana)
				AudioManager.play_sfx("heal")
	
	# UI toggles
	if Input.is_action_just_pressed("inventory"):
		TutorialManager.show_tutorial("inventory")
	if Input.is_action_just_pressed("quest_log"):
		TutorialManager.show_tutorial("quest")
	if Input.is_action_just_pressed("skill_tree"):
		TutorialManager.show_tutorial("skills")

# === DODGE ===
func _start_dodge() -> void:
	current_state = State.DODGING
	is_invulnerable = true
	dodge_timer = DODGE_DURATION
	dodge_cooldown_timer = DODGE_COOLDOWN
	GameManager.player_stats.stamina -= DODGE_STAMINA_COST
	stamina_changed.emit(GameManager.player_stats.stamina, GameManager.player_stats.max_stamina)
	dodge_direction = face_dir if move_dir.length() < 0.1 else move_dir.normalized()
	AudioManager.play_sfx("dodge")
	# Visual: slight scale change
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "scale", Vector2(0.8, 1.2), DODGE_DURATION * 0.5)
		tw.tween_property(sprite, "scale", Vector2(1, 1), DODGE_DURATION * 0.5)

func _process_dodge(delta: float) -> void:
	velocity = dodge_direction * DODGE_SPEED
	dodge_timer -= delta
	if dodge_timer <= 0:
		is_invulnerable = false
		current_state = State.IDLE

# === ATTACK ===
func _start_attack(heavy: bool) -> void:
	is_heavy_attack = heavy
	current_state = State.ATTACKING
	
	var weapon = GameManager.get_current_weapon()
	var speed_mult = weapon.get("speed", 1.0) * SkillManager.get_attack_speed_multiplier()
	attack_duration = (0.4 if heavy else 0.25) / speed_mult
	attack_timer = attack_duration
	
	var stam_cost = HEAVY_ATTACK_STAMINA if heavy else LIGHT_ATTACK_STAMINA
	GameManager.player_stats.stamina -= stam_cost
	stamina_changed.emit(GameManager.player_stats.stamina, GameManager.player_stats.max_stamina)
	
	# Combo logic
	if not heavy and combo_timer > 0:
		combo_count = mini(combo_count + 1, COMBO_MAX)
	elif not heavy:
		combo_count = 1
	else:
		combo_count = 0
	combo_timer = COMBO_WINDOW
	combo_changed.emit(combo_count)
	
	if combo_count >= COMBO_MAX:
		AudioManager.play_sfx("combo")
	
	velocity = face_dir * 50  # Slight lunge
	
	# Play attack sound
	if heavy:
		AudioManager.play_sfx("heavy_swing")
	else:
		AudioManager.play_sfx("sword_swing")
	
	# Enable attack hitbox
	_position_attack_area()
	attack_area.monitoring = true
	
	# Damage enemies in area
	await get_tree().create_timer(0.05).timeout
	_apply_attack_damage()

func _apply_attack_damage() -> void:
	if not is_instance_valid(attack_area):
		return
	var bodies = attack_area.get_overlapping_bodies()
	var base_damage = GameManager.get_total_attack()
	var mult = HEAVY_ATTACK_DAMAGE_MULT if is_heavy_attack else LIGHT_ATTACK_DAMAGE_MULT
	mult *= SkillManager.get_melee_damage_multiplier()
	
	# Combo bonus
	if combo_count >= COMBO_MAX:
		mult *= 1.5
	
	var final_damage = base_damage * mult
	var hit_something = false
	
	for body in bodies:
		if body.has_method("take_damage") and body.is_in_group("enemies"):
			var knockback_dir = (body.global_position - global_position).normalized()
			body.take_damage(final_damage, knockback_dir * ATTACK_KNOCKBACK)
			damage_dealt.emit(final_damage)
			hit_something = true
			
			# Life steal
			var ls = SkillManager.get_life_steal()
			if ls > 0:
				GameManager.heal_player(int(final_damage * ls))
				hp_changed.emit(GameManager.player_stats.hp, GameManager.player_stats.max_hp)
	
	if hit_something:
		if is_heavy_attack:
			AudioManager.play_sfx("heavy_hit")
		else:
			AudioManager.play_sfx("sword_hit")

func _position_attack_area() -> void:
	if attack_area:
		attack_area.position = face_dir * 24

func _process_attack(delta: float) -> void:
	attack_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 300 * delta)
	if attack_timer <= 0:
		attack_area.monitoring = false
		current_state = State.IDLE

# === SPELLCASTING ===
func _start_cast() -> void:
	var spell = GameManager.get_current_spell()
	if spell.is_empty():
		return
	if spell_cooldown_timer > 0:
		return
	var mana_cost = int(spell.get("mana_cost", 10) * SkillManager.get_mana_cost_multiplier())
	if GameManager.player_stats.mana < mana_cost:
		return
	
	current_state = State.CASTING
	cast_timer = 0.3
	GameManager.player_stats.mana -= mana_cost
	mana_changed.emit(GameManager.player_stats.mana, GameManager.player_stats.max_mana)
	
	var cd = spell.get("cooldown", 1.0) * (1.0 - SkillManager.get_cooldown_reduction())
	spell_cooldown_timer = cd
	
	velocity = Vector2.ZERO
	AudioManager.play_sfx("spell_cast")
	_spawn_spell(spell)

func _spawn_spell(spell: Dictionary) -> void:
	var spell_scene = preload("res://scenes/effects/spell_projectile.tscn")
	var proj = spell_scene.instantiate()
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + face_dir * 20
	
	var base_damage = spell.get("damage", 10) + GameManager.get_spell_power()
	var spell_mult = SkillManager.get_spell_damage_multiplier()
	if spell.get("subtype", "") == "area":
		spell_mult *= SkillManager.get_area_spell_multiplier()
	
	proj.setup(face_dir, base_damage * spell_mult, spell)

func _process_cast(delta: float) -> void:
	cast_timer -= delta
	if cast_timer <= 0:
		current_state = State.IDLE

# === DAMAGE & DEATH ===
func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_invulnerable or current_state == State.DEAD:
		return
	
	var defense = GameManager.get_total_defense()
	var reduction = SkillManager.get_damage_reduction()
	var final_damage = maxf(1, amount - defense * 0.5) * (1.0 - reduction)
	
	GameManager.player_stats.hp -= int(final_damage)
	hp_changed.emit(GameManager.player_stats.hp, GameManager.player_stats.max_hp)
	flash_timer = 0.15
	AudioManager.play_sfx("player_hit")
	
	# Knockback
	velocity += knockback
	
	if GameManager.player_stats.hp <= 0:
		_die()
	else:
		# Brief invulnerability after hit
		is_invulnerable = true
		await get_tree().create_timer(0.2).timeout
		if current_state != State.DODGING:
			is_invulnerable = false

func _die() -> void:
	current_state = State.DEAD
	GameManager.player_stats.hp = 0
	velocity = Vector2.ZERO
	AudioManager.play_sfx("player_death")
	player_died_signal.emit()
	GameManager.player_died.emit()
	GameManager.set_state(GameManager.GameState.DEAD)

func respawn(pos: Vector2) -> void:
	global_position = pos
	GameManager.player_stats.hp = GameManager.player_stats.max_hp
	GameManager.player_stats.mana = GameManager.player_stats.max_mana
	GameManager.player_stats.stamina = GameManager.player_stats.max_stamina
	current_state = State.IDLE
	is_invulnerable = false
	_emit_all_stats()
	GameManager.set_state(GameManager.GameState.PLAYING)

# === INTERACTION ===
func _try_interact() -> void:
	if nearby_interactables.is_empty():
		return
	var closest: Node2D = null
	var closest_dist: float = 9999
	for obj in nearby_interactables:
		if is_instance_valid(obj):
			var dist = global_position.distance_to(obj.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = obj
	if closest and closest.has_method("interact"):
		closest.interact(self)

func register_interactable(node: Node2D) -> void:
	if node not in nearby_interactables:
		nearby_interactables.append(node)

func unregister_interactable(node: Node2D) -> void:
	nearby_interactables.erase(node)

# === STUN ===
func apply_stun(duration: float) -> void:
	if current_state == State.DEAD or is_invulnerable:
		return
	current_state = State.STUNNED
	stun_timer = duration

func _process_stun(delta: float) -> void:
	stun_timer -= delta
	velocity = velocity.move_toward(Vector2.ZERO, 300 * delta)
	if stun_timer <= 0:
		current_state = State.IDLE

# === VISUALS ===
func _update_face_direction() -> void:
	if not sprite:
		return
	# Rotate sprite to face direction
	sprite.rotation = face_dir.angle() + PI/2

func _update_visuals(_delta: float) -> void:
	if not sprite:
		return
	# Flash red when damaged
	if flash_timer > 0:
		sprite.color = Color(1, 0.3, 0.3)
	elif is_invulnerable:
		# Flicker during i-frames
		sprite.color = Color(0.15, 0.5, 0.85, 0.5)
	else:
		sprite.color = Color(0.15, 0.5, 0.85)
	
	# Slight bob when moving
	if current_state == State.MOVING:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.01) * 2
	else:
		sprite.position.y = 0

# Called by InteractArea signals
func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.has_method("interact"):
		register_interactable(body)

func _on_interact_area_body_exited(body: Node2D) -> void:
	unregister_interactable(body)

func _on_interact_area_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.has_method("interact"):
		register_interactable(parent)

func _on_interact_area_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent:
		unregister_interactable(parent)
