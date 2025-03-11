extends CharacterBody3D

# Enemy Type Configuration
@export var projectile_scene: PackedScene

# Enemy Stats
@export_group("Base Stats")
@export var max_hp: float = 100.0
var current_hp: float = max_hp
@export var movement_speed: float = 5.0

# Combat Stats
@export_group("Combat Stats") 
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var projectile_speed: float = 15.0
@export var detection_radius: float = 10.0
@export var min_attack_distance: float = 5.0

# Nodes
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_raycast: RayCast3D = $AttackRaycast
@onready var health_bar: ProgressBar3D = $ProgressBar3D
@onready var projectile_spawn: Marker3D = $ProjectileSpawn

# State machine variables
enum EnemyState { IDLE, CHASE, ATTACK, DEAD }
var current_state: EnemyState = EnemyState.IDLE
var player: Node3D = null
var can_attack: bool = true

# Gravity konstanta
const GRAVITY_MULTIPLIER: float = 3.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * GRAVITY_MULTIPLIER

func _ready():
	# Setup health bar
	health_bar.max_value = max_hp
	health_bar.min_value = 0
	health_bar.value = current_hp
	health_bar.size = Vector2(1, 0.1)
	health_bar.position = Vector3(0, 2, 0)
	health_bar.billboard_mode = ProgressBar3D.BillboardMode.BILLBOARD_ENABLED
	
	attack_raycast.enabled = true
	attack_raycast.collision_mask = 1
	attack_raycast.target_position = Vector3(0, 0, detection_radius)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1
	

	health_bar.value = current_hp
	move_and_slide()

func idle_state() -> void:
	if player:
		current_state = EnemyState.CHASE

func chase_state(delta: float) -> void:
	if !player:
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= detection_radius and has_clear_line_of_sight():
		current_state = EnemyState.ATTACK
	else:
		move_towards_player(delta)

func attack_state() -> void:
	if !player:
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_radius:
		current_state = EnemyState.CHASE
	elif can_attack and has_clear_line_of_sight():
		perform_ranged_attack()
	else:
		current_state = EnemyState.CHASE

func perform_ranged_attack() -> void:
	if !projectile_scene:
		push_error("Projectile scene not set for ranged enemy!")
		return
	
	can_attack = false
	
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = projectile_spawn.global_position
	
	var direction = calculate_projectile_direction()
	if projectile.has_method("initialize"):
		projectile.initialize(direction, projectile_speed, attack_damage)
	
	start_attack_cooldown()

func calculate_projectile_direction() -> Vector3:
	var time_to_target = global_position.distance_to(player.global_position) / projectile_speed
	var predicted_position = player.global_position + player.velocity * time_to_target
	return (predicted_position - projectile_spawn.global_position).normalized()

func has_clear_line_of_sight() -> bool:
	if !player:
		return false

	var direction = (player.global_position - global_position)
	attack_raycast.target_position = direction
	attack_raycast.force_raycast_update()
	
	if attack_raycast.is_colliding():
		var collider = attack_raycast.get_collider()
		return collider == player
	
	return false

func start_attack_cooldown() -> void:
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func move_towards_player(delta: float) -> void:
	if !player:
		return
	
	var direction: Vector3 = (player.global_position - global_position).normalized()
	direction.y = 0
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	
	var look_at_pos = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(look_at_pos)

func dead_state() -> void:
	queue_free()

func take_damage(damage: float) -> void:
	current_hp -= damage
	if current_hp <= 0:
		current_state = EnemyState.DEAD

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
