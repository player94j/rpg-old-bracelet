extends StaticBody2D
## NPC Base - Handles dialogue, quests, and merchant functionality
## NPCs have distinct green/teal visuals to differentiate from enemies

signal dialogue_started(npc_id: String)
signal dialogue_ended(npc_id: String)

@export var npc_id: String = "npc_hermit"
@export var npc_name: String = "Old Hermit"
@export var is_merchant: bool = false
@export var quest_to_give: String = ""
@export var dialogue_lines: Array[String] = []
@export var post_quest_lines: Array[String] = []

var current_line: int = 0
var in_dialogue: bool = false
var shop_items: Array[Dictionary] = []

@onready var sprite: Polygon2D = $Sprite
@onready var interact_label: Label = $InteractLabel
@onready var interact_area: Area2D = $InteractArea

func _ready() -> void:
	add_to_group("npcs")
	if interact_label:
		interact_label.visible = false
	_setup_npc_data()
	_build_npc_visual()

func _build_npc_visual() -> void:
	if not sprite:
		return
	# NPCs are distinctly shaped and colored - friendly appearance
	match npc_id:
		"npc_hermit":
			# Old man with robe
			sprite.polygon = PackedVector2Array([
				Vector2(-5, -14), Vector2(0, -18), Vector2(5, -14),
				Vector2(6, -8), Vector2(8, -2), Vector2(10, 6),
				Vector2(6, 14), Vector2(0, 16), Vector2(-6, 14),
				Vector2(-10, 6), Vector2(-8, -2), Vector2(-6, -8)
			])
			sprite.color = Color(0.3, 0.7, 0.4)  # Sage green
		"npc_ghost":
			# Translucent ghost shape
			sprite.polygon = PackedVector2Array([
				Vector2(-6, -14), Vector2(0, -18), Vector2(6, -14),
				Vector2(8, -4), Vector2(8, 8),
				Vector2(4, 12), Vector2(2, 8), Vector2(0, 14),
				Vector2(-2, 8), Vector2(-4, 12),
				Vector2(-8, 8), Vector2(-8, -4)
			])
			sprite.color = Color(0.6, 0.7, 0.9, 0.7)  # Ghostly blue
		"npc_blacksmith":
			# Stocky, broad shoulders
			sprite.polygon = PackedVector2Array([
				Vector2(-8, -12), Vector2(0, -16), Vector2(8, -12),
				Vector2(12, -4), Vector2(12, 4), Vector2(10, 10),
				Vector2(6, 14), Vector2(-6, 14), Vector2(-10, 10),
				Vector2(-12, 4), Vector2(-12, -4)
			])
			sprite.color = Color(0.7, 0.5, 0.3)  # Brown/forge
		"npc_spell_vendor":
			# Wizard with pointed hat
			sprite.polygon = PackedVector2Array([
				Vector2(-3, -20), Vector2(0, -26), Vector2(3, -20),  # hat point
				Vector2(6, -12), Vector2(8, -4), Vector2(10, 4),
				Vector2(6, 12), Vector2(0, 14), Vector2(-6, 12),
				Vector2(-10, 4), Vector2(-8, -4), Vector2(-6, -12)
			])
			sprite.color = Color(0.4, 0.3, 0.8)  # Purple/arcane
		"npc_witch":
			# Hunched witch
			sprite.polygon = PackedVector2Array([
				Vector2(-4, -16), Vector2(2, -20), Vector2(6, -14),
				Vector2(8, -6), Vector2(10, 2), Vector2(8, 10),
				Vector2(4, 14), Vector2(-2, 16), Vector2(-8, 12),
				Vector2(-10, 4), Vector2(-8, -6)
			])
			sprite.color = Color(0.3, 0.5, 0.3)  # Swamp green
		_:
			# Default friendly NPC
			sprite.polygon = PackedVector2Array([
				Vector2(-6, -12), Vector2(0, -16), Vector2(6, -12),
				Vector2(8, 0), Vector2(6, 12), Vector2(-6, 12), Vector2(-8, 0)
			])
			sprite.color = Color(0.3, 0.7, 0.5)

