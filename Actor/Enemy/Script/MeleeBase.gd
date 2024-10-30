extends CharacterBody3D

@export var SPEED: float = 5.0
@export var attack_cooldown: float = 1.0 # Waktu cooldown antara serangan
@export var damage: float = 10.0        # Damage yang diberikan ke player
@export var health: float = 100.0       # Health enemy

# Node references
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_ray: RayCast3D = $AttackRayCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# State variables
enum EnemyState { IDLE, CHASE, ATTACK }
var current_state: EnemyState = EnemyState.IDLE
var can_attack: bool = true
var is_alive: bool = true
var player: Node3D = null

func _ready() -> void:
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	attack_ray.enabled = true
	call_deferred("actor_setup")

func actor_setup() -> void:
	await get_tree().create_timer(0.1).timeout
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not is_alive or not player:
		return

	if player:
		attack_ray.look_at(player.global_position)
	
	match current_state:
		EnemyState.IDLE:
			pass
				
		EnemyState.CHASE:
			if can_attack and is_player_in_attack_range():
				change_state(EnemyState.ATTACK)
			else:
				chase_player(delta)
				
		EnemyState.ATTACK:
			if not is_player_in_attack_range():
				change_state(EnemyState.CHASE)
			else:
				attack_player()

func chase_player(delta: float) -> void:
	if not player:
		return

	nav_agent.set_target_position(player.global_position)
	
	if nav_agent.is_navigation_finished():
		return
	var next_path_position: Vector3 = nav_agent.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	velocity = direction * SPEED
	look_at_target(player.global_position, delta)
	move_and_slide()
	
	# Play animation if available
	#if animation_player and animation_player.has_animation("walk"):
		#animation_player.play("walk")

func is_player_in_attack_range() -> bool:
	if not player:
		return false

	if attack_ray.is_colliding():
		var collider = attack_ray.get_collider()
		return collider == player
	
	return false

func attack_player() -> void:
	if not can_attack or not is_player_in_attack_range():
		return
		
	# Play attack animation if available
	#if animation_player and animation_player.has_animation("attack"):
		#animation_player.play("attack")
	
	if player.has_method("take_damage"):
		player.take_damage(damage)

	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func take_damage(amount: float) -> void:
	health -= amount
	
	# Play hurt animation if available
	#if animation_player and animation_player.has_animation("hurt"):
		#animation_player.play("hurt")
	
	if health <= 0:
		die()

func die() -> void:
	is_alive = false
	
	# Play death animation if available
	#if animation_player and animation_player.has_animation("death"):
		#animation_player.play("death")
	
	# Disable collision
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	
	# Optional: Remove enemy after animation
	await get_tree().create_timer(2.0).timeout
	queue_free()

func change_state(new_state: EnemyState) -> void:
	current_state = new_state
	
	# Reset attack cooldown when changing from attack state
	if current_state != EnemyState.ATTACK:
		can_attack = true

func look_at_target(target_pos: Vector3, delta: float) -> void:
	var look_direction = target_pos - global_position
	look_direction.y = 0  # Keep vertical rotation locked
	
	if look_direction:
		# Smooth rotation
		var current_transform = transform
		var target_transform = transform.looking_at(target_pos, Vector3.UP)
		transform = current_transform.interpolate_with(target_transform, delta * 10.0)

# Signal handlers untuk Area3D
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body
		if current_state == EnemyState.IDLE:
			change_state(EnemyState.CHASE)

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
		change_state(EnemyState.IDLE)
