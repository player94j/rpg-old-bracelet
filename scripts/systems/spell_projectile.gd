extends Area2D
## Spell Projectile - Handles all spell types (projectile, area, beam)

var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var damage: float = 15.0
var spell_data: Dictionary = {}
var lifetime: float = 3.0
var has_hit: bool = false
var spell_type: String = "projectile"
var aoe_radius: float = 60.0

@onready var sprite: Polygon2D = $Sprite
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func setup(dir: Vector2, dmg: float, data: Dictionary) -> void:
	direction = dir.normalized()
	damage = dmg
	spell_data = data
	spell_type = data.get("subtype", "projectile")
	rotation = direction.angle()
	
	match spell_type:
		"projectile":
			speed = 350.0
			lifetime = 2.5
		"area":
			speed = 0.0
			lifetime = 0.5
			aoe_radius = 80.0
			_do_area_damage()
		"beam":
			speed = 500.0
			lifetime = 1.5

func _physics_process(delta: float) -> void:
	if spell_type != "area":
		position += direction * speed * delta
	
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
	
	# Visual trail
	if sprite:
		sprite.color = _get_spell_color()
		modulate.a = clampf(lifetime, 0, 1)

func _on_body_entered(body: Node2D) -> void:
	if has_hit and spell_type == "projectile":
		return
	if body.is_in_group("player"):
		return
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var knockback = direction * 80
		body.take_damage(damage, knockback)
		_on_spell_hit(body)
		# Spell heal from skill
		var heal = SkillManager.get_spell_heal()
		if heal > 0:
			GameManager.heal_player(int(damage * heal))
		if spell_type == "projectile":
			has_hit = true
			# Chain lightning check
			var chains = SkillManager.get_chain_targets()
			if chains > 0:
				_chain_to_nearby(body, chains)
			queue_free()
	elif body.is_in_group("walls"):
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass

func _do_area_damage() -> void:
	# Delayed area damage
	await get_tree().create_timer(0.1).timeout
	var bodies = get_tree().get_nodes_in_group("enemies")
	for body in bodies:
		if global_position.distance_to(body.global_position) < aoe_radius:
			if body.has_method("take_damage"):
				var dir = (body.global_position - global_position).normalized()
				body.take_damage(damage, dir * 100)
	# Spawn visual
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "scale", Vector2(3, 3), 0.3)
		tw.parallel().tween_property(sprite, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)

func _chain_to_nearby(hit_body: Node2D, max_chains: int) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var chained = 0
	for enemy in enemies:
		if enemy == hit_body:
			continue
		if chained >= max_chains:
			break
		if global_position.distance_to(enemy.global_position) < 150:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage * 0.5, Vector2.ZERO)
				chained += 1

func _on_spell_hit(_body: Node2D) -> void:
	# Spawn hit effect
	pass

func _get_spell_color() -> Color:
	var id = spell_data.get("id", "")
	match id:
		"holy_spark": return Color(1.0, 0.9, 0.3)
		"flame_wave": return Color(1.0, 0.4, 0.1)
		"ice_lance": return Color(0.5, 0.8, 1.0)
		"lightning_bolt": return Color(1.0, 1.0, 0.5)
		"dark_nova": return Color(0.5, 0.0, 0.8)
		"divine_wrath": return Color(1.0, 0.95, 0.7)
		_: return Color(0.8, 0.6, 1.0)
