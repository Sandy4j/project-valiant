extends CharacterBody3D
class_name ModularEnemy

# Constants
const ROTATION_SPEED = 10.0

# Customizable properties
@export var max_hp: int = 100
@export var move_speed: float = 1.0
@export var chase_speed: float = 2.0
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var attack_damage: int = 10

# Node references
@onready var health_bar: ProgressBar3D = $ProgressBar3D
@onready var detection_area: Area3D = $Detection
@onready var attack_ray: RayCast3D = $RayCastAtk
@onready var attack_timer: Timer = $CDAttack
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# State variables
var current_hp: int
var gravity: float
var player: Player = null
var state: EnemyState

# Enums
enum EnemyState { IDLE, CHASE, ATTACK }

func _ready() -> void:
	attack_ray.target_position = Vector3(0, 0, -attack_range)
	initialize()

func initialize() -> void:
	current_hp = max_hp
	gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	state = EnemyState.IDLE
	
	setup_health_bar()
	setup_detection_area()
	setup_attack_timer()

func setup_health_bar() -> void:
	health_bar.max_value = max_hp
	health_bar.min_value = 0
	health_bar.value = current_hp
	health_bar.size = Vector2(1, 0.1)
	health_bar.position = Vector3(0, 2, 0)
	health_bar.billboard_mode = ProgressBar3D.BillboardMode.BILLBOARD_ENABLED

func setup_detection_area() -> void:
	detection_area.connect("body_entered", _on_detection_body_entered)
	detection_area.connect("body_exited", _on_detection_body_exited)

func setup_attack_timer() -> void:
	attack_timer.set_one_shot(true)
	attack_timer.set_wait_time(attack_cooldown)
	attack_timer.connect("timeout", _on_attack_timer_timeout)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	
	match state:
		EnemyState.IDLE:
			handle_idle_state(delta)
		EnemyState.CHASE:
			handle_chase_state(delta)
		EnemyState.ATTACK:
			handle_attack_state(delta)
	
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_idle_state(delta: float) -> void:
	velocity = velocity.move_toward(Vector3.ZERO, move_speed * delta)
	#play_animation("idle")

func handle_chase_state(delta: float) -> void:
	if player:
		var direction = player.global_position - global_position
		direction.y = 0
		direction = direction.normalized()      
		velocity = direction * chase_speed      
		rotate_towards_target(direction, delta)      
		if is_target_in_attack_range():
			transition_to_state(EnemyState.ATTACK)
		else:
			#play_animation("run")
			pass

func handle_attack_state(delta: float) -> void:
	velocity = Vector3.ZERO
	if player:
		rotate_towards_target((player.global_position - global_position).normalized(), delta)
		if attack_timer.is_stopped():
			perform_attack()
	else:
		transition_to_state(EnemyState.IDLE)

func rotate_towards_target(direction: Vector3, delta: float) -> void:
	if direction != Vector3.ZERO:
		# Pastikan arah hanya horizontal
		direction.y = 0
		direction = direction.normalized()
		look_at(global_position + direction, Vector3.UP)
		var target_transform = transform.looking_at(global_position + direction, Vector3.UP)
		transform = transform.interpolate_with(target_transform, ROTATION_SPEED * delta)

func is_target_in_attack_range() -> bool:
	return attack_ray.is_colliding() and attack_ray.get_collider() == player

func perform_attack() -> void:
	#play_animation("attack")
	if player and player.has_method("Hited"):
		player.Hited(attack_damage)
	attack_timer.start()

func take_damage(damage: int) -> void:
	current_hp = max(0, current_hp - damage)
	update_health_bar()
	#play_animation("hit")
	print("%s took %d damage. HP remaining: %d" % [name, damage, current_hp])
	if current_hp <= 0:
		die()

func die() -> void:
	#play_animation("die")
	set_physics_process(false)
	detection_area.set_deferred("monitoring", false)
	print("%s defeated!" % name)
	# Wait for death animation to finish before freeing
	#await animation_plasyer.animation_finished
	queue_free()

func update_health_bar() -> void:
	health_bar.value = current_hp

#func play_animation(anim_name: String) -> void:
	#if animation_player.has_animation(anim_name):
		#animation_player.play(anim_name)

func transition_to_state(new_state: EnemyState) -> void:
	state = new_state
	match state:
		EnemyState.IDLE:
			#play_animation("idle")
			pass
		EnemyState.CHASE:
			#play_animation("run")
			pass
		EnemyState.ATTACK:
			#play_animation("attack")
			pass

func _on_detection_body_entered(body: Node3D) -> void:
	if body is Player:
		print("Player entered detection range")
		player = body
		transition_to_state(EnemyState.CHASE)

func _on_detection_body_exited(body: Node3D) -> void:
	if body == player:
		print("Player exited detection range")
		player = null
		transition_to_state(EnemyState.IDLE)

func _on_attack_timer_timeout() -> void:
	if state == EnemyState.ATTACK and is_target_in_attack_range():
		perform_attack()
	else:
		transition_to_state(EnemyState.CHASE)
