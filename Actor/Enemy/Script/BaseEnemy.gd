extends CharacterBody3D
class_name BaseEnemy

@export_group("Base Stats")
@export var max_hp: float = 100.0
var current_hp: float = max_hp
@export var movement_speed: float = 5.0
var original_speed: float = movement_speed

@export_group("Combat Stats")
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var detection_radius: float = 10.0
@export var is_magic_damage: bool = false

@export_group("Defense Stats")
@export var physical_defense: float = 0.0
@export var magic_defense: float = 0.0

@onready var health_bar: ProgressBar3D = $ProgressBar3D
@onready var attack_raycast: RayCast3D = $AttackRaycast

enum EnemyState { IDLE, CHASE, ATTACK, DEAD }
var current_state: EnemyState = EnemyState.IDLE
var player: Node3D = null
var can_attack: bool = true
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var active_debuffs = {}

func _ready():
	health_bar.max_value = max_hp
	health_bar.min_value = 0
	health_bar.value = current_hp
	health_bar.size = Vector2(1, 0.1)
	health_bar.position = Vector3(0, 2, 0)
	health_bar.billboard_mode = ProgressBar3D.BillboardMode.BILLBOARD_ENABLED
	
	original_speed = movement_speed
	add_to_group("enemy")
	
	_init_child()
func _init_child() -> void:
	pass

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	health_bar.value = current_hp
	
	match current_state:
		EnemyState.IDLE:
			idle_state()
		EnemyState.CHASE:
			chase_state(delta)
		EnemyState.ATTACK:
			attack_state()
		EnemyState.DEAD:
			dead_state()
	
	_child_process(delta)

func _child_process(delta: float) -> void:
	pass

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

func move_towards_player(delta: float) -> void:
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0
	
	look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z))
	
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	move_and_slide()

func attack_state() -> void:
	if !player:
		current_state = EnemyState.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if distance_to_player > detection_radius:
		current_state = EnemyState.CHASE
	elif can_attack and has_clear_line_of_sight():
		perform_attack()
	else:
		current_state = EnemyState.CHASE

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

func perform_attack() -> void:
	pass

func start_attack_cooldown() -> void:
	can_attack = false
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func dead_state() -> void:
	var player_stats = get_tree().get_first_node_in_group("player").get_node("PlayerFunction/PlayerStats")
	if player_stats and player_stats.has_method("add_xp"):
		player_stats.add_xp(get_xp_reward())
	queue_free()

func get_xp_reward() -> int:
	return 30


func take_damage(damage: float, is_magic: bool = false) -> void:
	var actual_damage = damage
	if is_magic:
		actual_damage *= (1.0 - magic_defense)
	else:
		actual_damage *= (1.0 - physical_defense)
	actual_damage = max(1.0, actual_damage)
	current_hp -= actual_damage
	if current_hp <= 0:
		current_state = EnemyState.DEAD
	else:
		# Flash effect or damage animation could be added here
		pass


func take_damage_legacy(damage: float) -> void:
	take_damage(damage, false)
func is_magic_damager() -> bool:
	return is_magic_damage
func get_magic_defense() -> float:
	return magic_defense
func get_physical_defense() -> float:
	return physical_defense

func apply_debuff(debuff_type: String) -> void:
	var debuff_system = get_tree().get_first_node_in_group("player").get_node("PlayerFunction/MagicSystem")
	if debuff_system and debuff_system.has_method("apply_debuff"):
		debuff_system.apply_debuff(self, debuff_type)
		active_debuffs[debuff_type] = true

func update_speed() -> void:
	var cold_stacks = 0
	var debuff_system = get_tree().get_first_node_in_group("player").get_node("PlayerFunction/MagicSystem")
	
	if debuff_system and active_debuffs.has("cold"):
		var player_debuff_system = debuff_system.get_parent().get_node("DebuffSystem")
		if player_debuff_system and player_debuff_system.active_debuffs.has(self) and player_debuff_system.active_debuffs[self].has("cold"):
			cold_stacks = player_debuff_system.active_debuffs[self]["cold"]["stacks"]
	
	var slowdown_factor = max(0.5, 1.0 - (0.1 * cold_stacks))
	movement_speed = original_speed * slowdown_factor

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body == player:
		player = null
