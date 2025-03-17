extends Node
class_name EnemySpawner

@export_category("Spawn Settings")
@export var enemy_scenes: Array[PackedScene] = []
@export var max_active_enemies: int = 10
@export var pool_size: int = 15
@export var spawn_points_per_room: int = 3
@export var min_spawn_distance_from_player: float = 5.0

@export_category("Difficulty Settings")
@export var base_spawn_chance: float = 0.7
@export var difficulty_curve: Curve
@export var max_enemy_multiplier: float = 2.0

var dungeon_manager: DungeonM
var grid_map: GridMap
var dungeon_mesh: DungeonMesh
var level_manager: LevelManager

var enemy_pool: Dictionary = {}
var active_enemies: Array = []
var spawn_points: Array[Vector3] = []

func _ready():
	add_to_group("enemy_spawner")
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
	# First clean up any existing enemies
	clear_all_enemies()
	
	# Then generate new ones
	generate_spawn_points()
	calculate_difficulty()
	spawn_enemies()

func generate_spawn_points():
	spawn_points.clear()
	
	# Get all cells with normal rooms (cell type 0)
	var room_cells = grid_map.get_used_cells_by_item(0)
	
	# Skip if no rooms found
	if room_cells.is_empty():
		push_warning("No room cells found in the dungeon!")
		return
	
	# Step 1: Identify unique rooms by flood-fill algorithm
	var rooms = identify_unique_rooms(room_cells)
	
	# Step 2: Skip start and end rooms
	var start_cells = grid_map.get_used_cells_by_item(4)
	var end_cells = grid_map.get_used_cells_by_item(5)
	var excluded_cells = []
	
	# Add buffer zones around start/end rooms (don't spawn too close)
	for cell in start_cells:
		excluded_cells.append(cell)
		for x in range(-2, 3):
			for z in range(-2, 3):
				excluded_cells.append(Vector3i(cell.x + x, cell.y, cell.z + z))
				
	for cell in end_cells:
		excluded_cells.append(cell)
		for x in range(-2, 3):
			for z in range(-2, 3):
				excluded_cells.append(Vector3i(cell.x + x, cell.y, cell.z + z))
	
	for room in rooms:
		var valid_room_cells = []
		for cell in room:
			if not excluded_cells.has(cell):
				valid_room_cells.append(cell)
		if valid_room_cells.size() < 2:
			continue
			
		# Calculate center point of the room
		var center = Vector3i.ZERO
		for cell in valid_room_cells:
			center += cell
		center = Vector3i(center.x / valid_room_cells.size(), 0, center.z / valid_room_cells.size())
		
		# Generate spawn points based on room size
		var points_to_generate = min(spawn_points_per_room, valid_room_cells.size() / 2)
		var attempts = points_to_generate * 5  # Allow multiple attempts per point
		var room_points = []
		
		for _i in range(attempts):
			if room_points.size() >= points_to_generate:
				break
				
			# Pick a random cell from the room, preferring cells away from the edge
			var valid_inner_cells = valid_room_cells.filter(func(cell): 
				# Check if all adjacent cells are part of the room (inner cell)
				var is_inner = true
				for dir in [Vector3i.UP, Vector3i.DOWN, Vector3i.LEFT, Vector3i.RIGHT]:
					if not valid_room_cells.has(cell + dir):
						is_inner = false
						break
				return is_inner
			)
			
			var spawn_cell
			if valid_inner_cells.size() > 0:
				spawn_cell = valid_inner_cells[randi() % valid_inner_cells.size()]
			else:
				spawn_cell = valid_room_cells[randi() % valid_room_cells.size()]
			
			# Calculate world position from grid position
			var world_pos = dungeon_mesh.calculate_grid_to_world(Vector3(spawn_cell))
			
			# Check if this position is too close to existing spawn points
			var too_close = false
			for existing_point in room_points:
				if world_pos.distance_to(existing_point) < 1.5:
					too_close = true
					break
					
			if not too_close:
				room_points.append(world_pos)
				spawn_points.append(world_pos)
	
	print("Generated ", spawn_points.size(), " enemy spawn points across ", rooms.size(), " rooms")

