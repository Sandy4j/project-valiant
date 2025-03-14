extends Node
class_name EnemySpawner

@export_category("Spawn Settings")
@export var enemy_scenes: Array[PackedScene] = []
@export var max_active_enemies: int = 10
@export var pool_size: int = 15
@export var spawn_points_per_room: int = 3
@export var min_spawn_distance_from_wall: float = 1.5

@export_category("Difficulty Settings")
@export var base_spawn_chance: float = 0.7
@export var difficulty_curve: Curve
@export var max_enemy_multiplier: float = 2.0

var dungeon_manager: DungeonM
var grid_map: GridMap
var dungeon_mesh: DungeonMesh
var level_manager: LevelManager

var enemy_pool: Dictionary = {}
var active_enemies: Array[BaseEnemy] = []
var spawn_points: Array[Vector3] = []
var room_bounds: Dictionary = {}

func _ready():
	dungeon_manager = get_parent().get_node("DungeonManager")
	level_manager = get_parent().get_node("LevelManager")
	grid_map = dungeon_manager.get_node(dungeon_manager.grid_map_path)
	dungeon_mesh = dungeon_manager.get_node(dungeon_manager.dungeon_mesh_path)
	
	initialize_pool()
	dungeon_manager.dungeon_generation_completed.connect(_on_dungeon_generated)

func initialize_pool():
	for scene in enemy_scenes:
		enemy_pool[scene] = []
		for _i in range(pool_size):
			var enemy = scene.instantiate()
			enemy.visible = false
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			add_child(enemy)
			enemy_pool[scene].append(enemy)

func _on_dungeon_generated():
	reset_spawner()
	generate_spawn_points()
	calculate_difficulty()
	spawn_enemies()

func generate_spawn_points():
	spawn_points.clear()
	room_bounds.clear()
	
	# Identifikasi batas setiap ruangan
	var rooms = grid_map.get_used_cells().filter(
		func(cell): return grid_map.get_cell_item(cell) == 0
	)
	
	# Kelompokkan cell per ruangan
	for cell in rooms:
		var room_id = find_room_id(cell)
		if not room_bounds.has(room_id):
			room_bounds[room_id] = {
				"min_x": cell.x, "max_x": cell.x,
				"min_z": cell.z, "max_z": cell.z
			}
		else:
			room_bounds[room_id].min_x = min(room_bounds[room_id].min_x, cell.x)
			room_bounds[room_id].max_x = max(room_bounds[room_id].max_x, cell.x)
			room_bounds[room_id].min_z = min(room_bounds[room_id].min_z, cell.z)
			room_bounds[room_id].max_z = max(room_bounds[room_id].max_z, cell.z)
	
	# Generate titik spawn untuk setiap ruangan
	for room in room_bounds.values():
		for _i in range(spawn_points_per_room):
			var spawn_pos = generate_valid_spawn_position(room)
			if spawn_pos:
				spawn_points.append(spawn_pos)

func generate_valid_spawn_position(room: Dictionary) -> Vector3:
	var cell_size = grid_map.cell_size
	var attempts = 5
	
	# Gunakan world 3D dari dungeon mesh
	var world_3d = dungeon_mesh.get_world_3d()
	if not world_3d:
		push_error("Failed to get 3D world!")
		return Vector3.ZERO
	
	for _j in range(attempts):

		var x = randf_range(
			room.min_x + min_spawn_distance_from_wall/cell_size.x, 
			room.max_x + 1 - min_spawn_distance_from_wall/cell_size.x
		)
		var z = randf_range(
			room.min_z + min_spawn_distance_from_wall/cell_size.z,
			room.max_z + 1 - min_spawn_distance_from_wall/cell_size.z
		)
		
		var grid_pos = Vector3(x, 0, z)
		var world_pos = dungeon_mesh.calculate_grid_to_world(grid_pos)

		var space_state = world_3d.direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			world_pos + Vector3.UP * 2,
			world_pos - Vector3.UP * 2
		)
		query.collision_mask = 1 # Sesuaikan dengan layer collision yang diperlukan
		
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			return world_pos
	
	return Vector3.ZERO

func find_room_id(cell: Vector3i) -> int:
	# Implementasi flood fill untuk identifikasi ruangan
	var visited = []
	var to_check = [cell]
	var room_id = 0
	
	while not to_check.is_empty():
		var current = to_check.pop_back()
		if visited.has(current):
			continue
			
		visited.append(current)
		for dir in [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.FORWARD, Vector3i.BACK]:
			var neighbor = current + dir
			if grid_map.get_cell_item(neighbor) == 0 and not visited.has(neighbor):
				to_check.append(neighbor)
				
	return visited.hash()

func calculate_difficulty():
	var floor_factor = difficulty_curve.sample(level_manager.current_floor / 10.0)
	max_active_enemies = ceil(max_active_enemies * (1.0 + (max_enemy_multiplier - 1.0) * floor_factor))

func spawn_enemies():
	var spawn_chance = base_spawn_chance * (1.0 + (level_manager.current_floor - 1) * 0.05)
	
	for point in spawn_points:
		if active_enemies.size() >= max_active_enemies:
			break
			
		if randf() < spawn_chance:
			spawn_random_enemy(point)

func spawn_random_enemy(position: Vector3):
	if enemy_scenes.is_empty():
		return
	
	var selected_scene = enemy_scenes.pick_random()
	var enemy = get_enemy_from_pool(selected_scene)
	
	enemy.global_position = position
	enemy.visible = true
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	enemy.current_hp = enemy.max_hp
	active_enemies.append(enemy)
	
	# Scale difficulty
	var floor_scale = 1.0 + (level_manager.current_floor - 1) * 0.1
	enemy.max_hp *= floor_scale
	enemy.attack_damage *= floor_scale

func get_enemy_from_pool(scene: PackedScene) -> BaseEnemy:
	for enemy in enemy_pool[scene]:
		if not enemy.visible:
			return enemy
	
	var new_enemy = scene.instantiate()
	add_child(new_enemy)
	enemy_pool[scene].append(new_enemy)
	return new_enemy

func reset_spawner():
	for enemy in active_enemies:
		enemy.visible = false
		enemy.process_mode = Node.PROCESS_MODE_DISABLED
		enemy.global_position = Vector3.ZERO
	active_enemies.clear()

func _exit_tree():
	for scene in enemy_pool:
		for enemy in enemy_pool[scene]:
			enemy.queue_free()
	enemy_pool.clear()
