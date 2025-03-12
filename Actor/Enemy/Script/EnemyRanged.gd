extends BaseEnemy
class_name EnemyRanged

@export var projectile_scene: PackedScene
@export var projectile_speed: float = 15.0
@export var min_attack_distance: float = 5.0

@onready var projectile_spawn: Marker3D = $ProjectileSpawn

const GRAVITY_MULTIPLIER: float = 3.0

func _init_child() -> void:
	gravity *= GRAVITY_MULTIPLIER
	detection_radius = 10.0
	is_magic_damage = true 
	
	physical_defense = 0.1  # 10%
	magic_defense = 0.3     # 30%
	
	attack_raycast.enabled = true
	attack_raycast.collision_mask = 1
	attack_raycast.target_position = Vector3(0, 0, detection_radius)

func _child_process(delta: float) -> void:
	if is_on_floor():
		velocity.y = -0.1 

func perform_attack() -> void:
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

func get_xp_reward() -> int:
	return 40
