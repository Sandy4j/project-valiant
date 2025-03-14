extends Node
class_name PlayerStatsController

signal hp_changed()
signal mana_changed()
signal exp_changed()
signal stamina_changed(new_stamina)
signal stat_point_changed(new_points)
signal attribute_changed(attribute_name, new_value)
signal level_changed(new_level)
signal Pdied

var base_hp: int = 100
var base_mana: int = 1000
var base_physical_attack: int = 20
var base_magical_attack: int = 25
var base_physical_defense: int = 15
var base_magical_defense: int = 10
var base_stamina: int = 30
var base_hp_regen: float = 2.0
var base_stamina_regen_percent: float = 5.0


var str_points: int = 0 
var int_points: int = 0
var end_points: int = 0
var agi_points: int = 0
var vit_points: int = 0


var max_hp: int
var current_hp: int
var max_mana: int
var current_mana: int
var physical_attack: int
var magical_attack: int
var physical_defense: int
var magical_defense: int
var max_stamina: int
var current_stamina: int
var hp_regen: float
var stamina_regen: float
var magic_cd: float


var player_level: int = 1
var player_xp: int = 50
var xp_to_next_level: int = 100
var stat_points: int = 3 
var stat_points_per_level: int = 2

var move_speed: float = 5.0
var regen_timer: float = 0.0

# @onready var hp_bar = $IU/HP
# @onready var mana_bar = get_parent().get_node("UI Player/IU/Mana")
# @onready var stamina_bar = get_parent().get_node("UI Player/IU/Stamina")

func _ready():
	calculate_stats()

	current_hp = max_hp - 50
	current_mana = max_mana - 500
	current_stamina = max_stamina
	connect("heal_pot", Callable(self,"heal"))
	connect("mana_pot", Callable(self,"restore_mana"))
	
	#hp_bar.max_value = max_hp
	#hp_bar.value = current_hp
	# mana_bar.max_value = max_mana
	# mana_bar.value = current_mana
	# stamina_bar.max_value = max_stamina
	# stamina_bar.value = current_stamina

func _process(delta):
	regen_timer += delta
	
	if regen_timer >= 1.0:
		regen_timer = 0.0

		if current_hp < max_hp:
			current_hp = min(max_hp, current_hp + int(hp_regen))
			emit_signal("hp_changed")
			
		if current_stamina < max_stamina:
			var stamina_to_regen = (max_stamina * stamina_regen) / 100.0
			current_stamina = min(max_stamina, current_stamina + stamina_to_regen)
			emit_signal("stamina_changed", current_stamina)

func calculate_stats():
	max_hp = base_hp + (vit_points * 10)
	max_stamina = base_stamina + (vit_points * 5)

	max_mana = base_mana + (int_points * 5)
	
	physical_attack = base_physical_attack + (str_points * 2)
	magical_attack = base_magical_attack + (int_points * 2.5)

	physical_defense = base_physical_defense + (end_points * 1.5)
	magical_defense = base_magical_defense + (end_points * 1.5)
	hp_regen = base_hp_regen + (end_points * 0.5)

	stamina_regen = base_stamina_regen_percent + (agi_points * 0.5)

	magic_cd = agi_points * 2.0

func add_attribute_point(attribute: String, points: int = 1) -> bool:
	if stat_points < points:
		return false
	match attribute.to_lower():
		"str":
			str_points += points
			emit_signal("attribute_changed", "str", str_points)
		"int":
			int_points += points
			emit_signal("attribute_changed", "int", int_points)
		"end":
			end_points += points
			emit_signal("attribute_changed", "end", end_points)
		"agi":
			agi_points += points
			emit_signal("attribute_changed", "agi", agi_points)
		"vit":
			vit_points += points
			emit_signal("attribute_changed", "vit", vit_points)
		_:
			return false
	
	stat_points -= points
	emit_signal("stat_point_changed", stat_points)
	
	calculate_stats()
	
	#hp_bar.max_value = max_hp
	# mana_bar.max_value = max_mana
	# stamina_bar.max_value = max_stamina
	
	return true

