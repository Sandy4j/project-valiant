extends WorldEnvironment

func _ready():
	$LevelManager.add_to_group("level_manager")
	$DungeonManager.add_to_group("dungeon_manager")

	await get_tree().process_frame
	$DungeonManager.regenerate()

func _process(delta: float) -> void:
	var floor_label = $UI/FloorLabel
	if floor_label:
		$LevelManager.floor_changed.connect(func(new_floor): floor_label.text = "Floor: " + str(new_floor))
		
