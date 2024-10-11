extends Marker3D

@export var player_scene: PackedScene

func _ready():
	call_deferred("spawn_player")

func spawn_player():
	if player_scene:
		var player_instance = player_scene.instantiate()
		player_instance.global_transform = global_transform
		get_parent().add_child(player_instance)
	else:
		print("Error: Player scene not set in SpawnPoint")
