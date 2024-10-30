@tool
class_name EnemyConfig
extends Resource

@export_group("Enemy Settings")
@export var enemy_scene: PackedScene
@export var enemy_name: String = "Enemy"

@export_group("Spawn Settings")
@export_range(0.1, 10.0) var spawn_weight: float = 1.0
@export_range(0, 5) var min_per_room: int = 0
@export_range(0, 10) var max_per_room: int = 2
@export_range(0.0, 1.0) var spawn_chance: float = 1.0

@export_group("Level Restrictions")
@export var minimum_dungeon_level: int = 1  # Minimum dungeon level for this enemy to appear
@export var is_elite: bool = false  # If true, treated as a special enemy

# Optional validation
func _validate_config() -> bool:
	if not enemy_scene:
		push_error("Enemy scene not set for %s config" % enemy_name)
		return false
	if min_per_room > max_per_room:
		push_error("Min enemies cannot be greater than max for %s" % enemy_name)
		return false
	return true

# Optional: Helper method to get spawn probability based on dungeon level
func get_spawn_probability(dungeon_level: int) -> float:
	if dungeon_level < minimum_dungeon_level:
		return 0.0
	return spawn_chance
