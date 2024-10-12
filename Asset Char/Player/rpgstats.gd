extends Node
class_name RPGStats

signal stat_changed(stat_name, new_value)

var strength: int = 10:
	set(value):
		strength = value
		stat_changed.emit("strength", strength)

var intelligence: int = 10:
	set(value):
		intelligence = value
		stat_changed.emit("intelligence", intelligence)

var dexterity: int = 10:
	set(value):
		dexterity = value
		stat_changed.emit("dexterity", dexterity)

var agility: int = 10:
	set(value):
		agility = value
		stat_changed.emit("agility", agility)

var endurance: int = 10:
	set(value):
		endurance = value
		stat_changed.emit("endurance", endurance)

var luck: int = 10:
	set(value):
		luck = value
		stat_changed.emit("luck", luck)

var vitality: int = 10:
	set(value):
		vitality = value
		stat_changed.emit("vitality", vitality)

func get_physical_atk_bonus() -> int:
	return strength * 2 + dexterity

func get_physical_def_bonus() -> int:
	return strength + int(endurance * 0.5)

func get_magical_atk_bonus() -> int:
	return intelligence * 2

func get_magical_def_bonus() -> int:
	return int(intelligence * 0.3) + int(endurance * 0.7)

func get_max_mana_bonus() -> int:
	return intelligence * 5

func get_mana_regen_bonus() -> float:
	return intelligence * 0.01

func get_crit_damage_bonus() -> float:
	return dexterity * 0.01

func get_move_speed_bonus() -> float:
	return agility * 0.5

func get_max_stamina_bonus() -> int:
	return endurance * 2

func get_stamina_regen_bonus() -> float:
	return agility * 0.01

func get_max_hp_bonus() -> int:
	return vitality * 5

func get_hp_regen_bonus() -> float:
	return vitality * 0.002

func get_crit_chance_bonus() -> float:
	return luck * 0.002

func get_physical_penetration() -> float:
	return dexterity * 0.5

func get_magical_penetration() -> float:
	return intelligence * 0.5

func get_stats() -> Dictionary:
	return {
		"strength": strength,
		"intelligence": intelligence,
		"dexterity": dexterity,
		"agility": agility,
		"endurance": endurance,
		"luck": luck,
		"vitality": vitality,
		"physical_penetration": get_physical_penetration(),
		"magical_penetration": get_magical_penetration()
	}
