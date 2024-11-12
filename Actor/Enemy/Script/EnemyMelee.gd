extends CharacterBody3D

# Enemy Stats
@export_group("Base Stats")
@export var max_hp: float = 100.0
var current_hp: float = max_hp
@export var movement_speed: float = 5.0

# Combat Stats
@export_group("Combat Stats")
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var attack_radius: float = 2.0 # Melee range

# Nodes
@onready var attack_raycast: RayCast3D = $AttackRaycast
@onready var health_bar: ProgressBar3D = $ProgressBar3D
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

# State machine variables
enum EnemyState { IDLE, CHASE, ATTACK, DEAD }
var current_state: EnemyState = EnemyState.IDLE
var player: Node3D = null
var can_attack: bool = true
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	# Setup attack range
	attack_raycast.target_position = Vector3(0, 0, -attack_radius)

	# Setup health bar
	health_bar.max_value = max_hp
	health_bar.min_value = 0
	health_bar.value = current_hp
	health_bar.size = Vector2(1, 0.1)
	health_bar.position = Vector3(0, 2, 0)
	health_bar.billboard_mode = ProgressBar3D.BillboardMode.BILLBOARD_ENABLED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# State machine
	match current_state:
		EnemyState.IDLE:
			idle_state()
		EnemyState.CHASE:
			chase_state(delta)
		EnemyState.ATTACK:
			attack_state()
		EnemyState.DEAD:
			dead_state()
	
	# Update health bar
	health_bar.value = current_hp

func idle_state() -> void:
	if player:
		current_state = EnemyState.CHASE

func chase_state(delta: float) -> void:
	if !player:
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player <= attack_radius:
		current_state = EnemyState.ATTACK
	else:
		move_towards_player(delta)

func attack_state() -> void:
	if !player:
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > attack_radius:
		current_state = EnemyState.CHASE
	elif can_attack:
		perform_melee_attack()

func perform_melee_attack() -> void:
	can_attack = false
	attack_raycast.force_raycast_update()
	
	if attack_raycast.is_colliding():
		var target = attack_raycast.get_collider()
		if target.has_method("Hited"):
			target.Hited(attack_damage)

	# Start attack cooldown
	start_attack_cooldown()

func start_attack_cooldown() -> void:
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func move_towards_player(delta: float) -> void:
	nav_agent.target_position = player.global_position
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()

	# Look at player
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	
	# Move
	velocity = direction * movement_speed
	move_and_slide()

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
