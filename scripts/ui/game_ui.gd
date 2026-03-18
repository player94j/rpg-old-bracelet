extends CanvasLayer
## GameUI - Complete HUD, dialogue, inventory, quest log, skill tree, shop, death screen

# Node references
@onready var hp_bar: ProgressBar = $HUD/TopLeft/HPBar
@onready var stamina_bar: ProgressBar = $HUD/TopLeft/StaminaBar
@onready var mana_bar: ProgressBar = $HUD/TopLeft/ManaBar
@onready var level_label: Label = $HUD/TopLeft/LevelLabel
@onready var gold_label: Label = $HUD/TopRight/GoldLabel
@onready var xp_bar: ProgressBar = $HUD/TopLeft/XPBar
@onready var weapon_label: Label = $HUD/BottomLeft/WeaponLabel
@onready var spell_label: Label = $HUD/BottomLeft/SpellLabel
@onready var combo_label: Label = $HUD/BottomCenter/ComboLabel
@onready var region_label: Label = $HUD/TopCenter/RegionLabel
@onready var notification_label: Label = $HUD/TopCenter/NotificationLabel
# Panels
@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var dialogue_name: Label = $DialoguePanel/VBox/NameLabel
@onready var dialogue_text: Label = $DialoguePanel/VBox/TextLabel
@onready var inventory_panel: PanelContainer = $InventoryPanel
@onready var inventory_grid: GridContainer = $InventoryPanel/VBox/ScrollContainer/Grid
@onready var quest_panel: PanelContainer = $QuestPanel
@onready var quest_list: VBoxContainer = $QuestPanel/VBox/ScrollContainer/QuestList
@onready var skill_panel: PanelContainer = $SkillPanel
@onready var skill_melee_list: VBoxContainer = $SkillPanel/HBox/MeleeTree/MeleeScroll/MeleeList
@onready var skill_magic_list: VBoxContainer = $SkillPanel/HBox/MagicTree/MagicScroll/MagicList
@onready var skill_points_label: Label = $SkillPanel/PointsLabel
@onready var shop_panel: PanelContainer = $ShopPanel
@onready var shop_grid: GridContainer = $ShopPanel/VBox/ScrollContainer/ShopGrid
@onready var death_panel: PanelContainer = $DeathPanel
@onready var pause_panel: PanelContainer = $PausePanel
@onready var tutorial_panel: PanelContainer = $TutorialPanel
@onready var tutorial_title: Label = $TutorialPanel/VBox/TitleLabel
@onready var tutorial_text: Label = $TutorialPanel/VBox/ContentLabel
@onready var map_panel: PanelContainer = $MapPanel

var region_label_timer: float = 0.0
var notification_timer: float = 0.0
var tutorial_timer: float = 0.0

func _ready() -> void:
	add_to_group("game_ui")
	process_mode = Node.PROCESS_MODE_ALWAYS
	_hide_all_panels()
	_connect_signals()
	_update_hud()

func _connect_signals() -> void:
	GameManager.player_leveled_up.connect(_on_level_up)
	GameManager.xp_gained.connect(_on_xp_gained)
	GameManager.gold_changed.connect(_on_gold_changed)
	GameManager.item_acquired.connect(_on_item_acquired)
	GameManager.player_died.connect(_on_player_died)
	GameManager.region_entered.connect(_on_region_entered)
	GameManager.boss_defeated.connect(_on_boss_defeated)
	QuestManager.quest_started.connect(_on_quest_started)
	QuestManager.quest_completed.connect(_on_quest_completed)
	QuestManager.quest_updated.connect(_on_quest_updated)
	TutorialManager.tutorial_shown.connect(_on_tutorial_shown)
	EventManager.event_triggered.connect(_on_event_triggered)
	# Player signals (connected when player exists)
	await get_tree().process_frame
	_connect_player()

func _connect_player() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		if player.has_signal("hp_changed"):
			player.hp_changed.connect(_on_hp_changed)
			player.stamina_changed.connect(_on_stamina_changed)
			player.mana_changed.connect(_on_mana_changed)
			player.combo_changed.connect(_on_combo_changed)
			player.weapon_changed.connect(_on_weapon_changed)
			player.spell_changed.connect(_on_spell_changed)

