@tool
extends Node3D
class_name DungeonM

signal custom_seed_changed(new_seed: String)
signal new_floor_ready()
signal dungeon_generation_completed()

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
@onready var level_manager = get_tree().get_first_node_in_group("level_manager")

@export var border_size : int = 15 : set = set_border_size
func set_border_size(val : int)->void:
	border_size = val
	if Engine.is_editor_hint():
		grid_map.visualize_border()

@export_group("Layout Setting")
@export_range(0, 1) var survival_chance: float = 0.25
@export var room_number: int = 4
@export var room_margin: int = 2
@export var room_recursion: int = 50
@export var room_height: float = 4.0
@export var min_room_size: int = 2
@export var max_room_size: int = 6
@export_multiline var custom_seed: String = "" : set = set_custom_seed
func set_custom_seed(val: String) -> void:
	custom_seed = val
	custom_seed_changed.emit(val)
	
@export_group("Floor Difficulty Scaling")
@export var base_room_number: int = 4
@export var rooms_per_floor_increase: float = 0.5
@export var base_survival_chance: float = 0.25
@export var survival_chance_per_floor_decrease: float = 0.01
	
@export_group("Mesh Setting")
@export var mesh_size : float = 1.0
@export var grid_scale : float = 1.0
@export var dun_cell_scene : PackedScene
@export var start_room_scene: PackedScene
@export var end_room_scene: PackedScene

var player_instance: CharacterBody3D = null
var current_floor: int = 1

func cleanup_dungeon():
	if grid_map:
		grid_map.clear()

	if dungeon_mesh:
		dungeon_mesh.clear_room_instances()
		for child in dungeon_mesh.get_children():
			dungeon_mesh.remove_child(child)
			child.queue_free()
			
	# Remove enemies, items, etc.
	#var entities = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("items")
	#for entity in entities:
		#entity.queue_free()

func generate_dungeon() -> void:
	cleanup_dungeon()
	
	# Set difficulty parameters based on floor number
	if level_manager:
		current_floor = level_manager.get_current_floor()

	room_number = base_room_number + floor(rooms_per_floor_increase * (current_floor - 1))
	survival_chance = max(0.1, base_survival_chance - (survival_chance_per_floor_decrease * (current_floor - 1)))
	if custom_seed == "":
		custom_seed = str(current_floor) + str(Time.get_unix_time_from_system())
		custom_seed_changed.emit(custom_seed)
	
	if grid_map:
		grid_map.generate()
		await get_tree().create_timer(0.1).timeout
		if dungeon_mesh:
			dungeon_mesh.create_dungeon()
			grid_map.hide()
			await get_tree().create_timer(0.1).timeout
			spawn_floor_content()
			
			dungeon_generation_completed.emit()

func spawn_floor_content() -> void:
	# This function would spawn enemies, items, etc. based on floor level
	# Example: var enemy_count = base_enemies + (current_floor * 2)
	pass

func new_floor() -> void:
	cleanup_dungeon()
	if player_instance:
		player_instance.queue_free()
		player_instance = null
	custom_seed = ""
	
	await regenerate()
	emit_signal("new_floor_ready")

func spawn_player(y_offset: float = 2.0) -> void:
	if !dungeon_mesh.start_room_instance:
		await dungeon_generation_completed
	
	var start_room = dungeon_mesh.start_room_instance

	var spawn_point = start_room.get_node_or_null("din/pintu/spawnpoint")
	if !spawn_point:
		push_error("SpawnPoint node not found")
		return
		
	if player_instance:
		player_instance.queue_free()
		player_instance = null

	player_instance = player_scene.instantiate()
	add_child(player_instance)
	player_instance.add_to_group("player")

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