# Identifies unique rooms using a simple flood fill algorithm
func identify_unique_rooms(room_cells: Array) -> Array:
	var rooms = []
	var visited = []
	
	for cell in room_cells:
		if visited.has(cell):
			continue
			
		var room = []
		var queue = [cell]
		
		while not queue.is_empty():
			var current = queue.pop_front()
			if visited.has(current):
				continue
				
			visited.append(current)
			room.append(current)
			
			# Check 4 adjacent cells (4-connectivity)
			for direction in [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.FORWARD, Vector3i.BACK]:
				var neighbor = current + direction
				if room_cells.has(neighbor) and not visited.has(neighbor):
					queue.append(neighbor)
		
		# Only add rooms with at least 4 cells (to avoid tiny spaces)
		if room.size() >= 4:
			rooms.append(room)
	
	return rooms

func calculate_difficulty():
	var floor_factor = difficulty_curve.sample(level_manager.current_floor / 10.0)
	max_active_enemies = ceil(max_active_enemies * (1.0 + (max_enemy_multiplier - 1.0) * floor_factor))

func spawn_enemies():
	var spawn_chance = base_spawn_chance * (1.0 + (level_manager.current_floor - 1) * 0.05)
	
	# Shuffle spawn points to ensure random distribution
	spawn_points.shuffle()
	
	for point in spawn_points:
		if active_enemies.size() >= max_active_enemies:
			break
			
		if randf() < spawn_chance:
			spawn_random_enemy(point)


func clear_all_enemies():
	for i in range(active_enemies.size() - 1, -1, -1):
		if i < active_enemies.size():
			var enemy = active_enemies[i]
			if is_instance_valid(enemy):
				if enemy.has_signal("enemy_died") and enemy.enemy_died.is_connected(_on_enemy_died):
					enemy.enemy_died.disconnect(_on_enemy_died)
				enemy.visible = false
				enemy.process_mode = Node.PROCESS_MODE_DISABLED
				enemy.global_position = Vector3.ZERO
			active_enemies.remove_at(i)

	for scene in enemy_pool:
		for enemy in enemy_pool[scene]:
			if is_instance_valid(enemy):
				if enemy.has_signal("enemy_died") and enemy.enemy_died.is_connected(_on_enemy_died):
					enemy.enemy_died.disconnect(_on_enemy_died)
				enemy.visible = false
				enemy.process_mode = Node.PROCESS_MODE_DISABLED
				enemy.global_position = Vector3.ZERO

func spawn_random_enemy(position: Vector3):
	if enemy_scenes.is_empty():
		return
	
	var selected_scene = enemy_scenes.pick_random()
	var enemy = get_enemy_from_pool(selected_scene)
	
	# Only continue if we got a valid enemy
	if not is_instance_valid(enemy):
		print("Warning: Failed to get valid enemy from pool")
		return
	
	enemy.global_position = position
	enemy.visible = true
	enemy.process_mode = Node.PROCESS_MODE_INHERIT
	enemy.current_hp = enemy.max_hp
	
	# Only connect if not already connected
	if enemy.has_signal("enemy_died") and not enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.connect(_on_enemy_died)
	
	active_enemies.append(enemy)
	
	# Scale difficulty
	var floor_scale = 1.0 + (level_manager.current_floor - 1) * 0.1
	enemy.max_hp *= floor_scale
	enemy.attack_damage *= floor_scale

func _on_enemy_died(enemy):
	if not is_instance_valid(enemy):
		return

	var index = -1
	for i in range(active_enemies.size()):
		if active_enemies[i] == enemy:
			index = i
			break
			
	if index != -1:
		active_enemies.remove_at(index)
	
	if is_instance_valid(enemy) and enemy.has_signal("enemy_died") and enemy.enemy_died.is_connected(_on_enemy_died):
		enemy.enemy_died.disconnect(_on_enemy_died)

func get_enemy_from_pool(scene: PackedScene) -> BaseEnemy:
	if not enemy_pool.has(scene):
		return null
		
	for enemy in enemy_pool[scene]:
		if is_instance_valid(enemy) and not enemy.visible:
			return enemy
	
	# If we get here, we need to create a new enemy
	var new_enemy = scene.instantiate()
	add_child(new_enemy)
	enemy_pool[scene].append(new_enemy)
	return new_enemy

func _exit_tree():
	# Extra safety to ensure all children are properly freed
	for scene in enemy_pool:
		for enemy in enemy_pool[scene]:
			if is_instance_valid(enemy):
				if enemy.has_signal("enemy_died") and enemy.enemy_died.is_connected(_on_enemy_died):
					enemy.enemy_died.disconnect(_on_enemy_died)
				enemy.queue_free()
	enemy_pool.clear()
	active_enemies.clear()