func _process(delta: float) -> void:
	# Region label fade
	if region_label_timer > 0:
		region_label_timer -= delta
		if region_label_timer <= 0 and region_label:
			region_label.visible = false
	# Notification fade
	if notification_timer > 0:
		notification_timer -= delta
		if notification_timer <= 0 and notification_label:
			notification_label.visible = false
	# Tutorial auto-hide
	if tutorial_timer > 0:
		tutorial_timer -= delta
		if tutorial_timer <= 0 and tutorial_panel:
			tutorial_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_toggle_pause()
	elif event.is_action_pressed("inventory"):
		_toggle_inventory()
	elif event.is_action_pressed("quest_log"):
		_toggle_quest_log()
	elif event.is_action_pressed("skill_tree"):
		_toggle_skill_tree()
	elif event.is_action_pressed("map"):
		_toggle_map()
	elif event.is_action_pressed("interact"):
		if dialogue_panel and dialogue_panel.visible:
			_advance_dialogue()
		if tutorial_panel and tutorial_panel.visible:
			tutorial_panel.visible = false
			tutorial_timer = 0
		if shop_panel and shop_panel.visible:
			pass  # Shop handles its own input

func _hide_all_panels() -> void:
	if dialogue_panel: dialogue_panel.visible = false
	if inventory_panel: inventory_panel.visible = false
	if quest_panel: quest_panel.visible = false
	if skill_panel: skill_panel.visible = false
	if shop_panel: shop_panel.visible = false
	if death_panel: death_panel.visible = false
	if pause_panel: pause_panel.visible = false
	if tutorial_panel: tutorial_panel.visible = false
	if map_panel: map_panel.visible = false
	if combo_label: combo_label.visible = false

func _update_hud() -> void:
	var ps = GameManager.player_stats
	if hp_bar:
		hp_bar.max_value = ps.max_hp
		hp_bar.value = ps.hp
	if stamina_bar:
		stamina_bar.max_value = ps.max_stamina
		stamina_bar.value = ps.stamina
	if mana_bar:
		mana_bar.max_value = ps.max_mana
		mana_bar.value = ps.mana
	if xp_bar:
		xp_bar.max_value = ps.xp_to_next
		xp_bar.value = ps.xp
	if level_label:
		level_label.text = "Lv. %d" % ps.level
	if gold_label:
		gold_label.text = "%d G" % ps.gold
	var weapon = GameManager.get_current_weapon()
	if weapon_label:
		weapon_label.text = weapon.get("name", "No Weapon") if not weapon.is_empty() else "No Weapon"
	var spell = GameManager.get_current_spell()
	if spell_label:
		spell_label.text = spell.get("name", "No Spell") if not spell.is_empty() else "No Spell"

# === HUD CALLBACKS ===
func _on_hp_changed(current: int, maximum: int) -> void:
	if hp_bar:
		hp_bar.max_value = maximum
		hp_bar.value = current

