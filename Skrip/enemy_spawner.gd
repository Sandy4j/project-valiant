@tool
extends Node3D
class_name SpawnManager

@export var dungeon_manager_path: NodePath
@onready var dungeon_manager: DungeonM = get_node(dungeon_manager_path)

@export_group("Spawn Settings")
@export var min_enemy: int = 2
@export var max_enemy: int = 4
@export var spawn_points_per_room: int = 2
@export var exclusion_radius: int = 2  # New parameter to control exclusion zone size

signal spawn_points_generated(points: Array[Vector3])

var spawn_points: Array[Vector3] = []

func _ready() -> void:
	if dungeon_manager:
		dungeon_manager.new_floor_ready.connect(_on_new_floor_ready)
		await get_tree().create_timer(0.2).timeout
		generate_spawn_points()

func _on_new_floor_ready() -> void:
	await get_tree().create_timer(0.2).timeout
	generate_spawn_points()

func generate_spawn_points() -> void:
	spawn_points.clear()
	
	var grid_map = dungeon_manager.grid_map
	if !grid_map:
		push_error("GridMap not found!")
		return
	
	# Get all normal room cells (index 0)
	var room_cells = grid_map.get_used_cells_by_item(0)
	print("Found ", room_cells.size(), " room cells")
	
	# Get start and end room cells
	var start_room_cells = grid_map.get_used_cells_by_item(4)
	var end_room_cells = grid_map.get_used_cells_by_item(5)
	
	# Create smaller exclusion zones
	var exclusion_cells = []
	for special_cells in [start_room_cells, end_room_cells]:
		for special_cell in special_cells:
			# Add debug print for special cells
			print("Special cell found at: ", special_cell)
			for x in range(-exclusion_radius, exclusion_radius + 1):
				for z in range(-exclusion_radius, exclusion_radius + 1):
					var excluded_cell = Vector3i(special_cell.x + x, 0, special_cell.z + z)
					exclusion_cells.append(excluded_cell)
	
	# Debug print for exclusion cells
	print("Created ", exclusion_cells.size(), " exclusion cells")
	
	# Remove excluded cells and keep track of how many are removed
	var initial_count = room_cells.size()
	room_cells = room_cells.filter(func(cell): return cell not in exclusion_cells)
	print("Removed ", initial_count - room_cells.size(), " cells due to exclusion")
	print("After exclusion: ", room_cells.size(), " valid room cells")
	
	# Group cells into rooms with additional debugging
	var rooms = group_cells_by_rooms(room_cells)
	print("Found ", rooms.size(), " distinct rooms")
	
	# Print room sizes for debugging
	for i in range(rooms.size()):
		print("Room ", i, " size: ", rooms[i].size(), " cells")
	
	# Generate spawn points for each room
	for room in rooms:
		if room.size() >= 4:  # Only generate spawn points in rooms big enough
			var room_spawn_points = generate_room_spawn_points(room)
			spawn_points.append_array(room_spawn_points)
	
	print("Generated ", spawn_points.size(), " total spawn points")
	emit_signal("spawn_points_generated", spawn_points)

func group_cells_by_rooms(cells: Array) -> Array[Array]:
	var rooms: Array[Array] = []
	var processed_cells = []
	
	for cell in cells:
		if cell in processed_cells:
			continue
		
		var room = []
		var to_check = [cell]
		
		while to_check.size() > 0:
			var current = to_check.pop_front()
			if current in processed_cells:
				continue
				
			room.append(current)
			processed_cells.append(current)
			
			# Check all adjacent cells
			for offset in [
				Vector3i(1, 0, 0), Vector3i(-1, 0, 0),  # Left/Right
				Vector3i(0, 0, 1), Vector3i(0, 0, -1),  # Forward/Back
			]:
				var neighbor = current + offset
				if neighbor in cells and neighbor not in processed_cells and neighbor not in to_check:
					to_check.append(neighbor)
		
		if room.size() > 0:
			rooms.append(room)
	
	return rooms

func generate_room_spawn_points(room_cells: Array) -> Array[Vector3]:
	var room_spawn_points: Array[Vector3] = []
	
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
	
	# Calculate room center
	var center = Vector3(
		(min_x + max_x) / 2.0,
		0,
		(min_z + max_z) / 2.0
	)
	
	var cell_size = dungeon_manager.grid_map.cell_size
	var points_to_generate = spawn_points_per_room
	var attempts = 0
	var max_attempts = 50
	
	while points_to_generate > 0 and attempts < max_attempts:
		var random_cell = room_cells.pick_random()
		var spawn_point = Vector3(
			random_cell.x * cell_size.x + cell_size.x * 0.5,
			1.0,  # Slightly above ground
			random_cell.z * cell_size.z + cell_size.z * 0.5
		)
		
		# Check if point is far enough from other spawn points
		var is_valid = true
		for existing_point in room_spawn_points:
			if spawn_point.distance_to(existing_point) < cell_size.x * 1.2:
				is_valid = false
				break
		
		# Ensure point isn't too close to room edges (relaxed to 0.5 cell size)
		if is_valid:
			var distance_from_edge = min(
				spawn_point.x - min_x * cell_size.x,
				max_x * cell_size.x - spawn_point.x,
				spawn_point.z - min_z * cell_size.z,
				max_z * cell_size.z - spawn_point.z
			)
			if distance_from_edge < cell_size.x * 0.5:
				is_valid = false
		
		if is_valid:
			room_spawn_points.append(spawn_point)
			points_to_generate -= 1
			print("Added spawn point at: ", spawn_point)
		
		attempts += 1
	
	return room_spawn_points

func get_random_spawn_points(count: int = -1) -> Array[Vector3]:
	print("Total available spawn points: ", spawn_points.size())
	
	if spawn_points.is_empty():
		print("Warning: No spawn points available!")
		return []
	
	if count == -1:
		count = randi_range(min_enemy, max_enemy)
	
	print("Attempting to get ", count, " spawn points")
	
	var selected_points: Array[Vector3] = []
	var available_points = spawn_points.duplicate()
	
	for i in range(min(count, available_points.size())):
		var random_index = randi() % available_points.size()
		selected_points.append(available_points[random_index])
		available_points.remove_at(random_index)
	
	print("Selected ", selected_points.size(), " spawn points")
	return selected_points

# Debug function to visualize spawn points
func debug_draw_spawn_points() -> void:
	for point in spawn_points:
		var debug_mesh = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.3
		sphere.height = 0.6
		debug_mesh.mesh = sphere
		debug_mesh.position = point
		add_child(debug_mesh)
		
		# Create material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.RED
		material.emission_enabled = true
		material.emission = Color.RED
		debug_mesh.material_override = material
