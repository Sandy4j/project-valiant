extends Node
# Singleton instance
var player_stats_data: Dictionary = {}
var rpg_stats_data: Dictionary = {}

func save_player_stats(stats: PlayerStats):
	player_stats_data = {
		"level": stats.level,
		"base_max_hp": stats.base_max_hp,
		"current_hp": stats.current_hp,
		"max_hp": stats.max_hp,
		"current_mana": stats.current_mana,
		"max_mana": stats.max_mana,
		"current_exp": stats.current_exp,
		"max_exp": stats.max_exp,
		"curse_value": stats.curse_value,
		"move_speed": stats.move_speed,
		"physical_atk": stats.physical_atk,
		"physical_defense": stats.physical_defense,
		"magical_atk": stats.magical_atk,
		"magical_defense": stats.magical_defense,
		"crit_damage": stats.crit_damage,
		"crit_chance": stats.crit_chance,
		"max_stamina": stats.max_stamina,
		"current_stamina": stats.current_stamina,
		"stamina_regen": stats.stamina_regen,
		"mana_regen": stats.mana_regen,
		"hp_regen": stats.hp_regen,
		"physical_penetration": stats.physical_penetration,
		"magical_penetration": stats.magical_penetration
	}

func save_rpg_stats(stats: RPGstats):
	rpg_stats_data = {
		"strength": stats.strength,
		"intelligence": stats.intelligence,
		"dexterity": stats.dexterity,
		"agility": stats.agility,
		"endurance": stats.endurance,
		"luck": stats.luck,
		"vitality": stats.vitality
	}

func load_player_stats(stats: PlayerStats):
	if !player_stats_data.is_empty():
		stats.level = player_stats_data["level"]
		stats.base_max_hp = player_stats_data["base_max_hp"]
		stats.current_hp = player_stats_data["current_hp"]
		stats.max_hp = player_stats_data["max_hp"]
		stats.current_mana = player_stats_data["current_mana"]
		stats.max_mana = player_stats_data["max_mana"]
		stats.current_exp = player_stats_data["current_exp"]
		stats.max_exp = player_stats_data["max_exp"]
		stats.curse_value = player_stats_data["curse_value"]
		stats.move_speed = player_stats_data["move_speed"]
		stats.physical_atk = player_stats_data["physical_atk"]
		stats.physical_defense = player_stats_data["physical_defense"]
		stats.magical_atk = player_stats_data["magical_atk"]
		stats.magical_defense = player_stats_data["magical_defense"]
		stats.crit_damage = player_stats_data["crit_damage"]
		stats.crit_chance = player_stats_data["crit_chance"]
		stats.max_stamina = player_stats_data["max_stamina"]
		stats.current_stamina = player_stats_data["current_stamina"]
		stats.stamina_regen = player_stats_data["stamina_regen"]
		stats.mana_regen = player_stats_data["mana_regen"]
		stats.hp_regen = player_stats_data["hp_regen"]
		stats.physical_penetration = player_stats_data["physical_penetration"]
		stats.magical_penetration = player_stats_data["magical_penetration"]

func load_rpg_stats(stats: RPGstats):
	if !rpg_stats_data.is_empty():
		stats.strength = rpg_stats_data["strength"]
		stats.intelligence = rpg_stats_data["intelligence"]
		stats.dexterity = rpg_stats_data["dexterity"]
		stats.agility = rpg_stats_data["agility"]
		stats.endurance = rpg_stats_data["endurance"]
		stats.luck = rpg_stats_data["luck"]
		stats.vitality = rpg_stats_data["vitality"]

func clear_data():
	player_stats_data.clear()
	rpg_stats_data.clear()
