extends Node
class_name LevelManager

signal floor_changed(new_floor: int)
signal checkpoint_reached(floor: int)

const CHECKPOINT_INTERVAL = 3

var current_floor: int = 1
var last_checkpoint_floor: int = 1
var player: CharacterBody3D = null
var dungeon_manager: DungeonM = null
@onready var stats: PlayerStatsController = $PlayerFunction/PlayerStats

func _ready() -> void:
	await get_tree().process_frame
	dungeon_manager = get_tree().get_first_node_in_group("dungeon_manager")
	player = get_tree().get_first_node_in_group("player")
	if dungeon_manager:
		dungeon_manager.dungeon_generation_completed.connect(_on_dungeon_generation_completed)
	print("lantai :", current_floor)

func advance_floor() -> void:
	var enemy_spawner = get_tree().get_first_node_in_group("enemy_spawner")
	if enemy_spawner and enemy_spawner.has_method("cleanup_enemies"):
		enemy_spawner.cleanup_enemies()
	
	# Simpan statistik player sebelum dihapus
	if player:
		var player_stats = player.get_node_or_null("PlayerFunction/PlayerStats")
		if player_stats:
			GlobalSignal.saved_stats = player_stats.save_stats()
			print("LevelManager: Saved player stats before advancing floor: ", GlobalSignal.saved_stats)
		else:
			print("LevelManager: Could not find PlayerStats node")
			
		player.queue_free() 
		await player.tree_exited
		player = null

	current_floor += 1
	floor_changed.emit(current_floor)
	
	# Pastikan custom_seed kosong untuk menghasilkan floor baru
	if dungeon_manager:
		dungeon_manager.custom_seed = ""
		dungeon_manager.new_floor()
		
	print("lantai :", current_floor)
	if current_floor % CHECKPOINT_INTERVAL == 0:
		save_checkpoint()

func _on_dungeon_generation_completed() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func save_checkpoint() -> void:
	last_checkpoint_floor = current_floor
	checkpoint_reached.emit(current_floor)
	print("Checkpoint saved at floor ", current_floor)

func reset_to_checkpoint() -> void:
	current_floor = last_checkpoint_floor

	if player:
		player.queue_free()
		await player.tree_exited
		player = null
		
	dungeon_manager.regenerate()
	floor_changed.emit(current_floor)

func get_current_floor() -> int:
	return current_floor

func get_last_checkpoint_floor() -> int:
	return last_checkpoint_floor
	
func reset_game() -> void:
	current_floor = 1
	last_checkpoint_floor = 1
	
	# Reset player stats if needed
	# player_stat_manager.clear_data()
	if player:
		player.queue_free()
		await player.tree_exited
		player = null
	dungeon_manager.regenerate()
	floor_changed.emit(current_floor)
