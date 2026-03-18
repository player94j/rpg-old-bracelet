extends Node
## TutorialManager - Shows contextual tutorial popups
## Supports a guided intro sequence that plays before enemies activate

signal tutorial_shown(tutorial_id: String)
signal intro_tutorial_complete

var tutorials: Dictionary = {
	"welcome": {"title": "Welcome, John the Baptist", "text": "You awaken in the Ashen Wastes.\nA dark power stirs across the land.\nYou must rise and face the coming evil.\n\n[E] or click to continue"},
	"movement": {"title": "Movement", "text": "WASD / Left Stick = Move\nYour character faces the direction you move.\nExplore the world around you!\n\nKeyboard & Xbox controller supported."},
	"combat": {"title": "Combat", "text": "Left Click / X = Light Attack\nRight Click / Y = Heavy Attack\nCombo: Light > Light > Heavy for a finisher!\nAttacks cost Stamina (green bar)."},
	"dodge": {"title": "Dodge Roll", "text": "Space / A = Dodge roll\nYou are INVULNERABLE during the roll!\nCosts 20 Stamina. Use to evade attacks.\nCooldown: 0.5 seconds."},
	"magic": {"title": "Magic Spells", "text": "Q / LB = Cast your equipped spell\nR / RB = Cycle between spells\nSpells cost Mana (blue bar).\nFind new spells from vendors and loot!"},
	"interact": {"title": "Interact", "text": "Press E / B near NPCs or objects\nto talk, trade, or pick up items.\nLook for the [E] prompt indicator."},
	"inventory": {"title": "Inventory", "text": "Press I / Back to open inventory.\nEquip weapons and armor.\nUse consumable items like potions.\nGear improves your stats!"},
	"quest": {"title": "Quest Log", "text": "Press J / Select to view quest log.\nTrack objectives and quest progress.\nMain quests advance the story.\nSide quests give extra rewards!"},
	"skills": {"title": "Skill Tree", "text": "Press K to open the Skill Tree.\nSpend skill points (earned on level up)\nto unlock melee and magic abilities.\nSome skills have prerequisites."},
	"boss": {"title": "Boss Fight!", "text": "A powerful enemy blocks your path!\nBosses have multiple phases.\nWatch for phase changes at HP thresholds.\nLearn attack patterns to survive!"},
	"ng_plus": {"title": "New Game+", "text": "Enemies are 35% stronger per cycle\nbut you keep your gear and levels.\nNew boss attack patterns appear.\nHow far can you go?"},
	"controls_summary": {"title": "Controls Overview", "text": "T = Cycle Weapon | F = Use Item\nM = World Map | ESC = Pause Menu\nI = Inventory | J = Quests | K = Skills\n\nAll actions have Xbox controller bindings!"},
}

# Intro tutorial sequence - shown at game start
var intro_sequence: Array[String] = ["welcome", "movement", "controls_summary"]
var intro_active: bool = false
var intro_step: int = 0

func show_tutorial(tutorial_id: String) -> void:
	if GameManager.tutorials_shown.has(tutorial_id):
		return
	if not tutorials.has(tutorial_id):
		return
	GameManager.tutorials_shown[tutorial_id] = true
	AudioManager.play_sfx("tutorial_popup")
	tutorial_shown.emit(tutorial_id)

func get_tutorial(tutorial_id: String) -> Dictionary:
	return tutorials.get(tutorial_id, {})

func start_intro_sequence() -> void:
	if GameManager.tutorials_shown.has("welcome"):
		intro_tutorial_complete.emit()
		return
	intro_active = true
	intro_step = 0
	_show_intro_step()

func _show_intro_step() -> void:
	if intro_step >= intro_sequence.size():
		intro_active = false
		intro_tutorial_complete.emit()
		return
	var tid = intro_sequence[intro_step]
	GameManager.tutorials_shown[tid] = true
	AudioManager.play_sfx("tutorial_popup")
	tutorial_shown.emit(tid)

func advance_intro() -> void:
	if not intro_active:
		return
	intro_step += 1
	_show_intro_step()

func is_intro_active() -> bool:
	return intro_active
