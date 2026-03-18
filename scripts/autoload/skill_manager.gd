extends Node
## SkillManager - Skill trees for melee and magic builds

signal skill_unlocked(skill_id: String)
signal skill_points_changed(points: int)

# Skill tree data
var melee_skills: Dictionary = {
	"power_strike": {"name": "Power Strike", "description": "+15% melee damage", "cost": 1, "max_rank": 3, "rank": 0, "requires": [], "bonus": {"melee_damage_mult": 0.15}},
	"swift_blade": {"name": "Swift Blade", "description": "+10% attack speed", "cost": 1, "max_rank": 3, "rank": 0, "requires": [], "bonus": {"attack_speed_mult": 0.10}},
	"iron_skin": {"name": "Iron Skin", "description": "+8% damage reduction", "cost": 1, "max_rank": 3, "rank": 0, "requires": [], "bonus": {"damage_reduction": 0.08}},
	"combo_master": {"name": "Combo Master", "description": "+20% combo damage", "cost": 2, "max_rank": 2, "rank": 0, "requires": ["power_strike"], "bonus": {"combo_damage_mult": 0.20}},
	"stamina_surge": {"name": "Stamina Surge", "description": "+15% stamina regen", "cost": 1, "max_rank": 3, "rank": 0, "requires": [], "bonus": {"stamina_regen_mult": 0.15}},
	"berserker": {"name": "Berserker", "description": "+25% dmg when HP < 30%", "cost": 3, "max_rank": 1, "rank": 0, "requires": ["power_strike", "combo_master"], "bonus": {"low_hp_damage": 0.25}},
	"whirlwind": {"name": "Whirlwind", "description": "Unlocks spin attack (Heavy while moving)", "cost": 2, "max_rank": 1, "rank": 0, "requires": ["swift_blade"], "bonus": {"unlock_whirlwind": true}},
	"life_steal": {"name": "Life Steal", "description": "Heal 5% of melee damage dealt", "cost": 3, "max_rank": 1, "rank": 0, "requires": ["berserker"], "bonus": {"life_steal": 0.05}},
}

var magic_skills: Dictionary = {
	"arcane_power": {"name": "Arcane Power", "description": "+15% spell damage", "cost": 1, "max_rank": 3, "rank": 0, "requires": [], "bonus": {"spell_damage_mult": 0.15}},
	"mana_well": {"name": "Mana Well", "description": "+20 max mana", "cost": 1, "max_rank": 3, "rank": 0, "requires": [], "bonus": {"max_mana_flat": 20}},
	"quick_cast": {"name": "Quick Cast", "description": "-10% spell cooldown", "cost": 1, "max_rank": 3, "rank": 0, "requires": [], "bonus": {"cooldown_reduction": 0.10}},
	"spell_mastery": {"name": "Spell Mastery", "description": "-15% mana cost", "cost": 2, "max_rank": 2, "rank": 0, "requires": ["arcane_power"], "bonus": {"mana_cost_reduction": 0.15}},
	"mana_regen": {"name": "Mana Regeneration", "description": "+15% mana regen", "cost": 1, "max_rank": 3, "rank": 0, "requires": [], "bonus": {"mana_regen_mult": 0.15}},
	"elemental_fury": {"name": "Elemental Fury", "description": "+30% area spell damage", "cost": 3, "max_rank": 1, "rank": 0, "requires": ["arcane_power", "spell_mastery"], "bonus": {"area_spell_mult": 0.30}},
	"chain_lightning": {"name": "Chain Lightning", "description": "Projectiles can hit 2 extra targets", "cost": 2, "max_rank": 1, "rank": 0, "requires": ["quick_cast"], "bonus": {"chain_targets": 2}},
	"divine_grace": {"name": "Divine Grace", "description": "Spells heal 10% of damage dealt", "cost": 3, "max_rank": 1, "rank": 0, "requires": ["elemental_fury"], "bonus": {"spell_heal": 0.10}},
}

