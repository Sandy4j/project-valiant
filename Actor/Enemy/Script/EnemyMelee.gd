extends BaseEnemy
class_name EnemyMelee

@export var attack_radius: float = 2.0

func _init_child() -> void:
	attack_raycast.target_position = Vector3(0, 0, -attack_radius)
	detection_radius = attack_radius

func attack_state() -> void:
	if !player:
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > attack_radius:
		current_state = EnemyState.CHASE
	elif can_attack:
		perform_attack()

func perform_attack() -> void:
	can_attack = false
	attack_raycast.force_raycast_update()
	
	if attack_raycast.is_colliding():
		var target = attack_raycast.get_collider()
		if target.has_method("Hited"):
			target.Hited(attack_damage)

	start_attack_cooldown()

func get_xp_reward() -> int:
	return 30
