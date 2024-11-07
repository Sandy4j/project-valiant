extends WorldEnvironment

@onready var DungMan = $DungeonManager
@onready var spawn_manager: SpawnManager = $Node3D
@export var enemy_scene: PackedScene

func _ready():
	DungMan.new_floor_ready.connect(spawn_enemies)
	DungMan.regenerate()

func spawn_enemies():
	var spawn_points = spawn_manager.get_random_spawn_points()
	print("Spawn points:", spawn_points)
	
	# Spawn enemies at these points
	for point in spawn_points:
		var enemy = enemy_scene.instantiate()
		add_child(enemy)
		enemy.global_position = point
