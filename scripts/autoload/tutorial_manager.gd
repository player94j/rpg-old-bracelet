extends Node
## TutorialManager - Shows contextual tutorial popups

signal tutorial_shown(tutorial_id: String)

var tutorials: Dictionary = {
	"movement": {"title": "Movement", "text": "Use WASD or Left Stick to move.\nJohn the Baptist roams the wastes..."},
	"combat": {"title": "Combat", "text": "Left Click / X = Light Attack\nRight Click / Y = Heavy Attack\nCombo: Light > Light > Heavy for a finisher!"},
	"dodge": {"title": "Dodge", "text": "Space / A to dodge roll.\nYou have i-frames during the roll.\nCosts stamina!"},
	"magic": {"title": "Magic", "text": "Q / LB to cast your equipped spell.\nR / RB to cycle spells.\nSpells cost Mana."},
	"interact": {"title": "Interact", "text": "Press E / B near NPCs or objects\nto interact with them."},
	"inventory": {"title": "Inventory", "text": "Press I / Back to open inventory.\nEquip weapons and armor.\nUse consumable items."},
	"quest": {"title": "Quests", "text": "Press J / Select to view quest log.\nTrack objectives and rewards."},
	"skills": {"title": "Skill Tree", "text": "Press K to open the Skill Tree.\nSpend skill points to unlock\nmelee and magic abilities."},
	"boss": {"title": "Boss Fight!", "text": "A powerful enemy blocks your path!\nWatch for phase changes.\nLearn attack patterns to survive."},
	"ng_plus": {"title": "New Game+", "text": "Enemies are stronger but you keep\nyour gear and levels.\nNew variations await!"},
}

func show_tutorial(tutorial_id: String) -> void:
	if GameManager.tutorials_shown.has(tutorial_id):
		return
	if not tutorials.has(tutorial_id):
		return
	GameManager.tutorials_shown[tutorial_id] = true
	tutorial_shown.emit(tutorial_id)

func get_tutorial(tutorial_id: String) -> Dictionary:
	return tutorials.get(tutorial_id, {})