func _on_stamina_changed(current: float, maximum: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = maximum
		stamina_bar.value = current

func _on_mana_changed(current: int, maximum: int) -> void:
	if mana_bar:
		mana_bar.max_value = maximum
		mana_bar.value = current

func _on_combo_changed(count: int) -> void:
	if combo_label:
		if count >= 2:
			combo_label.visible = true
			combo_label.text = "COMBO x%d!" % count
		else:
			combo_label.visible = false

func _on_weapon_changed(weapon: Dictionary) -> void:
	if weapon_label:
		weapon_label.text = weapon.get("name", "No Weapon")

func _on_spell_changed(spell: Dictionary) -> void:
	if spell_label:
		spell_label.text = spell.get("name", "No Spell")

func _on_level_up(new_level: int) -> void:
	_show_notification("LEVEL UP! Now Level %d" % new_level)
	_update_hud()

func _on_xp_gained(amount: int) -> void:
	if xp_bar:
		xp_bar.value = GameManager.player_stats.xp

func _on_gold_changed(new_amount: int) -> void:
	if gold_label:
		gold_label.text = "%d G" % new_amount

func _on_item_acquired(item: Dictionary) -> void:
	_show_notification("Got: %s" % item.get("name", "Unknown"))

func _on_region_entered(region: String) -> void:
	_update_hud()

func _on_boss_defeated(boss_id: String) -> void:
	_show_notification("BOSS DEFEATED!")

func _on_quest_started(quest_id: String) -> void:
	var quest = QuestManager.player_quests.get(quest_id, {})
	_show_notification("Quest Started: %s" % quest.get("name", ""))

func _on_quest_completed(quest_id: String) -> void:
	var quest = QuestManager.player_quests.get(quest_id, {})
	_show_notification("Quest Complete: %s" % quest.get("name", ""))

func _on_quest_updated(quest_id: String, _obj: String) -> void:
	pass

func _on_tutorial_shown(tutorial_id: String) -> void:
	var data = TutorialManager.get_tutorial(tutorial_id)
	if data.is_empty():
		return
	if tutorial_panel:
		tutorial_panel.visible = true
		if tutorial_title:
			tutorial_title.text = data.get("title", "")
		if tutorial_text:
			tutorial_text.text = data.get("text", "")
		tutorial_timer = 6.0

func _on_event_triggered(event: Dictionary) -> void:
	_show_notification("Event: %s!" % event.get("name", "Unknown"))

func _on_player_died() -> void:
	if death_panel:
		death_panel.visible = true

# === DIALOGUE ===
func show_dialogue(speaker: String, text: String) -> void:
	if dialogue_panel:
		dialogue_panel.visible = true
		if dialogue_name: dialogue_name.text = speaker
		if dialogue_text: dialogue_text.text = text

func hide_dialogue() -> void:
	if dialogue_panel:
		dialogue_panel.visible = false

func _advance_dialogue() -> void:
	# The NPC handles advancing through its own interact method
	pass

# === SHOP ===
func show_shop(shop_name: String, items: Array[Dictionary]) -> void:
	if not shop_panel:
		return
	shop_panel.visible = true
	_populate_shop(shop_name, items)

func _populate_shop(_name: String, items: Array[Dictionary]) -> void:
	if not shop_grid:
		return
	for child in shop_grid.get_children():
		child.queue_free()
	for item in items:
		if item.is_empty():
			continue
		var btn = Button.new()
		btn.text = "%s - %d G" % [item.get("name", "???"), item.get("price", 0)]
		btn.custom_minimum_size = Vector2(200, 30)
		var item_copy = item.duplicate(true)
		btn.pressed.connect(func(): _buy_item(item_copy))
		shop_grid.add_child(btn)
	# Close button
	var close_btn = Button.new()
	close_btn.text = "Close Shop"
	close_btn.pressed.connect(func(): shop_panel.visible = false; GameManager.set_state(GameManager.GameState.PLAYING))
	shop_grid.add_child(close_btn)

func _buy_item(item: Dictionary) -> void:
	var price = item.get("price", 999999)
	if GameManager.spend_gold(price):
		match item.type:
			"weapon":
				GameManager.weapon_inventory.append(item)
			"spell":
				GameManager.spell_inventory.append(item)
			"armor", "accessory":
				GameManager.add_item(item)
			_:
				GameManager.add_item(item)
		_show_notification("Bought: %s" % item.get("name", ""))
	else:
		_show_notification("Not enough gold!")

# === INVENTORY ===
func _toggle_inventory() -> void:
	if not inventory_panel:
		return
	if inventory_panel.visible:
		inventory_panel.visible = false
		GameManager.set_state(GameManager.GameState.PLAYING)
	else:
		_hide_all_panels()
		inventory_panel.visible = true
		GameManager.set_state(GameManager.GameState.INVENTORY)
		_populate_inventory()

func _populate_inventory() -> void:
	if not inventory_grid:
		return
	for child in inventory_grid.get_children():
		child.queue_free()
	
	# Equipment section header
	var equip_header = Label.new()
	equip_header.text = "=== EQUIPPED ==="
	equip_header.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	inventory_grid.add_child(equip_header)
	
	# Weapon
	var weapon = GameManager.equipped.weapon
	var wbtn = Button.new()
	wbtn.text = "Weapon: %s" % (weapon.get("name", "None") if weapon else "None")
	wbtn.custom_minimum_size = Vector2(250, 28)
	inventory_grid.add_child(wbtn)
	
	# Armor
	var armor = GameManager.equipped.armor
	var abtn = Button.new()
	abtn.text = "Armor: %s" % (armor.get("name", "None") if armor else "None")
	abtn.custom_minimum_size = Vector2(250, 28)
	inventory_grid.add_child(abtn)
	
	# Accessory
	var acc = GameManager.equipped.accessory
	var accbtn = Button.new()
	accbtn.text = "Accessory: %s" % (acc.get("name", "None") if acc else "None")
	accbtn.custom_minimum_size = Vector2(250, 28)
	inventory_grid.add_child(accbtn)
	
	# Weapons list
	var wh = Label.new()
	wh.text = "=== WEAPONS ==="
	wh.add_theme_color_override("font_color", Color(0.8, 0.5, 0.3))
	inventory_grid.add_child(wh)
	for w in GameManager.weapon_inventory:
		var btn = Button.new()
		btn.text = "%s (DMG: %d)" % [w.get("name", "???"), w.get("damage", 0)]
		btn.custom_minimum_size = Vector2(250, 28)
		var wcopy = w
		btn.pressed.connect(func(): GameManager.equip_weapon(wcopy); _populate_inventory())
		inventory_grid.add_child(btn)
	
	# Spells list
	var sh = Label.new()
	sh.text = "=== SPELLS ==="
	sh.add_theme_color_override("font_color", Color(0.3, 0.5, 1.0))
	inventory_grid.add_child(sh)
	for s in GameManager.spell_inventory:
		var btn = Button.new()
		btn.text = "%s (DMG: %d, MP: %d)" % [s.get("name", "???"), s.get("damage", 0), s.get("mana_cost", 0)]
		btn.custom_minimum_size = Vector2(250, 28)
		var scopy = s
		btn.pressed.connect(func(): GameManager.equip_spell(scopy); _populate_inventory())
		inventory_grid.add_child(btn)
	
	# Items
	var ih = Label.new()
	ih.text = "=== ITEMS ==="
	ih.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	inventory_grid.add_child(ih)
	for item in GameManager.inventory:
		var btn = Button.new()
		var stack_text = " x%d" % item.stack if item.has("stack") else ""
		btn.text = "%s%s" % [item.get("name", "???"), stack_text]
		btn.custom_minimum_size = Vector2(250, 28)
		btn.add_theme_color_override("font_color", LootTable.get_rarity_color(item.get("rarity", "common")))
		var icopy = item
		if item.type == "consumable":
			btn.pressed.connect(func(): GameManager.use_consumable(icopy.id); _populate_inventory())
		elif item.type == "armor":
			btn.pressed.connect(func(): GameManager.equipped.armor = icopy; _populate_inventory())
		elif item.type == "accessory":
			btn.pressed.connect(func(): GameManager.equipped.accessory = icopy; _populate_inventory())
		inventory_grid.add_child(btn)

# === QUEST LOG ===
func _toggle_quest_log() -> void:
	if not quest_panel:
		return
	if quest_panel.visible:
		quest_panel.visible = false
		GameManager.set_state(GameManager.GameState.PLAYING)
	else:
		_hide_all_panels()
		quest_panel.visible = true
		GameManager.set_state(GameManager.GameState.PAUSED)
		_populate_quest_log()

func _populate_quest_log() -> void:
	if not quest_list:
		return
	for child in quest_list.get_children():
		child.queue_free()
	
	# Active quests
	var active_header = Label.new()
	active_header.text = "=== ACTIVE QUESTS ==="
	active_header.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	quest_list.add_child(active_header)
	
	var active = QuestManager.get_active_quests()
	if active.is_empty():
		var none_label = Label.new()
		none_label.text = "  No active quests"
		quest_list.add_child(none_label)
	for quest in active:
		var quest_label = Label.new()
		var type_tag = "[MAIN]" if quest.type == "main" else "[SIDE]"
		quest_label.text = "%s %s" % [type_tag, quest.get("name", "")]
		quest_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5) if quest.type == "main" else Color(0.7, 0.9, 0.7))
		quest_list.add_child(quest_label)
		
		var desc = Label.new()
		desc.text = "  %s" % quest.get("description", "")
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD
		desc.custom_minimum_size = Vector2(350, 0)
		quest_list.add_child(desc)
		
		for obj in quest.get("objectives", []):
			var obj_label = Label.new()
			var check = "[x]" if obj.current >= obj.count else "[ ]"
			obj_label.text = "  %s %s (%d/%d)" % [check, obj.description, obj.current, obj.count]
			obj_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5) if obj.current >= obj.count else Color(0.8, 0.8, 0.8))
			quest_list.add_child(obj_label)
	
	# Completed quests
	var completed_header = Label.new()
	completed_header.text = "\n=== COMPLETED ==="
	completed_header.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	quest_list.add_child(completed_header)
	
	var completed = QuestManager.get_completed_quests()
	for quest in completed:
		var ql = Label.new()
		ql.text = "  [DONE] %s" % quest.get("name", "")
		ql.add_theme_color_override("font_color", Color(0.4, 0.6, 0.4))
		quest_list.add_child(ql)

