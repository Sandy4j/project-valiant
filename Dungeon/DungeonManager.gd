@tool
extends Node3D
class_name DungeonM

signal custom_seed_changed(new_seed: String)
signal new_floor_ready()

func regenerate_for_new_floor() -> void:
	generate_dungeon()
	emit_signal("new_floor_ready")

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

func _ready():
	add_to_group("dungeon_manager")

func generate_dungeon() -> void:
	if grid_map:
		grid_map.generate()
		await get_tree().create_timer(0.1).timeout
		if dungeon_mesh:
			dungeon_mesh.create_dungeon()
			grid_map.hide()

func new_floor() -> void:
	regenerate()
	emit_signal("new_floor_ready")

func spawn_player(y_offset: float = 2.0) -> void:
	# Remove existing player instance if it exists
	if player_instance:
		player_instance.queue_free()
	
	# Make sure we have a player scenew
	if !player_scene:
		push_warning("Player scene not set!")
		return
	
	# Find start room position (look for cells with item index 4)
	var start_cells = grid_map.get_used_cells_by_item(4)
	if start_cells.is_empty():
		push_warning("No start room found!")
		return
		
	# Get the leftmost cell of the start room
	var start_pos = start_cells[0]
	for cell in start_cells:
		if cell.x < start_pos.x:
			start_pos = cell
	
	# Instance the player
	player_instance = player_scene.instantiate()
	add_child(player_instance)
	
	# Calculate world position (using GridMap's cell size)
	var world_pos = Vector3(
		start_pos.x * grid_map.cell_size.x + grid_map.cell_size.x,
		y_offset,  # Offset Y to ensure player spawns above the floor
		start_pos.z * grid_map.cell_size.z + grid_map.cell_size.z * 0.5
	)
	
	player_instance.position = world_pos

func regenerate() -> void:
		generate_dungeon()
		await get_tree().create_timer(0.1).timeout
		spawn_player()
