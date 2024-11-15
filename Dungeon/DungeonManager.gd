@tool
extends Node3D
class_name DungeonM

signal custom_seed_changed(new_seed: String)
signal new_floor_ready()
signal dungeon_generation_completed()

var nav_region: NavigationRegion3D

func _ready():
	add_to_group("dungeon_manager")

@export var start : bool = false : set = set_start
func set_start(_val:bool)->void:
	if Engine.is_editor_hint():
		generate_dungeon()

@export var grid_map_path: NodePath
@export var dungeon_mesh_path: NodePath
@export var player_scene: PackedScene

@onready var grid_map: GridMap = get_node(grid_map_path)
@onready var dungeon_mesh: Node3D = get_node(dungeon_mesh_path)

@export var border_size : int = 35 : set = set_border_size
func set_border_size(val : int)->void:
	border_size = val
	if Engine.is_editor_hint():
		grid_map.visualize_border()

@export_group("Layout Setting")
@export_range(0, 1) var survival_chance: float = 0.25
@export var room_number: int = 6
@export var room_margin: int = 2
@export var room_recursion: int = 50
@export var room_height: float = 4.0
@export var min_room_size: int = 2
@export var max_room_size: int = 8
@export_multiline var custom_seed: String = "" : set = set_custom_seed
func set_custom_seed(val: String) -> void:
	custom_seed = val
	custom_seed_changed.emit(val)
	
@export_group("Mesh Setting")
@export var mesh_size : float = 1.0
@export var grid_scale : float = 1.0
@export var dun_cell_scene : PackedScene
@export var start_room_scene: PackedScene
@export var end_room_scene: PackedScene

var player_instance: CharacterBody3D = null

func cleanup_dungeon():
	if grid_map:
		grid_map.clear()

	if dungeon_mesh:
		dungeon_mesh.clear_room_instances()
		for child in dungeon_mesh.get_children():
			dungeon_mesh.remove_child(child)
			child.queue_free()
			
	if nav_region:
		nav_region.navigation_mesh = null
		nav_region.enabled = false

func generate_dungeon() -> void:
	cleanup_dungeon()
	if grid_map:
		grid_map.generate()
		await get_tree().create_timer(0.1).timeout
		if dungeon_mesh:
			dungeon_mesh.create_dungeon()
			grid_map.hide()
			await get_tree().create_timer(0.1).timeout
			generate_navigation_mesh()
			dungeon_generation_completed.emit()

func generate_navigation_mesh() -> void:
	if !nav_region:
		return
	var nav_mesh = NavigationMesh.new()

	nav_mesh.cell_size = 0.1 
	nav_mesh.cell_height = 0.1
	nav_mesh.agent_height = 1.0
	nav_mesh.agent_radius = 0.35
	nav_mesh.agent_max_climb = 0.25
	
	var vertices: PackedVector3Array = []
	var indices: PackedInt32Array = []
	var used_cells = grid_map.get_used_cells()
	for cell in used_cells:
		var cell_item = grid_map.get_cell_item(cell)
		if cell_item != 3: 
			var world_pos = grid_map.map_to_local(cell)

			var cell_size = grid_map.cell_size
			var half_size = cell_size * 0.5
			
			var base_idx = vertices.size()
			vertices.append(world_pos + Vector3(-half_size.x, 0, -half_size.z))
			vertices.append(world_pos + Vector3(half_size.x, 0, -half_size.z))
			vertices.append(world_pos + Vector3(half_size.x, 0, half_size.z))
			vertices.append(world_pos + Vector3(-half_size.x, 0, half_size.z))
			
			indices.append(base_idx)
			indices.append(base_idx + 1)
			indices.append(base_idx + 2)
			indices.append(base_idx)
			indices.append(base_idx + 2)
			indices.append(base_idx + 3)
			
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_INDEX] = indices
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	nav_mesh.create_from_mesh(array_mesh)
	nav_region.navigation_mesh = nav_mesh
	nav_region.enabled = true

func new_floor() -> void:
	cleanup_dungeon()
	if player_instance:
		player_instance.queue_free()
		player_instance = null
	
	await regenerate()
	emit_signal("new_floor_ready")

func spawn_player(y_offset: float = 2.0) -> void:
	if !dungeon_mesh.start_room_instance:
		await dungeon_generation_completed
	
	var start_room = dungeon_mesh.start_room_instance

	var spawn_point = start_room.get_node_or_null("din/pintu/spawnpoint")
	if !spawn_point:
		push_error("SpawnPoint node not found in start room at path: din/pintu/spawnpoint")
		return
		
	if player_instance:
		player_instance.queue_free()
		player_instance = null
	
	# Instance the player
	player_instance = player_scene.instantiate()
	add_child(player_instance)

	await get_tree().process_frame
	player_instance.global_position = spawn_point.global_position
	
	var model = player_instance.get_node_or_null("Rogue")
	if model:
		model.rotation.y = deg_to_rad(90)

func regenerate() -> void:
	cleanup_dungeon()
	generate_dungeon()
	await dungeon_generation_completed
	spawn_player()