func unlock_skill(tree: String, skill_id: String) -> bool:
	var skills = melee_skills if tree == "melee" else magic_skills
	if not skills.has(skill_id):
		return false
	var skill = skills[skill_id]
	if skill.rank >= skill.max_rank:
		return false
	if GameManager.player_stats.skill_points < skill.cost:
		return false
	# Check prerequisites
	for req in skill.requires:
		if skills[req].rank <= 0:
			return false
	skill.rank += 1
	GameManager.player_stats.skill_points -= skill.cost
	_apply_skill_bonus(skill)
	skill_unlocked.emit(skill_id)
	skill_points_changed.emit(GameManager.player_stats.skill_points)
	return true

func _apply_skill_bonus(skill: Dictionary) -> void:
	var bonus = skill.bonus
	if bonus.has("max_mana_flat"):
		GameManager.player_stats.max_mana += int(bonus.max_mana_flat)
		GameManager.player_stats.mana = mini(GameManager.player_stats.mana + int(bonus.max_mana_flat), GameManager.player_stats.max_mana)

func get_melee_damage_multiplier() -> float:
	var mult = 1.0
	mult += melee_skills.power_strike.rank * melee_skills.power_strike.bonus.melee_damage_mult
	mult += melee_skills.combo_master.rank * melee_skills.combo_master.bonus.combo_damage_mult
	if melee_skills.berserker.rank > 0:
		var hp_pct = float(GameManager.player_stats.hp) / float(GameManager.player_stats.max_hp)
		if hp_pct < 0.3:
			mult += melee_skills.berserker.bonus.low_hp_damage
	return mult

func get_attack_speed_multiplier() -> float:
	return 1.0 + melee_skills.swift_blade.rank * melee_skills.swift_blade.bonus.attack_speed_mult

func get_damage_reduction() -> float:
	return melee_skills.iron_skin.rank * melee_skills.iron_skin.bonus.damage_reduction

func get_stamina_regen_multiplier() -> float:
	return 1.0 + melee_skills.stamina_surge.rank * melee_skills.stamina_surge.bonus.stamina_regen_mult

func get_spell_damage_multiplier() -> float:
	var mult = 1.0
	mult += magic_skills.arcane_power.rank * magic_skills.arcane_power.bonus.spell_damage_mult
	return mult

func get_area_spell_multiplier() -> float:
	return 1.0 + magic_skills.elemental_fury.rank * magic_skills.elemental_fury.bonus.area_spell_mult

func get_cooldown_reduction() -> float:
	return magic_skills.quick_cast.rank * magic_skills.quick_cast.bonus.cooldown_reduction

func get_mana_cost_multiplier() -> float:
	return 1.0 - magic_skills.spell_mastery.rank * magic_skills.spell_mastery.bonus.mana_cost_reduction

func get_mana_regen_multiplier() -> float:
	return 1.0 + magic_skills.mana_regen.rank * magic_skills.mana_regen.bonus.mana_regen_mult

func has_whirlwind() -> bool:
	return melee_skills.whirlwind.rank > 0

func get_life_steal() -> float:
	if melee_skills.life_steal.rank > 0:
		return melee_skills.life_steal.bonus.life_steal
	return 0.0

func get_spell_heal() -> float:
	if magic_skills.divine_grace.rank > 0:
		return magic_skills.divine_grace.bonus.spell_heal
	return 0.0

func get_chain_targets() -> int:
	if magic_skills.chain_lightning.rank > 0:
		return magic_skills.chain_lightning.bonus.chain_targets
	return 0

func get_save_data() -> Dictionary:
	var melee_ranks = {}
	for id in melee_skills:
		melee_ranks[id] = melee_skills[id].rank
	var magic_ranks = {}
	for id in magic_skills:
		magic_ranks[id] = magic_skills[id].rank
	return {"melee_ranks": melee_ranks, "magic_ranks": magic_ranks}

func load_save_data(data: Dictionary) -> void:
	var melee_ranks = data.get("melee_ranks", {})
	for id in melee_ranks:
		if melee_skills.has(id):
			melee_skills[id].rank = melee_ranks[id]
	var magic_ranks = data.get("magic_ranks", {})
	for id in magic_ranks:
		if magic_skills.has(id):
			magic_skills[id].rank = magic_ranks[id]

func reset_skills() -> void:
	for id in melee_skills:
		melee_skills[id].rank = 0
	for id in magic_skills:
		magic_skills[id].rank = 0
