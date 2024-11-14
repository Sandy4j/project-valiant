extends Node
class_name EnemySpawner

signal enemies_spawned(count: int)
signal floor_enemies_cleared

@export var grid_map_path: NodePath

@export_group("Enemy Settings")
@export var enemy_scenes: Array[PackedScene] = []
@export var min_enemies_per_room: int = 1
@export var max_enemies_per_room: int = 3
@export var spawn_height: float = 1.0
@export var edge_margin: float = 1.0  # Distance from room edges

var grid_map: GridMap
var level_manager: LevelManager
var enemy_container: Node3D
var rng = RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("enemy_spawner")
	setup_references()
	setup_connections()
	setup_container()

func setup_references() -> void:
	if !grid_map_path.is_empty():
		grid_map = get_node(grid_map_path)
	else:
		push_warning("GridMap path not set in EnemySpawner!")

func setup_connections() -> void:
	if level_manager:
		level_manager.floor_changed.connect(_on_floor_changed)

func setup_container() -> void:
	enemy_container = Node3D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)

func _on_floor_changed(new_floor: int) -> void:
	clear_enemies()
	# Wait a bit for the new floor to fully generate
	await get_tree().create_timer(0.3).timeout
	spawn_enemies_in_rooms()

func clear_enemies() -> void:
	for child in enemy_container.get_children():
		child.queue_free()
	floor_enemies_cleared.emit()

func spawn_enemies_in_rooms() -> void:
	if !is_instance_valid(grid_map):
		push_error("GridMap reference is invalid!")
		return
		
	if enemy_scenes.is_empty():
		push_warning("No enemy scenes configured in EnemySpawner!")
		return
		
	var normal_rooms = get_normal_room_cells()
	var total_enemies = 0
	
	for room_cells in normal_rooms:
		var enemy_count = rng.randi_range(min_enemies_per_room, max_enemies_per_room)
		var spawn_positions = calculate_spawn_positions(room_cells, enemy_count)
		
		for pos in spawn_positions:
			spawn_enemy(pos)
			total_enemies += 1
			
	enemies_spawned.emit(total_enemies)
	print("Spawned ", total_enemies, " enemies across ", normal_rooms.size(), " rooms")

func get_normal_room_cells() -> Array:
	var used_cells = grid_map.get_used_cells()
	var room_cells = {}
	
	# Filter out non-normal room cells first
	var normal_cells = used_cells.filter(func(cell): 
		var cell_type = grid_map.get_cell_item(cell)
		return cell_type == 0 # Only normal room cells
	)
	
	# Group cells by their connected regions
	for cell in normal_cells:
		var room_id = find_room_id(cell, room_cells)
		if room_id == -1:
			room_id = room_cells.size()
			room_cells[room_id] = []
		room_cells[room_id].append(cell)
	
	return room_cells.values()

func find_room_id(cell: Vector3i, room_cells: Dictionary) -> int:
	for room_id in room_cells:
		for room_cell in room_cells[room_id]:
			if are_cells_adjacent(cell, room_cell):
				return room_id
	return -1

func are_cells_adjacent(cell1: Vector3i, cell2: Vector3i) -> bool:
	return cell1.distance_squared_to(cell2) <= 1

func calculate_spawn_positions(room_cells: Array, enemy_count: int) -> Array:
	var positions = []
	var cell_size = grid_map.cell_size
	
	# Calculate room bounds
	var min_x = INF
	var max_x = -INF
	var min_z = INF
	var max_z = -INF
	
	for cell in room_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_z = min(min_z, cell.z)
		max_z = max(max_z, cell.z)
	
	# Calculate spawn area with margins
	var spawn_min_x = min_x * cell_size.x + edge_margin
	var spawn_max_x = (max_x + 1) * cell_size.x - edge_margin
	var spawn_min_z = min_z * cell_size.z + edge_margin
	var spawn_max_z = (max_z + 1) * cell_size.z - edge_margin
	
	# Generate random positions within the room
	for i in enemy_count:
		var spawn_pos = Vector3(
			rng.randf_range(spawn_min_x, spawn_max_x),
			spawn_height,
			rng.randf_range(spawn_min_z, spawn_max_z)
		)
		positions.append(spawn_pos)
	
	return positions

func spawn_enemy(pos: Vector3) -> void:
	var enemy_scene = enemy_scenes.pick_random()
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		enemy_container.add_child(enemy)
		enemy.global_position = pos

# Optional: Method to get current enemy count
func get_enemy_count() -> int:
	return enemy_container.get_child_count()

# Optional: Method to manually trigger enemy spawning (useful for testing)
func debug_spawn_enemies() -> void:
	clear_enemies()
	spawn_enemies_in_rooms()
