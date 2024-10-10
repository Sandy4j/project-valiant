extends CharacterBody3D
class_name Player

@export var SPEED = 5.0
@export var JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.05
@export var ATTACK_RANGE = 2.0
<<<<<<< Updated upstream


=======
@onready var animation_tree = get_node("AnimationTree")
@onready var playback = animation_tree.get("parameters/playback")
>>>>>>> Stashed changes
@onready var HP_BAR = $UI/IU/HP
@onready var camera = $"Pivot Cam/Camera3D"
@onready var attack_raycast = $AttackRaycast
@onready var main = "res://main.tscn"
@onready var stats: PlayerStats = $PlayerStats
@onready var weapon_system: WeaponSystem = $WeaponSystem

#Snimation Node
var idle_node:String = "Idle"
var walk_node:String = "Walk"
var run_node:String = "Run"
var jump_node:String = "Jump"
var attack1_node:String = "Attack1"
var death_node:String = "Death"

#State Machine
var is_attacking:bool
var is_walking:bool
var is_running:bool
var is_dying:bool 

var spawn_point = Vector3.ZERO
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	GlobalSignal.damaged.connect(self.Hited)
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
	stats.connect("player_died", Callable(self, "died"))
	stats.connect("debuff_applied", Callable(self, "_on_debuff_applied"))
	stats.connect("debuff_healed", Callable(self, "_on_debuff_healed"))

func _physics_process(delta):
	var on_floor = is_on_floor()
	# Add the gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and (!is_attacking):
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(-input_dir.x, 0, -input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
<<<<<<< Updated upstream
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	move_and_slide()
	handle_weapon_system(delta)
=======
		var target_rotation = atan2(direction.x, direction.z)
		rotation.y = lerp(rotation.y, target_rotation, MOUSE_SENSITIVITY * delta)
		is_walking = true
		if Input.is_action_just_pressed("sprint") and is_walking:
			SPEED * 2
			is_running = true
		else:
			SPEED / 2
			is_running = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		is_walking = false
		is_running = false

	move_and_slide()
	animation_tree["parameters/conditions/IsOnFloor"] = on_floor
	animation_tree["parameters/conditions/IsInAir"] = !on_floor
	animation_tree["parameters/conditions/IsWalking"] = is_walking
	animation_tree["parameters/conditions/IsNotWalking"] = !is_walking
	animation_tree["parameters/conditions/IsRunning"] = is_running
	animation_tree["parameters/conditions/IsNotRunning"] = !is_running
	animation_tree["parameters/conditions/is_dying"] = is_dying
	handle_melee_attack(delta)


func handle_melee_attack(delta):
	# Update timers
	combo_timer -= delta
	attack_cooldown -= delta
>>>>>>> Stashed changes
	
func _on_hp_changed(new_hp):
	HP_BAR.value = new_hp
	if new_hp <= 0:
		died()

func died():
	print("Player died")
	respawn()

func _on_level_up(new_level):
	print("Player leveled up to level ", new_level)

func _on_debuff_applied(debuff_value):
	print("Debuff applied. Max HP reduced by ", debuff_value)
	spawn_curselift()

func _on_debuff_healed():
	print("Debuff healed. Max HP restored.")

func respawn():
	global_transform.origin = spawn_point
	velocity = Vector3.ZERO
	stats.reset_stats()
	print("Player respawned at: ", spawn_point)

func spawn_curselift():
	var curselift_object = CurseliftObject.new()
	curselift_object.global_transform.origin = global_transform.origin
	get_parent().add_child(curselift_object)
	curselift_object.connect("curselift", Callable(self, "_on_curselift_collected"))

func _on_curselift_collected(body):
	if body == self:
		stats.heal_debuff()

func curse_lift():
	stats.heal_debuff()

func handle_weapon_system(delta):
	var current_weapon = weapon_system.get_current_weapon()
	current_weapon.update(delta)
	
	if Input.is_action_just_pressed("light attack"):
		var damage = current_weapon.attack()
		if damage > 0:
			apply_damage_to_enemy(damage)
	
	if Input.is_action_just_pressed("switch_weapon"):
		weapon_system.switch_weapon()
		update_attack_range()

func apply_damage_to_enemy(damage):
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

<<<<<<< Updated upstream
func Hited(damage: int):
	stats.take_damage(damage)
=======
func die():
	print("Player died!")
	
	respawn()

func check_death():
	if cur_hp <= 0:
		is_dying
		die()

func Hited(damage:int):
	print("Current HP before hit:", cur_hp)
	cur_hp -= damage
	setHP(cur_hp)
>>>>>>> Stashed changes
	print("Damage done:", damage)
	print("Current HP after hit:", stats.current_hp)
