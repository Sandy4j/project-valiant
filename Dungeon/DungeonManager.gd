@tool
extends Node3D

signal custom_seed_changed(new_seed: String)

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
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

var player_instance: Node3D = null

func start_dungeon() -> void:
	if not Engine.is_editor_hint():
		generate_dungeon()
		await get_tree().create_timer(0.1).timeout
		spawn_player()

func generate_dungeon() -> void:
	# Step 1: Generate the procedural layout using GridMap
	if grid_map:
		grid_map.generate()
		await get_tree().create_timer(0.1).timeout
		
		# Step 2: Create the mesh dungeon using DunMesh
		if dungeon_mesh:
			dungeon_mesh.create_dungeon()
			
			# Step 3: Hide the GridMap after generation
			grid_map.hide()

func spawn_player() -> void:
	if not player_scene:
		push_warning("Player scene not set in DungeonManager!")
		return
		
	# Remove existing player if any
	if player_instance:
		player_instance.queue_free()
	
	# Find start room position
	var start_room_nodes = get_tree().get_nodes_in_group("start_room")
	if start_room_nodes.is_empty():
		push_warning("No start room found!")
		return
		
	# Get the first start room node
	var start_room = start_room_nodes[0]
	
	# Instance the player
	player_instance = player_scene.instantiate()
	add_child(player_instance)
	
	if Engine.is_editor_hint():
		player_instance.owner = get_tree().edited_scene_root
	
	# Position player at start room with slight offset to ensure they're inside
	player_instance.position = start_room.position + Vector3(1.0, 0.0, 0.0)

# Optional: Function to manually trigger regeneration
func regenerate() -> void:
	if Engine.is_editor_hint():
		generate_dungeon()
		await get_tree().create_timer(0.1).timeout
		spawn_player()
