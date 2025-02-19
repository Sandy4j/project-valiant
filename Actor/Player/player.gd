extends CharacterBody3D
class_name Player

@export var JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.05
@export var ATTACK_RANGE = 2.0
@export var ROTATION_SPEED = 10.0 

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
@onready var attack_raycast = $Rogue/AttackRaycast
@onready var main = "res://main.tscn"
@onready var GlobalSignal = "res://GlobalSignal.gd"
@onready var weapon_system: WeaponSystem = $WeaponSystem
@onready var ui_player: UI = %"UI Player"
@onready var model = $Rogue

@onready var stats: PlayerStats = $Node
var inv_op:bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera_rotation: float = 0.0 

func _ready():
	add_to_group("player")
	HP_BAR.max_value = stats.max_hp
	HP_BAR.value = stats.current_hp
<<<<<<< Updated upstream
	spawn_point = global_transform.origin
<<<<<<< HEAD
	call_deferred("connect_to_checkpoints")
=======
>>>>>>> Stashed changes
=======
>>>>>>> a4c5b3381e7ad774742250367db6ebbaeb5e3799
	
	attack_raycast.target_position = Vector3(0, 0, ATTACK_RANGE)
	attack_raycast.enabled = true
	attack_raycast.add_exception(self)
	weapon_system = WeaponSystem.new()
	add_child(weapon_system)
	update_attack_range()
	
	stats.connect("hp_changed", Callable(self, "_on_hp_changed"))
	stats.connect("curse_applied", Callable(self, "_on_curse_applied"))
	stats.connect("curse_lifted", Callable(self, "_on_curse_lifted"))
	stats.connect("Pdied", Callable(self, "died"))
	
func update_camera_rotation(cam_rotation: float):
	camera_rotation = cam_rotation

func _unhandled_input(event):
	if Input.is_action_just_pressed("dodge"):
		ui_player.update_floor_label(LevelManager.current_floor)
	if Input.is_action_just_pressed("suicide"):
		Hited(1000)

func _physics_process(delta):
	var on_floor = is_on_floor()
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var input_vector3 = Vector3(input_dir.x, 0, input_dir.y)
	var direction = Vector3.ZERO
	
	if input_vector3 != Vector3.ZERO:
		var cam_basis = Transform3D(Basis.from_euler(Vector3(0, camera_rotation, 0)))
		direction = (cam_basis * input_vector3).normalized()
		
		is_walking = true
		velocity.x = direction.x * stats.move_speed
		velocity.z = direction.z * stats.move_speed

		var target_rotation = atan2(direction.x, direction.z)
		if model:
			var current_rotation = model.rotation.y
			var new_rotation = lerp_angle(current_rotation, target_rotation, delta * ROTATION_SPEED)
			model.rotation.y = new_rotation
	else:
		is_walking = false
		velocity.x = move_toward(velocity.x, 0, stats.move_speed)
		velocity.z = move_toward(velocity.z, 0, stats.move_speed)
		if (attacku1_node_name in playback.get_current_node()): 
			is_attacking = true
		else: 
			is_attacking = false
	
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

func Hited(damage: int):
	stats.take_damage(damage)
	if (inv_op):
		inv_op = !inv_op
		ui_player.inv_clos()

func _on_hp_changed(new_hp):
	HP_BAR.value = new_hp
	HP_BAR.max_value = stats.max_hp

func died():
	stats.save_stats()
	LevelManager.reset_to_checkpoint()

func respawn() -> void:
	stats.load_stats()
	velocity = Vector3.ZERO
	stats.reset_stats()
	await get_tree().create_timer(0.1).timeout
	var dungeon_manager = get_tree().get_first_node_in_group("dungeon_manager")
	if dungeon_manager:
		if is_instance_valid(self):
			var current_parent = get_parent()
			if current_parent:
				current_parent.remove_child(self)
		dungeon_manager.spawn_player()

func _on_level_up(new_level):
	print("Player leveled up to level ", new_level)

func handle_weapon_system(delta):
	var current_weapon = weapon_system.get_current_weapon()
	current_weapon.update(delta)   
	if Input.is_action_just_pressed("light attack"):
		var damage = current_weapon.attack()
		apply_damage_to_enemy(damage)   
	if Input.is_action_just_pressed("swap weapon"):
		weapon_system.switch_weapon()
		set_attack_range(current_weapon.attack_range)

func apply_damage_to_enemy(damage):
	if (idle_node_name in playback.get_current_node() or 
		walk_node_name in playback.get_current_node()) and is_on_floor():
		
		if not is_attacking:
			playback.travel(attacku1_node_name)
<<<<<<< HEAD
<<<<<<< Updated upstream
=======
			is_attacking = true
			
>>>>>>> a4c5b3381e7ad774742250367db6ebbaeb5e3799
		if attack_raycast and attack_raycast.is_colliding():
=======
			is_attacking = true
			
		if attack_raycast.is_colliding():
>>>>>>> Stashed changes
			var collider = attack_raycast.get_collider()
			if  collider.has_method("take_damage"):
				collider.take_damage(damage)
				print("Dealt ", damage, " damage to enemy with ", 
					  weapon_system.get_current_weapon().weapon_name)
		else:
			print("No enemy in range")
<<<<<<< HEAD
<<<<<<< Updated upstream
=======
		await get_tree().create_timer(0.1).timeout
		is_attacking = false
>>>>>>> Stashed changes
=======
		await get_tree().create_timer(0.5).timeout
		is_attacking = false
>>>>>>> a4c5b3381e7ad774742250367db6ebbaeb5e3799

func update_attack_range():
	var current_weapon = weapon_system.get_current_weapon()
	set_attack_range(current_weapon.attack_range)

func set_attack_range(new_range: float):
	if attack_raycast:
<<<<<<< HEAD
<<<<<<< Updated upstream
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
	var curse_lift_object = preload("res://Actor/Player/curseliftobject.tscn").instantiate()
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
=======
		attack_raycast.target_position = Vector3(0, 0, new_range)
		print("Attack range updated to: ", -new_range)
>>>>>>> Stashed changes
=======
		attack_raycast.target_position = Vector3(0, 0, new_range)
		print("Attack range updated to: ", new_range)
>>>>>>> a4c5b3381e7ad774742250367db6ebbaeb5e3799
