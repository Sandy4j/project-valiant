extends Node
class_name PlayerPhysicalCombatController

signal attack_performed
signal combo_updated(combo_count)

@export var ATTACK_RANGE = 2.0
@export var MAX_COMBO = 3
@export var BASE_DAMAGE_MULTIPLIER = 1.0

@export var COMBO_1_MULTIPLIER = 1.0
@export var COMBO_2_MULTIPLIER = 1.2
@export var COMBO_3_MULTIPLIER = 1.5

@export var BASE_ATTACK_COOLDOWN = 0.5
@export var COMBO_TIMEOUT = 2.0

@onready var stats_controller = get_parent().get_node("PlayerStats")
@onready var animation_controller = get_parent().get_node("PlayerAnim")
@onready var attack_raycast = $"../../Rogue/AttackRaycast"

var current_combo = 0
var combo_timer = 0.0
var attack_cooldown = 0.0
var can_attack = true

func _process(delta):
	if attack_cooldown > 0:
		attack_cooldown -= delta
		if attack_cooldown <= 0:
			can_attack = true
	
	if current_combo > 0:
		combo_timer += delta
		if combo_timer >= COMBO_TIMEOUT:
			reset_combo()
			
	if Input.is_action_just_pressed("light attack") and can_attack:
		perform_attack()

func perform_attack() -> void:
	var stamina_cost = stats_controller.get_max_stamina() * 0.01

	if not stats_controller.use_stamina(int(stamina_cost)):
		print("Not enough stamina to attack!")
		return

	current_combo = (current_combo % MAX_COMBO) + 1
	combo_timer = 0
	emit_signal("combo_updated", current_combo)

	emit_signal("attack_performed")
	
	# Optional: Handle attack animation
	# If animation_controller has these methods, use them
	# Otherwise, use the play_attack method from the existing code
	# match current_combo:
		# 1:
			# if animation_controller.has_method("play_attack1"):
				# animation_controller.play_attack1()
			# else:
				# animation_controller.play_attack()
		# 2:
			# if animation_controller.has_method("play_attack2"):
				# animation_controller.play_attack2()
			# else:
				# animation_controller.play_attack()
		# 3:
			# if animation_controller.has_method("play_attack3"):
				# animation_controller.play_attack3()
			# else:
				# animation_controller.play_attack()

	attack_cooldown = BASE_ATTACK_COOLDOWN
	can_attack = false
	check_hit()

func check_hit() -> void:
	if attack_raycast.is_colliding():
		var target = attack_raycast.get_collider()
		if target and target.has_method("take_damage"):
			var damage = calculate_damage()
			target.take_damage(damage)
			print("Hit target for " + str(damage) + " damage!")

func calculate_damage() -> int:
	var base_damage = stats_controller.get_physical_attack()
	var combo_multiplier = COMBO_1_MULTIPLIER
	match current_combo:
		1:
			combo_multiplier = COMBO_1_MULTIPLIER
		2:
			combo_multiplier = COMBO_2_MULTIPLIER
		3:
			combo_multiplier = COMBO_3_MULTIPLIER
	
	var damage = int(base_damage * combo_multiplier * BASE_DAMAGE_MULTIPLIER)
	
	var crit_chance = 50
	var crit_multiplier = 2.0
	
	if randf() * 100 <= crit_chance:
		damage = int(damage * crit_multiplier)
		print("CRITICAL HIT!")
	
	return damage

func reset_combo() -> void:
	current_combo = 0
	combo_timer = 0.0
	emit_signal("combo_updated", current_combo)


func get_current_combo() -> int:
	return current_combo

func interrupt_combo() -> void:
	reset_combo()
	attack_cooldown = 0.0
	can_attack = true
