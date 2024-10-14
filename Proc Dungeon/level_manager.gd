extends Node3D

class_name LevelManager

@export var procedural_dungeon_scene: PackedScene
@export var player_scene: PackedScene

var current_dungeon: Node
var player: Node

signal level_completed

func _ready():
	start_game()

func start_game():
	initialize_level()

func initialize_level():
	if current_dungeon:
		current_dungeon.queue_free()
	
	current_dungeon = procedural_dungeon_scene.instantiate()
	add_child(current_dungeon)
	current_dungeon.generate()
	
	spawn_player()
	connect_exit_signal()

func spawn_player():
	if player:
		player.queue_free()
	
	player = player_scene.instantiate()
	add_child(player)
	
	var spawn_point = current_dungeon.get_node("SpawnPoint")
	if spawn_point:
		player.global_position = spawn_point.global_position

func connect_exit_signal():
	var exit_point = current_dungeon.get_node("ExitPoint")
	if exit_point and exit_point.has_signal("player_entered"):
		exit_point.connect("player_entered", _on_exit_point_entered)

func _on_exit_point_entered():
	emit_signal("level_completed")
	go_to_next_level()

func go_to_next_level():
	# Simpan data yang diperlukan (misalnya, skor pemain)
	initialize_level()

func _process(delta):
	if player and current_dungeon:
		check_player_at_exit()

func check_player_at_exit():
	var exit_point = current_dungeon.get_node("ExitPoint")
	if exit_point:
		if player.global_position.distance_to(exit_point.global_position) < 1.0:
			_on_exit_point_entered()
