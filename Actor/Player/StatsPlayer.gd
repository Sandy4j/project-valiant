extends Node
class_name PlayerStats

signal hp_changed(value)
signal mana_changed(value)
signal stamina_changed(value)
signal exp_changed(value)
signal level_up(new_level)
signal curse_applied(curse_value)
signal curse_lifted
signal Pdied

var level: int = 1
var base_max_hp: int = 100
var current_hp: int
var max_hp: int
var current_mana: int
var max_mana: int = 50
var current_exp: int = 0
var max_exp: int = 100
var curse_value: int = 0
var max_curse_percentage: float = 0.5
var move_speed: float = 5.0

var physical_atk: int = 10
var physical_defense: int = 5
var magical_atk: int = 10
var magical_defense: int = 5
var crit_damage: float = 1.5
var crit_chance: float = 0.1
var max_stamina: int = 100
var current_stamina: int
var stamina_regen: float = 0.5
var mana_regen: float = 0.25
var hp_regen: float = 0.1
var physical_penetration: float = 0.0
var magical_penetration: float = 0.0

var rpg_stats: RPGStats

func _init():
	rpg_stats = RPGStats.new()
	rpg_stats.connect("stat_changed", Callable (self, "_on_rpg_stat_changed"))

func _ready():
	reset_stats()
	

func _process(delta):
	regenerate_hp(delta)
	regenerate_mana(delta)
	regenerate_stamina(delta)

func reset_stats():
	update_derived_stats()
	current_hp = max_hp
	current_mana = max_mana
	current_stamina = max_stamina
	emit_signal("hp_changed", current_hp)
	emit_signal("mana_changed", current_mana)
	emit_signal("stamina_changed", current_stamina)

func update_derived_stats():
	physical_atk = 10 + rpg_stats.get_physical_atk_bonus()
	physical_defense = 5 + rpg_stats.get_physical_def_bonus()
	magical_atk = 10 + rpg_stats.get_magical_atk_bonus()
	magical_defense = 5 + rpg_stats.get_magical_def_bonus()
	max_mana = 50 + rpg_stats.get_max_mana_bonus()
	mana_regen = 0.25 + rpg_stats.get_mana_regen_bonus()
	crit_damage = 1.5 + rpg_stats.get_crit_damage_bonus()
	move_speed = 5.0 + rpg_stats.get_move_speed_bonus()
	max_stamina = 100 + rpg_stats.get_max_stamina_bonus()
	stamina_regen = 0.5 + rpg_stats.get_stamina_regen_bonus()
	max_hp = base_max_hp + rpg_stats.get_max_hp_bonus() - curse_value
	hp_regen = 0.1 + rpg_stats.get_hp_regen_bonus()
	crit_chance = 0.1 + rpg_stats.get_crit_chance_bonus()
	physical_penetration = rpg_stats.get_physical_penetration()
	magical_penetration = rpg_stats.get_magical_penetration()

func _on_rpg_stat_changed(_stat_name, _new_value):
	update_derived_stats()

func take_damage(amount: int):
	current_hp = max(0, current_hp - amount)
	emit_signal("hp_changed", current_hp)
	if current_hp == 0:
		die()

func die():
	apply_curse()
	reset_stats()
	emit_signal("Pdied")
	get_parent().respawn()

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
	
func use_stamina(amount: int) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		emit_signal("stamina_changed", current_stamina)
		return true
	return false

func restore_stamina(amount: int):
	current_stamina = min(max_stamina, current_stamina + amount)
	emit_signal("stamina_changed", current_stamina)

func regenerate_hp(delta: float):
	var regen_amount = hp_regen * delta
	current_hp = min(max_hp, current_hp + regen_amount)
	emit_signal("hp_changed", current_hp)

func regenerate_mana(delta: float):
	var regen_amount = mana_regen * delta
	current_mana = min(max_mana, current_mana + regen_amount)
	emit_signal("mana_changed", current_mana)

func regenerate_stamina(delta: float):
	var regen_amount = stamina_regen * delta
	current_stamina = min(max_stamina, current_stamina + regen_amount)
	emit_signal("stamina_changed", current_stamina)


func gain_exp(amount: int):
	current_exp += amount
	emit_signal("exp_changed", current_exp)
	
	while current_exp >= max_exp:
		levelup()

func levelup():
	level += 1
	current_exp -= max_exp
	max_exp = int(max_exp * 1.5)  # Increase max_exp by 50% each level
	emit_signal("level_up", level)
	emit_signal("exp_changed", current_exp)
	
	reset_stats()

func apply_curse():
	var new_curse = int(base_max_hp * 0.1)  # 10% of base max HP
	var max_curse = int(base_max_hp * max_curse_percentage)
	curse_value = min(curse_value + new_curse, max_curse)
	emit_signal("curse_applied", curse_value)

func lift_curse():
	curse_value = 0
	reset_stats()
	emit_signal("curse_lifted")

func get_stats() -> Dictionary:
	var stats = {
		"level": level,
		"hp": current_hp,
		"max_hp": max_hp,
		"mana": current_mana,
		"max_mana": max_mana,
		"stamina": current_stamina,
		"max_stamina": max_stamina,
		"exp": current_exp,
		"max_exp": max_exp,
		"curse": curse_value,
		"physical_atk": physical_atk,
		"physical_defense": physical_defense,
		"magical_atk": magical_atk,
		"magical_defense": magical_defense,
		"crit_damage": crit_damage,
		"crit_chance": crit_chance,
		"move_speed": move_speed,
		"stamina_regen": stamina_regen,
		"mana_regen": mana_regen,
		"hp_regen": hp_regen,
		"physical_penetration": physical_penetration,
		"magical_penetration": magical_penetration
	}
	stats.merge(rpg_stats.get_stats())
	return stats
