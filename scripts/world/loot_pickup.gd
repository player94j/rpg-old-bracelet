extends Area2D
## Loot Pickup - Collectible items dropped by enemies
## Distinct visual based on rarity with glow effect

var item_data: Dictionary = {}
var bob_offset: float = 0.0
var collected: bool = false

@onready var sprite: Polygon2D = $Sprite
@onready var label: Label = $Label

func _ready() -> void:
	add_to_group("pickups")
	bob_offset = randf() * TAU
	body_entered.connect(_on_body_entered)
	if label and not item_data.is_empty():
		label.text = item_data.get("name", "Item")
		label.visible = true
	_set_visual()

func _process(delta: float) -> void:
	if sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.005 + bob_offset) * 3
		# Slow rotation for visibility
		sprite.rotation += delta * 1.5

func _set_visual() -> void:
	if not sprite:
		return
	var rarity = item_data.get("rarity", "common") if not item_data.is_empty() else "common"
	sprite.color = LootTable.get_rarity_color(rarity)
	
	# Different shapes based on item type
	var item_type = item_data.get("type", "") if not item_data.is_empty() else ""
	match item_type:
		"weapon":
			# Diamond shape
			sprite.polygon = PackedVector2Array([
				Vector2(0, -8), Vector2(6, 0), Vector2(0, 8), Vector2(-6, 0)
			])
		"armor":
			# Shield shape
			sprite.polygon = PackedVector2Array([
				Vector2(-6, -6), Vector2(6, -6), Vector2(6, 2), Vector2(0, 8), Vector2(-6, 2)
			])
		"spell":
			# Star shape
			sprite.polygon = PackedVector2Array([
				Vector2(0, -8), Vector2(2, -3), Vector2(7, -3),
				Vector2(3, 1), Vector2(5, 7), Vector2(0, 3),
				Vector2(-5, 7), Vector2(-3, 1), Vector2(-7, -3), Vector2(-2, -3)
			])
		"consumable":
			# Potion/circle
			sprite.polygon = PackedVector2Array([
				Vector2(-2, -6), Vector2(2, -6), Vector2(4, -3),
				Vector2(5, 0), Vector2(5, 4), Vector2(3, 6),
				Vector2(-3, 6), Vector2(-5, 4), Vector2(-5, 0), Vector2(-4, -3)
			])
		_:
			# Default square
			sprite.polygon = PackedVector2Array([
				Vector2(-5, -5), Vector2(5, -5), Vector2(5, 5), Vector2(-5, 5)
			])

func _on_body_entered(body: Node2D) -> void:
	if collected:
		return
	if body.is_in_group("player"):
		collected = true
		_collect(body)

func _collect(_player: Node2D) -> void:
	if item_data.is_empty():
		queue_free()
		return
	
	AudioManager.play_sfx("pickup")
	
	match item_data.type:
		"weapon":
			GameManager.weapon_inventory.append(item_data)
			GameManager.item_acquired.emit(item_data)
		"spell":
			GameManager.spell_inventory.append(item_data)
			GameManager.item_acquired.emit(item_data)
		"armor", "accessory":
			GameManager.add_item(item_data)
		"consumable", "quest_item":
			if item_data.has("stack"):
				item_data.stack = 1
			GameManager.add_item(item_data)
			if item_data.type == "quest_item":
				QuestManager.notify_collect(item_data.id)
		_:
			GameManager.add_item(item_data)
	
	# Pickup animation
	if sprite:
		var tw = create_tween()
		tw.tween_property(self, "position:y", position.y - 20, 0.2)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
		tw.tween_callback(queue_free)
	else:
		queue_free()
