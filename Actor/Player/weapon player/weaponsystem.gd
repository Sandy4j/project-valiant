extends Node

class_name WeaponSystem

var current_weapon: Weapon
var weapons: Array[Weapon] = []

signal weapon_switched(new_weapon: Weapon)

func _ready():
	# Initialize weapons
	var sword = Sword.new()
	var spear = Spear.new()
	weapons = [sword, spear]
	current_weapon = weapons[0]

func switch_weapon():
	var current_index = weapons.find(current_weapon)
	var next_index = (current_index + 1) % weapons.size()
	current_weapon = weapons[next_index]
	print("Switched to " + current_weapon.weapon_name)
	emit_signal("weapon_switched", current_weapon)

func get_current_weapon() -> Weapon:
	return current_weapon
