# Weapon.gd
class_name Weapon

var weapon_name: String
var damage: int
var attack_speed: float
var attack_range: float
var combo_damages: Array[int]
var combo_count: int = 0
var combo_timer: float = 0.0
var combo_timeout: float = 1.0
var attack_cooldown: float = 0.0

func _init():
	pass

func attack() -> int:
	if attack_cooldown <= 0:
		var damage = combo_damages[combo_count]
		combo_count = (combo_count + 1) % combo_damages.size()
		combo_timer = combo_timeout
		attack_cooldown = 1.0 / attack_speed
		return damage
	return 0

func update(delta: float):
	combo_timer -= delta
	attack_cooldown -= delta
	if combo_timer <= 0:
		combo_count = 0
