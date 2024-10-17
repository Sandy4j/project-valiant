extends Node3D

@export var procedural_dungeon_scene: PackedScene
@export var mesh_generator_scene: PackedScene
@export var player_scene: PackedScene

var current_dungeon: Node
var current_mesh_generator: Node
var player: Node

func _ready():
	start_new_level()

func clear_current_level():
	for child in get_children():
		child.queue_free()
	
	current_dungeon = null
	current_mesh_generator = null
	player = null
	
	GlobalSignal.reset()
	await get_tree().process_frame

func start_new_level(custom_seed: String = ""):
	await clear_current_level()
	
	current_dungeon = procedural_dungeon_scene.instantiate()
	add_child(current_dungeon)
	
	if current_dungeon.has_method("generate"):
		current_dungeon.generate()
	
	await get_tree().process_frame
	
	current_mesh_generator = mesh_generator_scene.instantiate()
	add_child(current_mesh_generator)
	
	# Initialize DungeonManager with new instances
	GlobalSignal.initialize(current_dungeon, current_mesh_generator)
	
	# Generate layout
	GlobalSignal.generate_layout()
	await GlobalSignal.layout_generated
	
	# Create mesh
	GlobalSignal.create_mesh()
	await GlobalSignal.mesh_generated
	
	await get_tree().process_frame
	
	# Spawn player logic
	var spawn_points = get_tree().get_nodes_in_group("spawn_point")
	if not spawn_points.is_empty():
		var spawn_point = spawn_points[0]
		spawn_player(spawn_point.global_transform.origin)
	else:
		push_error("No spawn points found in the scene!")

func spawn_player(spawn_position: Vector3):
	if player_scene:
		player = player_scene.instantiate()
		add_child(player)
		player.global_transform.origin = spawn_position
	else:
		push_error("Player scene not set!")

func restart_level():
	start_new_level()

func next_level():
	# Implementasi untuk level berikutnya, bisa dengan menambah kesulitan, ukuran, dll.
	# Misalnya, kita bisa menambah ukuran dungeon atau mengubah parameter lainnya
	if current_dungeon and current_dungeon.has_method("increase_difficulty"):
		current_dungeon.increase_difficulty()
	start_new_level()

# Fungsi ini bisa dipanggil ketika pemain mencapai level_change_scene
func on_level_complete():
	next_level()
