extends Node3D
class_name EnemySpawnManager

# Signals
signal room_cleared(room_id: int)
signal enemies_spawned(room_id: int, count: int)

# Node References
@export var dungeon_manager_path: NodePath
@onready var dungeon_manager: DungeonM = get_node(dungeon_manager_path)

# Enemy Settings
@export var enemy_scene: PackedScene
@export_group("Spawn Settings")
@export var min_enemies_per_room: int = 2
@export var max_enemies_per_room: int = 5
@export var spawn_delay: float = 0.2
@export var min_spawn_distance: float = 2.0  # Minimum distance between spawn points
@export var edge_margin: float = 1.0  # Margin from room edges

# Room Management
var active_rooms: Dictionary = {}  # Stores room data and state
var room_triggers: Dictionary = {}  # Stores room trigger areas
var spawned_enemies: Dictionary = {}  # Tracks enemies per room

# Internal tracking
var _current_floor: int = 0
var _player: Node3D = null

func _ready():
	setup_signals()
	
func setup_signals():
	if dungeon_manager:
		dungeon_manager.new_floor_ready.connect(_on_new_floor_ready)
	
	# Wait a frame to ensure dungeon is generated
	await get_tree().process_frame
	initialize_room_detection()

func initialize_room_detection():
	var grid_map = dungeon_manager.grid_map
	if !grid_map:
		push_error("GridMap not found!")
		return
		
	# Clear existing triggers
	for trigger in room_triggers.values():
		if is_instance_valid(trigger):
			trigger.queue_free()
	room_triggers.clear()
	active_rooms.clear()
	
	# Get all normal rooms (type 0)
	var normal_rooms = grid_map.get_used_cells_by_item(0)
	var room_id = 0
	
	for room_cells in normal_rooms:
		# Group adjacent cells into rooms
		if !is_cell_processed(room_cells):
			var room_data = process_room(grid_map, room_cells)
			if room_data:
				create_room_trigger(room_id, room_data)
				room_id += 1

func is_cell_processed(cell: Vector3i) -> bool:
	for room in active_rooms.values():
		if cell in room.cells:
			return true
	return false

func process_room(grid_map: GridMap, start_cell: Vector3i) -> Dictionary:
	var room_cells = PackedVector3Array()
	var queue = [start_cell]
	var min_bounds = Vector3i(99999, 0, 99999)
	var max_bounds = Vector3i(-99999, 0, -99999)
	
	# Flood fill to find connected room cells
	while !queue.is_empty():
		var current = queue.pop_front()
		if current in room_cells:
			continue
			
		if grid_map.get_cell_item(current) == 0:  # Normal room type
			room_cells.append(current)
			min_bounds = Vector3i(
				min(min_bounds.x, current.x),
				0,
				min(min_bounds.z, current.z)
			)
			max_bounds = Vector3i(
				max(max_bounds.x, current.x),
				0,
				max(max_bounds.z, current.z)
			)
			
			# Check neighbors
			for dir in [Vector3i.RIGHT, Vector3i.LEFT, Vector3i.FORWARD, Vector3i.BACK]:
				var next = current + dir
				if grid_map.get_cell_item(next) == 0 and !(next in room_cells):
					queue.append(next)
	
	if room_cells.size() > 0:
		return {
			"cells": room_cells,
			"min_bounds": min_bounds,
			"max_bounds": max_bounds,
			"center": (Vector3(min_bounds) + Vector3(max_bounds)) / 2,
			"size": Vector3(max_bounds - min_bounds) + Vector3.ONE,
			"cleared": false,
			"enemies_spawned": false
		}
	return {}

