extends Node
class_name MagicSystem

# Signals
signal spell_cast(spell_name: String)
signal spell_cooldown_updated(spell_name: String, cooldown: float)
signal spell_failed(reason: String)

# Exports
@export_category("Spell Settings")
@export var spell_spawn_point: NodePath
@export var camera_controller: NodePath

# Spell Data Configuration
var spell_data: Dictionary = {
	"firebolt": {
		"name": "Firebolt",
		"scene": preload("res://aset ril/aset vfx/Proyektil/enemy/Blast.tscn"),
		"damage_base": 40,
		"damage_multiplier": 1.5,
		"mana_cost": 30,
		"cooldown": 3.0,
		"speed": 15.0,
		"aoe_radius": 2.0,
		"debuff": "burn"
	},
	"blizzard": {
		"name": "Blizzard Beam",
		"scene": preload("res://aset ril/aset vfx/Proyektil/player/beam/beam.tscn"),
		"damage_base": 45,
		"damage_multiplier": 1.0,
		"mana_cost": 45,
		"cooldown": 5.0,
		"penetration": true,
		"debuff": "cold",
		"delay": 2.0
	}
}


@onready var stats: PlayerStatsController = get_parent().get_node("PlayerStats")
@onready var spawn_point: Node3D = get_node(spell_spawn_point)
@onready var camera: Camera3D = get_node(camera_controller)
var current_cooldowns: Dictionary = {}

func _ready():
	initialize_spells()
	connect_signals()

func initialize_spells():
	for spell in spell_data:
		current_cooldowns[spell] = {
			"remaining": 0.0,
			"timer": Timer.new()
		}
		add_child(current_cooldowns[spell]["timer"])
		current_cooldowns[spell]["timer"].timeout.connect(
			func(): 
				current_cooldowns[spell]["remaining"] = 0.0
				emit_signal("spell_cooldown_updated", spell, 0.0)
		)

func connect_signals():
	for spell in current_cooldowns:
		current_cooldowns[spell]["timer"].timeout.connect(
			func(): 
				current_cooldowns[spell]["remaining"] = 0.0
				emit_signal("spell_cooldown_updated", spell, 0.0)
		)

func _process(delta):
	for spell in current_cooldowns:
		if current_cooldowns[spell]["remaining"] > 0:
			current_cooldowns[spell]["remaining"] = max(0.0, current_cooldowns[spell]["remaining"] - delta)
			emit_signal("spell_cooldown_updated", spell, current_cooldowns[spell]["remaining"])

func cast_spell(spell_name: String):
	if not spell_data.has(spell_name):
		emit_signal("spell_failed", "Invalid spell")
		return
	
	var spell = spell_data[spell_name]
	
	# Cooldown check
	if current_cooldowns[spell_name]["remaining"] > 0:
		emit_signal("spell_failed", "Spell on cooldown")
		return
	
	# Mana check
	if not stats.use_mana(spell["mana_cost"]):
		emit_signal("spell_failed", "Not enough mana")
		return
	
	# Calculate final damage
	var damage = calculate_spell_damage(spell)
	
	# Instantiate spell scene
	var spell_instance = spell["scene"].instantiate()
	setup_spell_instance(spell_instance, spell_name, damage)
	
	# Add to scene tree
	get_tree().current_scene.add_child(spell_instance)
	
	# Start cooldown
	start_cooldown(spell_name, spell["cooldown"])
	emit_signal("spell_cast", spell_name)

func calculate_spell_damage(spell: Dictionary) -> int:
	return int(spell["damage_base"] + (stats.get_magical_attack() * spell["damage_multiplier"]))

func setup_spell_instance(instance: Node, spell_name: String, damage: int):
	# Common setup
	instance.global_transform = camera.global_transform
	instance.transform.origin = spawn_point.global_position
   
	match spell_name:
		"firebolt":
			instance.speed = spell_data[spell_name]["speed"]
			instance.damage = damage
			instance.aoe_radius = spell_data[spell_name]["aoe_radius"]
			instance.debuff_type = spell_data[spell_name]["debuff"]
			
		"blizzard":
			instance.damage = damage
			instance.debuff_type = spell_data[spell_name]["debuff"]
			instance.penetration = spell_data[spell_name]["penetration"]
			instance.delay = spell_data[spell_name]["delay"]

func start_cooldown(spell_name: String, duration: float):
	current_cooldowns[spell_name]["remaining"] = duration
	current_cooldowns[spell_name]["timer"].start(duration)

func get_cooldown_status(spell_name: String) -> float:
	return current_cooldowns[spell_name]["remaining"]

func force_cancel_spell(spell_name: String):
	if current_cooldowns[spell_name]["timer"].time_left > 0:
		current_cooldowns[spell_name]["timer"].stop()
		current_cooldowns[spell_name]["remaining"] = 0.0
		emit_signal("spell_cooldown_updated", spell_name, 0.0)

func upgrade_spell(spell_name: String, property: String, value: Variant):
	if spell_data[spell_name].has(property):
		spell_data[spell_name][property] = value

func get_spell_info(spell_name: String) -> Dictionary:
	return spell_data[spell_name].duplicate(true)

# Debug functions
func print_spell_info():
	for spell in spell_data:
		print("Spell: %s" % spell)
		print("Damage: %d" % calculate_spell_damage(spell_data[spell]))
		print("Cooldown: %.1f" % spell_data[spell]["cooldown"])
		print("Mana Cost: %d" % spell_data[spell]["mana_cost"])
		print("------------")
