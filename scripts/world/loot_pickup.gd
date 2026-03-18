extends Area2D
## Loot Pickup - Collectible items dropped by enemies

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
	_set_color()

func _process(delta: float) -> void:
	if sprite:
		sprite.position.y = sin(Time.get_ticks_msec() * 0.005 + bob_offset) * 3

func _set_color() -> void:
	if sprite and not item_data.is_empty():
		sprite.color = LootTable.get_rarity_color(item_data.get("rarity", "common"))

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