func create_room_trigger(room_id: int, room_data: Dictionary):
	var trigger = Area3D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = 2  # Assuming player is on layer 2
	
	var collision_shape = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	
	# Calculate trigger size based on room bounds
	var room_size = room_data.size
	shape.size = Vector3(
		room_size.x * dungeon_manager.grid_map.cell_size.x,
		4.0,  # Height of trigger
		room_size.z * dungeon_manager.grid_map.cell_size.z
	)
	
	collision_shape.shape = shape
	trigger.add_child(collision_shape)
	
	# Position trigger at room center
	var world_center = Vector3(
		room_data.center.x * dungeon_manager.grid_map.cell_size.x,
		2.0,  # Height offset
		room_data.center.z * dungeon_manager.grid_map.cell_size.z
	)
	trigger.position = world_center
	
	# Connect signals
	trigger.body_entered.connect(_on_room_entered.bind(room_id))
	trigger.body_exited.connect(_on_room_exited.bind(room_id))
	
	add_child(trigger)
	room_triggers[room_id] = trigger
	active_rooms[room_id] = room_data

func _on_room_entered(body: Node3D, room_id: int):
	if !body.is_in_group("player"):
		return
		
	var room_data = active_rooms.get(room_id)
	if !room_data or room_data.enemies_spawned:
		return
		
	spawn_enemies_in_room(room_id)

func _on_room_exited(body: Node3D, room_id: int):
	if !body.is_in_group("player"):
		return
	
	# Optional: Implement room exit behavior
	pass

func spawn_enemies_in_room(room_id: int):
	var room_data = active_rooms.get(room_id)
	if !room_data or room_data.enemies_spawned:
		return
		
	room_data.enemies_spawned = true
	var num_enemies = randi_range(min_enemies_per_room, max_enemies_per_room)
	var spawn_positions = calculate_spawn_positions(room_data, num_enemies)
	
	spawned_enemies[room_id] = []
	
	# Spawn enemies with delay
	for pos in spawn_positions:
		spawn_enemy(room_id, pos)
		await get_tree().create_timer(spawn_delay).timeout

func calculate_spawn_positions(room_data: Dictionary, count: int) -> Array:
	var positions = []
	var room_min = Vector3(room_data.min_bounds) * dungeon_manager.grid_map.cell_size
	var room_max = Vector3(room_data.max_bounds) * dungeon_manager.grid_map.cell_size
	
	# Add margin to spawn area
	room_min += Vector3(edge_margin, 0, edge_margin)
	room_max -= Vector3(edge_margin, 0, edge_margin)
	
	for i in count:
		var valid_position = false
		var attempt = 0
		var pos = Vector3.ZERO
		
		while !valid_position and attempt < 10:
			pos = Vector3(
				randf_range(room_min.x, room_max.x),
				1.0,  # Height above ground
				randf_range(room_min.z, room_max.z)
			)
			
			# Check distance from other spawn points
			valid_position = true
			for existing_pos in positions:
				if pos.distance_to(existing_pos) < min_spawn_distance:
					valid_position = false
					break
					
			attempt += 1
		
		if valid_position:
			positions.append(pos)
	
	return positions

func spawn_enemy(room_id: int, pos: Vector3):
	if !enemy_scene:
		push_error("Enemy scene not set!")
		return
		
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.position = pos
	
	# Track spawned enemy
	if !spawned_enemies.has(room_id):
		spawned_enemies[room_id] = []
	spawned_enemies[room_id].append(enemy)
	
	# Optional: Connect enemy death signal
	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died.bind(room_id, enemy))
	
	emit_signal("enemies_spawned", room_id, 1)

func _on_enemy_died(room_id: int, enemy: Node3D):
	if spawned_enemies.has(room_id):
		spawned_enemies[room_id].erase(enemy)
		
		# Check if room is cleared
		if spawned_enemies[room_id].is_empty():
			active_rooms[room_id].cleared = true
			emit_signal("room_cleared", room_id)

func _on_new_floor_ready():
	_current_floor += 1
	# Reset room state for new floor
	for enemies in spawned_enemies.values():
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.queue_free()
	
	spawned_enemies.clear()
	initialize_room_detection()

# Helper functions
func get_active_room_count() -> int:
	return active_rooms.size()

func get_cleared_room_count() -> int:
	var cleared = 0
	for room in active_rooms.values():
		if room.cleared:
			cleared += 1
	return cleared

func get_total_enemy_count() -> int:
	var total = 0
	for enemies in spawned_enemies.values():
		total += enemies.size()
	return total