# === SKILL TREE ===
func _toggle_skill_tree() -> void:
	if not skill_panel:
		return
	if skill_panel.visible:
		skill_panel.visible = false
		GameManager.set_state(GameManager.GameState.PLAYING)
	else:
		_hide_all_panels()
		skill_panel.visible = true
		GameManager.set_state(GameManager.GameState.PAUSED)
		_populate_skill_tree()

func _populate_skill_tree() -> void:
	if skill_points_label:
		skill_points_label.text = "Skill Points: %d" % GameManager.player_stats.skill_points
	
	# Melee tree
	if skill_melee_list:
		for child in skill_melee_list.get_children():
			child.queue_free()
		for id in SkillManager.melee_skills:
			var skill = SkillManager.melee_skills[id]
			var btn = Button.new()
			btn.text = "%s (%d/%d) - Cost: %d SP" % [skill.name, skill.rank, skill.max_rank, skill.cost]
			btn.custom_minimum_size = Vector2(220, 28)
			if skill.rank >= skill.max_rank:
				btn.text += " [MAX]"
				btn.disabled = true
			var skill_id = id
			btn.pressed.connect(func(): SkillManager.unlock_skill("melee", skill_id); _populate_skill_tree())
			skill_melee_list.add_child(btn)
			var desc = Label.new()
			desc.text = "  %s" % skill.description
			desc.add_theme_font_size_override("font_size", 11)
			skill_melee_list.add_child(desc)
	
	# Magic tree
	if skill_magic_list:
		for child in skill_magic_list.get_children():
			child.queue_free()
		for id in SkillManager.magic_skills:
			var skill = SkillManager.magic_skills[id]
			var btn = Button.new()
			btn.text = "%s (%d/%d) - Cost: %d SP" % [skill.name, skill.rank, skill.max_rank, skill.cost]
			btn.custom_minimum_size = Vector2(220, 28)
			if skill.rank >= skill.max_rank:
				btn.text += " [MAX]"
				btn.disabled = true
			var skill_id = id
			btn.pressed.connect(func(): SkillManager.unlock_skill("magic", skill_id); _populate_skill_tree())
			skill_magic_list.add_child(btn)
			var desc = Label.new()
			desc.text = "  %s" % skill.description
			desc.add_theme_font_size_override("font_size", 11)
			skill_magic_list.add_child(desc)

