extends Marker3D

@export var player_scene: PackedScene
var player_spawned = false

func _ready():
	call_deferred("spawn_player")

func spawn_player():
	if player_scene and not player_spawned:
		var player_instance = player_scene.instantiate()
		player_instance.global_transform = global_transform
		get_parent().add_child(player_instance)
		player_spawned = true
	elif player_spawned:
		print("Player already spawned")
	else:
		print("Error: Player scene not set in SpawnPoint")
