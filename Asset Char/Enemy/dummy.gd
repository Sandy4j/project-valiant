extends CharacterBody3D
class_name Dummy

const SPEED = 0.2
const CHASE_SPEED = 1.0
const ATTACK_RANGE = -2.0
const ATTACK_COOLDOWN = 1.0
const ROTATION_SPEED = 10.0

@onready var health_bar: ProgressBar3D = $ProgressBar3D
@onready var detection_area: Area3D = $Detection
@onready var attack_ray: RayCast3D = $RayCastAtk
@onready var attack_timer = $CDAttack

@export var max_hp: int = 100
@onready var current_hp: int = max_hp

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: Player = null
var is_chasing = false
var can_attack = true

func _ready() -> void:
	setup_health_bar()
	setup_detection_area()
	setup_attack_timer()

func setup_health_bar() -> void:
	health_bar.max_value = max_hp
	health_bar.min_value = 0
	health_bar.value = current_hp
	health_bar.size = Vector2(1, 0.1)  # Adjust size as needed
	health_bar.position = Vector3(0, 2, 0)  # Adjust position to be above the enemy
	health_bar.billboard_mode = ProgressBar3D.BillboardMode.BILLBOARD_ENABLED

func setup_detection_area() -> void:
	detection_area.connect("body_entered", _on_detection_area_body_entered)
	detection_area.connect("body_exited", _on_detection_area_body_exited)

func setup_attack_timer() -> void:
	attack_timer = Timer.new()
	attack_timer.set_one_shot(false)
	attack_timer.set_wait_time(ATTACK_COOLDOWN)
	attack_timer.connect("timeout", _on_attack_timer_timeout)
	add_child(attack_timer)

func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	handle_movement(delta)
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

func handle_movement(delta: float) -> void:
	if is_chasing and player:
		chase_player(delta)
	else:
		stop_moving()

func chase_player(delta: float) -> void:
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0
	velocity = direction * CHASE_SPEED
	
	rotate_towards_player(direction, delta)
	
	if is_player_in_attack_range():
		handle_attack()
	else:
		reset_attack()

func rotate_towards_player(direction: Vector3, delta: float) -> void:
	if direction != Vector3.ZERO:
		var target_rotation = Quaternion(transform.basis).slerp(Quaternion(Basis.looking_at(direction, Vector3.UP)), ROTATION_SPEED * delta)
		transform.basis = Basis(target_rotation)

func stop_moving() -> void:
	velocity = velocity.move_toward(Vector3.ZERO, SPEED)
	reset_attack()

func handle_attack() -> void:
	if can_attack:
		attack()
		can_attack = false
		attack_timer.start()

func reset_attack() -> void:
	attack_timer.stop()
	can_attack = true

func take_damage(damage: int) -> void:
	current_hp = max(0, current_hp - damage)
	update_health_bar()
	print("Enemy took ", damage, " damage. HP remaining: ", current_hp)
	if current_hp <= 0:
		die()

func die() -> void:
	print("Enemy defeated!")
	queue_free()

func update_health_bar() -> void:
	health_bar.value = current_hp

func is_player_in_attack_range() -> bool:
	if attack_ray.is_colliding():
		var collider = attack_ray.get_collider()
		return collider == player
	return false

func attack() -> void:
	print("Attacking player")
	if player and player.has_method("Hited"):
		player.Hited(10)  # Assuming 10 is the damage amount

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body is Player:
		print("Player entered detection range")
		player = body
		is_chasing = true

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		print("Player exited detection range")
		player = null
		is_chasing = false
		reset_attack()
