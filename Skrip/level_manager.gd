extends Node

signal floor_changed(new_floor: int)
signal checkpoint_reached(floor: int)

const CHECKPOINT_INTERVAL = 3
const FLOOR_SCENE_PATH = "res://Floor/Floor%d.tscn"

var current_floor: int = 1
var last_checkpoint_floor: int = 1
var current_scene: Node = null
var player: Player = null
var dungeon_manager: DungeonM = null

func _ready() -> void:
	#load_floor(current_floor)
	await get_tree().process_frame
	dungeon_manager = get_tree().get_first_node_in_group("dungeon_manager")
	player = get_tree().get_first_node_in_group("player")

func advance_floor() -> void:
	if player:
		player.queue_free()
		await player.tree_exited

	current_floor += 1
	floor_changed.emit(current_floor)
	load_floor(current_floor)
	await get_tree().process_frame
	dungeon_manager.new_floor()
	
	if current_floor % CHECKPOINT_INTERVAL == 0:
		save_checkpoint()

func load_floor(floor_number: int) -> void:
	cleanup_current_scene()

	var floor_path = FLOOR_SCENE_PATH % floor_number
	var floor_scene = load(floor_path)
	
	if floor_scene:
		current_scene = floor_scene.instantiate()
		get_tree().root.call_deferred("add_child", current_scene)
		await get_tree().process_frame
	else:
		push_error("Could not load floor scene: " + floor_path)

func cleanup_current_scene() -> void:
	if current_scene and is_instance_valid(current_scene):
		current_scene.queue_free()
		await current_scene.tree_exited

func save_checkpoint() -> void:
	last_checkpoint_floor = current_floor
	checkpoint_reached.emit(current_floor)
	print("Checkpoint saved at floor ", current_floor)

func reset_to_checkpoint() -> void:
	current_floor = last_checkpoint_floor

	load_floor(current_floor)
	await get_tree().process_frame
	
	if current_floor == 1:
		if dungeon_manager:
			if player:
				player.queue_free()
				await player.tree_exited
			dungeon_manager.regenerate()
			await dungeon_manager.new_floor_ready
	
	floor_changed.emit(current_floor)

func get_current_floor() -> int:
	return current_floor

func get_last_checkpoint_floor() -> int:
	return last_checkpoint_floor
	
func reset_game() -> void:
	current_floor = 1
	last_checkpoint_floor = 1
	#player_stat_manager.clear_data()
	call_deferred("load_floor", current_floor)
	floor_changed.emit(current_floor)