func take_damage(damage: int) -> void:
	var actual_damage = max(1, damage - physical_defense)
	
	current_hp = max(0, current_hp - actual_damage)
	emit_signal("hp_changed")
	
	if current_hp <= 0:
		emit_signal("Pdied")

func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		emit_signal("mana_changed")
		return true
	return false

func use_stamina(amount: int) -> bool:
	if current_stamina >= amount:
		current_stamina -= amount
		emit_signal("stamina_changed", current_stamina)
		return true
	return false

func heal(amount: int) -> void:
	print("Healing player by:", amount)
	current_hp = min(max_hp, current_hp + amount)
	emit_signal("hp_changed")


func restore_mana(amount: int) -> void:
	print("Mana restored by:", amount)
	current_mana = min(max_mana, current_mana + amount)
	emit_signal("mana_changed")


func restore_stamina(amount: int) -> void:
	current_stamina = min(max_stamina, current_stamina + amount)
	emit_signal("stamina_changed", current_stamina)

func add_xp(amount: int) -> void:
	player_xp += amount
	
	if player_xp >= xp_to_next_level:
		level_up()
	
	emit_signal("exp_changed")

func level_up() -> void:
	player_level += 1
	player_xp -= xp_to_next_level
	xp_to_next_level = calculate_next_level_xp()
	
	stat_points += stat_points_per_level
	
	emit_signal("level_changed")
	emit_signal("stat_point_changed", stat_points)
	
	current_hp = max_hp
	current_mana = max_mana
	current_stamina = max_stamina
	
	emit_signal("hp_changed")
	emit_signal("mana_changed")
	emit_signal("stamina_changed", current_stamina)

func calculate_next_level_xp() -> int:
	return int(xp_to_next_level * 1.5)

func save_stats() -> Dictionary:
	var save_data = {
		"level": player_level,
		"xp": player_xp,
		"stat_points": stat_points,
		"str": str_points,
		"int": int_points,
		"end": end_points,
		"agi": agi_points,
		"vit": vit_points,
		"current_hp": current_hp,
		"current_mana": current_mana,
		"current_stamina": current_stamina
	}
	return save_data
	
func load_stats(data: Dictionary) -> void:
	if data.has("level"): player_level = data["level"]
	if data.has("xp"): player_xp = data["xp"]
	if data.has("stat_points"): stat_points = data["stat_points"]
	if data.has("str"): str_points = data["str"]
	if data.has("int"): int_points = data["int"]
	if data.has("end"): end_points = data["end"]
	if data.has("agi"): agi_points = data["agi"]
	if data.has("vit"): vit_points = data["vit"]
	calculate_stats()
	
	if data.has("current_hp"): current_hp = min(data["current_hp"], max_hp)
	if data.has("current_mana"): current_mana = min(data["current_mana"], max_mana)
	if data.has("current_stamina"): current_stamina = min(data["current_stamina"], max_stamina)
	
	# Update UI
	#hp_bar.max_value = max_hp
	#hp_bar.value = current_hp
	# mana_bar.max_value = max_mana
	# mana_bar.value = current_mana
	# stamina_bar.max_value = max_stamina
	# stamina_bar.value = current_stamina
	
func reset_stats() -> void:
	current_hp = max_hp
	current_mana = max_mana
	current_stamina = max_stamina
	
	emit_signal("hp_changed")
	emit_signal("mana_changed")
	emit_signal("stamina_changed", current_stamina)

func get_max_hp() -> int: return max_hp
func get_max_mana() -> int: return max_mana
func get_max_stamina() -> int: return max_stamina
func get_physical_attack() -> int: return physical_attack
func get_magical_attack() -> int: return magical_attack
func get_physical_defense() -> int: return physical_defense
func get_magical_defense() -> int: return magical_defense
func get_magic_cd() -> float: return magic_cd