func _setup_npc_data() -> void:
	match npc_id:
		"npc_hermit":
			npc_name = "Old Hermit"
			dialogue_lines = [
				"Ah... you've awakened at last, John.",
				"The darkness spreads across these lands.",
				"A great evil stirs in the Shadow Citadel.",
				"But first, you must prove your worth.",
				"Seek the Hollow Knight in the Ashen Ruins.",
				"Defeat him, and your path will become clear."
			]
			post_quest_lines = [
				"You have done well, John the Baptist.",
				"Now venture forth to the Crimson Mire.",
				"The corruption runs deeper than we feared."
			]
			quest_to_give = "mq_01_awakening"
		"npc_ghost":
			npc_name = "Weeping Ghost"
			dialogue_lines = [
				"Please... my pendant... I cannot rest without it.",
				"It lies somewhere deep in the ruins.",
				"Find it... bring it back to me..."
			]
			post_quest_lines = [
				"Thank you... I can finally rest...",
				"Take this ring... it will protect you..."
			]
			quest_to_give = "sq_lost_pendant"
		"npc_witch":
			npc_name = "Swamp Witch"
			dialogue_lines = [
				"Hah... another fool enters the Mire.",
				"But you... you have the mark of the Baptist.",
				"A great beast festers in the heart of this swamp.",
				"The Bog Hydra. It guards the source of corruption.",
				"Bring me venom glands from the lesser beasts,",
				"and I shall brew a potion to weaken its defenses."
			]
			quest_to_give = ""
		"npc_blacksmith":
			npc_name = "Doran the Smith"
			is_merchant = true
			dialogue_lines = [
				"Welcome. I forge weapons for those who can pay.",
				"Browse my wares."
			]
			shop_items = [
				LootTable.get_item_by_id("iron_sword"),
				LootTable.get_item_by_id("battle_axe"),
				LootTable.get_item_by_id("twin_daggers"),
				LootTable.get_item_by_id("chainmail"),
				LootTable.get_item_by_id("health_potion"),
				LootTable.get_item_by_id("mana_potion"),
			]
			for item in shop_items:
				if not item.is_empty():
					item["price"] = item.get("value", 50)
		"npc_spell_vendor":
			npc_name = "Arcane Scholar"
			is_merchant = true
			dialogue_lines = [
				"Knowledge is power, traveler.",
				"I have spells for those worthy of wielding them."
			]
			shop_items = [
				LootTable.get_item_by_id("flame_wave"),
				LootTable.get_item_by_id("ice_lance"),
				LootTable.get_item_by_id("lightning_bolt"),
			]
			for item in shop_items:
				if not item.is_empty():
					item["price"] = item.get("value", 100) if item.has("value") else 100

func interact(player: Node2D) -> void:
	if in_dialogue:
		advance_dialogue()
		return
	
	in_dialogue = true
	current_line = 0
	
	var lines = dialogue_lines
	if not quest_to_give.is_empty() and QuestManager.is_quest_completed(quest_to_give):
		lines = post_quest_lines if not post_quest_lines.is_empty() else dialogue_lines
	
	GameManager.set_state(GameManager.GameState.DIALOGUE)
	dialogue_started.emit(npc_id)
	QuestManager.notify_interact(npc_id)
	AudioManager.play_sfx("npc_talk")
	
	var ui = get_tree().get_first_node_in_group("game_ui")
	if ui and ui.has_method("show_dialogue"):
		ui.show_dialogue(npc_name, lines[current_line])

func advance_dialogue() -> void:
	var lines = dialogue_lines
	if not quest_to_give.is_empty() and QuestManager.is_quest_completed(quest_to_give):
		lines = post_quest_lines if not post_quest_lines.is_empty() else dialogue_lines
	
	current_line += 1
	if current_line >= lines.size():
		end_dialogue()
		return
	
	AudioManager.play_sfx("npc_talk")
	var ui = get_tree().get_first_node_in_group("game_ui")
	if ui and ui.has_method("show_dialogue"):
		ui.show_dialogue(npc_name, lines[current_line])

func end_dialogue() -> void:
	in_dialogue = false
	current_line = 0
	
	if not quest_to_give.is_empty() and not QuestManager.is_quest_active(quest_to_give) and not QuestManager.is_quest_completed(quest_to_give):
		QuestManager.start_quest(quest_to_give)
	
	if is_merchant:
		var ui = get_tree().get_first_node_in_group("game_ui")
		if ui and ui.has_method("show_shop"):
			ui.show_shop(npc_name, shop_items)
			return
	
	GameManager.set_state(GameManager.GameState.PLAYING)
	dialogue_ended.emit(npc_id)
	var ui = get_tree().get_first_node_in_group("game_ui")
	if ui and ui.has_method("hide_dialogue"):
		ui.hide_dialogue()

func _on_interact_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if interact_label:
			interact_label.visible = true
		if body.has_method("register_interactable"):
			body.register_interactable(self)

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		if interact_label:
			interact_label.visible = false
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
		if in_dialogue:
			end_dialogue()
