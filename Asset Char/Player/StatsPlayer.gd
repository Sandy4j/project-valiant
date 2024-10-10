extends Node

class_name PlayerStats

signal hp_changed(value)
signal mana_changed(value)
signal exp_changed(value)
signal level_up(new_level)
signal debuff_applied(debuff_value)
signal debuff_healed
signal player_died

var level: int = 1
var base_max_hp: int = 100
var current_hp: int
var max_hp: int
var current_mana: int
var max_mana: int = 50
var current_exp: int = 0
var max_exp: int = 100

var debuff_value: int = 0
var max_debuff_percentage: float = 0.5  # 50% max debuff

func _ready():
	reset_stats()

func reset_stats():
	max_hp = base_max_hp - debuff_value
	current_hp = max_hp
	current_mana = max_mana
	emit_signal("hp_changed", current_hp)
	emit_signal("mana_changed", current_mana)

func take_damage(amount: int):
	current_hp = max(0, current_hp - amount)
	emit_signal("hp_changed", current_hp)
	if current_hp == 0:
		apply_debuff()
		reset_stats()
		emit_signal("player_died")

func apply_debuff():
	print("applied buff")
	var new_debuff = int(base_max_hp * 0.1)  # 10% of base max HP
	var max_debuff = int(base_max_hp * max_debuff_percentage)
	debuff_value = min(debuff_value + new_debuff, max_debuff)
	emit_signal("debuff_applied", debuff_value)

func heal_debuff():
	debuff_value = 0
	reset_stats()
	emit_signal("debuff_healed")

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)
	emit_signal("hp_changed", current_hp)

func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		emit_signal("mana_changed", current_mana)
		return true
	return false

func restore_mana(amount: int):
	current_mana = min(max_mana, current_mana + amount)
	emit_signal("mana_changed", current_mana)

func gain_exp(amount: int):
	current_exp += amount
	emit_signal("exp_changed", current_exp)
	
	while current_exp >= max_exp:
		levelup()

func levelup():
	level += 1
	current_exp -= max_exp
	max_exp = int(max_exp * 1.5)  # Increase max_exp by 50% each level
	
	base_max_hp += 10
	max_mana += 5
	
	reset_stats()
	
	emit_signal("level_up", level)

func get_stats() -> Dictionary:
	return {
		"level": level,
		"hp": current_hp,
		"max_hp": max_hp,
		"mana": current_mana,
		"max_mana": max_mana,
		"exp": current_exp,
		"max_exp": max_exp,
		"debuff": debuff_value
	}
