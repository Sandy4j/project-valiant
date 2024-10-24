extends CharacterBody3D
class_name Player

@export var JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.05
@export var ATTACK_RANGE = 2.0

var idle_node_name: String = "Idle"
var walk_node_name: String = "Walk"
var run_node_name: String = "Run"
var jump_node_name: String = "Jump"
var attacku1_node_name: String = "AttackU1"
var death_node_name: String = "Death"
var hitted_node_name: String = "Hitted"

var is_attacking: bool
var is_walking: bool
var is_running: bool
var is_dying: bool
var is_hitted: bool

@onready var animation_tree = get_node("AnimationTree")
@onready var playback = animation_tree.get("parameters/playback")
@onready var HP_BAR = $"UI Player/IU/HP"
@onready var attack_raycast = $AttackRaycast
@onready var main = "res://main.tscn"
@onready var stats: PlayerStats = $PlayerStats
@onready var GlobalSignal = "res://GlobalSignal.gd"
@onready var weapon_system: WeaponSystem = $WeaponSystem
@onready var dodge_component = $dodge
@onready var ui_player: UI = %"UI Player"

var inv_op:bool = false
var spawn_point = Vector3.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("player")
	set_physics_process(false)
	# Tunggu sebentar sebelum mengaktifkan physics
	await get_tree().create_timer(0.1).timeout
	set_physics_process(true)
	HP_BAR.max_value = stats.max_hp
	HP_BAR.value = stats.current_hp
	spawn_point = global_transform.origin
	call_deferred("connect_to_checkpoints")
	
	attack_raycast.target_position = Vector3(0, 0, -ATTACK_RANGE)
	attack_raycast.enabled = true
	weapon_system = WeaponSystem.new()
	add_child(weapon_system)
	update_attack_range()
	
	# Connect signals from PlayerStats
	stats.connect("hp_changed", Callable(self, "_on_hp_changed"))
	stats.connect("levelup", Callable(self, "_on_level_up"))
	stats.connect("curse_applied", Callable(self, "_on_curse_applied"))
	stats.connect("curse_lifted", Callable(self, "_on_curse_lifted"))
	
	 # Connect dodge component signals
	dodge_component.connect("dodge_started", Callable(self, "_on_dodge_started"))
	dodge_component.connect("dodge_ended", Callable(self, "_on_dodge_ended"))
	dodge_component.connect("iframe_ended", Callable(self, "_on_iframe_ended"))
	

func _physics_process(delta):
	var on_floor = is_on_floor()
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()
	if direction:
		is_walking = true
		velocity.x = direction.x * stats.move_speed
		velocity.z = direction.z * stats.move_speed
	else:
		is_walking = false
		velocity.x = move_toward(velocity.x, 0, stats.move_speed)
		velocity.z = move_toward(velocity.z, 0, stats.move_speed)
		if (attacku1_node_name in playback.get_current_node()): 
			is_attacking = true
		else: 
			is_attacking = false
		
	if dodge_component.is_dodging():
		# The dodge component is handling movement
		pass
	elif direction:
		velocity.x = direction.x * stats.move_speed
		velocity.z = direction.z * stats.move_speed
	else:
		velocity.x = move_toward(velocity.x, 0, stats.move_speed)
		velocity.z = move_toward(velocity.z, 0, stats.move_speed)

	if Input.is_action_just_pressed("dodge"):
		dodge_component.dodge(direction)
	
	if Input.is_action_just_pressed("inven"):
		inv_op = !inv_op
		if inv_op:
			ui_player.inv_open()
		else:
			ui_player.inv_clos()
	
	
	handle_weapon_system(delta)
	move_and_slide()
	animation_tree["parameters/conditions/IsOnFloor"] = on_floor
	animation_tree["parameters/conditions/IsInAir"] = !on_floor
	animation_tree["parameters/conditions/IsWalking"] = is_walking
	animation_tree["parameters/conditions/IsNotWalking"] =!is_walking
	animation_tree["parameters/conditions/IsRunning"] = is_running
	animation_tree["parameters/conditions/IsNotRunning"] = !is_running
	animation_tree["parameters/conditions/IsDying"] = is_dying
	animation_tree["parameters/conditions/IsHitted"] = is_hitted

func _on_dodge_started():
	print("Player started dodging!")

func _on_dodge_ended():
	print("Player finished dodging!")

func _on_iframe_ended():
	print("Player's invincibility frames ended!")

func Hited(damage: int):
	stats.take_damage(damage)
	if (inv_op):
		inv_op = !inv_op
		ui_player.inv_clos()

func _on_hp_changed(new_hp):
	HP_BAR.value = new_hp
	HP_BAR.max_value = stats.max_hp

func respawn():
	global_transform.origin = spawn_point
	velocity = Vector3.ZERO
	stats.reset_stats()
	print("Player respawned at: ", spawn_point)
	
func _on_level_up(new_level):
	print("Player leveled up to level ", new_level)

func handle_weapon_system(delta):
	var current_weapon = weapon_system.get_current_weapon()
	current_weapon.update(delta)   
	if Input.is_action_just_pressed("light attack"):
		var damage = current_weapon.attack()
		
		if damage > 0:
			apply_damage_to_enemy(damage)   
	if Input.is_action_just_pressed("swap weapon"):
		weapon_system.switch_weapon()
		set_attack_range(current_weapon.attack_range)

func apply_damage_to_enemy(damage):
	if (idle_node_name in playback.get_current_node() or walk_node_name in playback.get_current_node()) and is_on_floor():
		if (is_attacking == false):
			playback.travel(attacku1_node_name)
		if attack_raycast and attack_raycast.is_colliding():
			var collider = attack_raycast.get_collider()
			if collider and collider.has_method("take_damage"):
				collider.take_damage(damage)
				print("Dealt ", damage, " damage to enemy with ", weapon_system.get_current_weapon().weapon_name)
				
		else:
			print("No enemy in range")

func update_attack_range():
	var current_weapon = weapon_system.get_current_weapon()
	set_attack_range(current_weapon.attack_range)

func set_attack_range(new_range: float):
	if attack_raycast:
		attack_raycast.target_position = Vector3(0, 0, -new_range)
		print("Attack range updated to: ", new_range)

func connect_to_checkpoints():
	var checkpoints = get_tree().get_nodes_in_group("checkpoints")
	for checkpoint in checkpoints:
		checkpoint.connect("checkpoint_reached", Callable(self, "update_spawn_point"))

func update_spawn_point(new_spawn_point):
	spawn_point = new_spawn_point
	print("Spawn point updated to: ", spawn_point)
	
func _on_curse_applied(curse_value):
	spawn_curse_lift_object()
	print("Curse applied. Max HP reduced by ", curse_value)

func _on_curse_lifted():
	print("Curse lifted. Max HP restored.")

func spawn_curse_lift_object():
	var curse_lift_object = preload("res://Asset Char/Player/curseliftobject.tscn").instantiate()
	var spawn_offset = Vector3(randf_range(-3, 3), 1, randf_range(-3, 3))
	curse_lift_object.global_position = global_position + spawn_offset
	get_tree().current_scene.add_child(curse_lift_object)
	curse_lift_object.connect("curse_lift_collected", Callable(self, "_on_curse_lift_collected"))
	print("CurseLiftObject spawned at: ", curse_lift_object.global_position)

func _on_curse_lift_collected(body):
	if body == self:
		stats.lift_curse()

func collect_curse_lift():
	stats.lift_curse()
