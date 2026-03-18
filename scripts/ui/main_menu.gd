extends Control
## Main Menu - Title screen with New Game, Continue, Options, Quit

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $VBoxContainer/SubtitleLabel
@onready var new_game_btn: Button = $VBoxContainer/ButtonContainer/NewGameBtn
@onready var continue_btn: Button = $VBoxContainer/ButtonContainer/ContinueBtn
@onready var ng_plus_btn: Button = $VBoxContainer/ButtonContainer/NGPlusBtn
@onready var load_panel: PanelContainer = $LoadPanel
@onready var slot_container: VBoxContainer = $LoadPanel/VBox/SlotContainer

func _ready() -> void:
	GameManager.set_state(GameManager.GameState.MENU)
	get_tree().paused = false
	if continue_btn:
		continue_btn.disabled = not _any_save_exists()
	if ng_plus_btn:
		ng_plus_btn.visible = _has_completed_game()
	if load_panel:
		load_panel.visible = false

func _any_save_exists() -> bool:
	for i in range(SaveManager.MAX_SLOTS):
		if SaveManager.has_save(i):
			return true
	return false

func _has_completed_game() -> bool:
	# Check if any save has completed the final boss
	for i in range(SaveManager.MAX_SLOTS):
		var info = SaveManager.get_save_info(i)
		if info.get("ng_plus", 0) > 0:
			return true
	return false

func _on_new_game_btn_pressed() -> void:
	GameManager.start_new_game()
	get_tree().change_scene_to_file("res://scenes/world/game_world.tscn")

func _on_continue_btn_pressed() -> void:
	if load_panel:
		load_panel.visible = true
		_populate_save_slots()

func _on_ng_plus_btn_pressed() -> void:
	# Load most recent save and start NG+
	for i in range(SaveManager.MAX_SLOTS):
		if SaveManager.has_save(i):
			SaveManager.load_game(i)
			GameManager.start_new_game_plus()
			get_tree().change_scene_to_file("res://scenes/world/game_world.tscn")
			return

func _on_quit_btn_pressed() -> void:
	get_tree().quit()

func _populate_save_slots() -> void:
	if not slot_container:
		return
	for child in slot_container.get_children():
		child.queue_free()
	for i in range(SaveManager.MAX_SLOTS):
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(300, 40)
		if SaveManager.has_save(i):
			var info = SaveManager.get_save_info(i)
			var time_str = "%02d:%02d" % [int(info.get("play_time", 0)) / 3600, (int(info.get("play_time", 0)) % 3600) / 60]
			var ng_str = " [NG+%d]" % info.get("ng_plus", 0) if info.get("ng_plus", 0) > 0 else ""
			btn.text = "Slot %d: Lv.%d | %s | %s%s" % [i + 1, info.get("level", 1), info.get("region", "???"), time_str, ng_str]
			var slot = i
			btn.pressed.connect(func(): _load_slot(slot))
		else:
			btn.text = "Slot %d: Empty" % (i + 1)
			btn.disabled = true
		slot_container.add_child(btn)
	# Close button
	var close = Button.new()
	close.text = "Back"
	close.custom_minimum_size = Vector2(300, 35)
	close.pressed.connect(func(): load_panel.visible = false)
	slot_container.add_child(close)

func _load_slot(slot: int) -> void:
	if SaveManager.load_game(slot):
		get_tree().change_scene_to_file("res://scenes/world/game_world.tscn")