# === MAP ===
func _toggle_map() -> void:
	if not map_panel:
		return
	map_panel.visible = not map_panel.visible
	if map_panel.visible:
		GameManager.set_state(GameManager.GameState.PAUSED)
	else:
		GameManager.set_state(GameManager.GameState.PLAYING)

# === PAUSE ===
func _toggle_pause() -> void:
	if GameManager.current_state == GameManager.GameState.DEAD:
		return
	if pause_panel:
		if pause_panel.visible:
			pause_panel.visible = false
			GameManager.set_state(GameManager.GameState.PLAYING)
		else:
			_hide_all_panels()
			pause_panel.visible = true
			GameManager.set_state(GameManager.GameState.PAUSED)

# === NOTIFICATIONS ===
func show_region_name(name: String) -> void:
	if region_label:
		region_label.text = name
		region_label.visible = true
		region_label_timer = 3.0

func _show_notification(text: String) -> void:
	if notification_label:
		notification_label.text = text
		notification_label.visible = true
		notification_timer = 3.0

# === PAUSE MENU BUTTONS ===
func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_save_pressed() -> void:
	SaveManager.save_game(0)
	_show_notification("Game Saved!")

func _on_load_pressed() -> void:
	if SaveManager.has_save(0):
		SaveManager.load_game(0)
		_show_notification("Game Loaded!")
		pause_panel.visible = false
		GameManager.set_state(GameManager.GameState.PLAYING)
		_update_hud()

func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")

# === DEATH SCREEN ===
func _on_respawn_pressed() -> void:
	if death_panel:
		death_panel.visible = false
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		players[0].respawn(Vector2(0, 0))

func _on_death_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/menus/main_menu.tscn")
