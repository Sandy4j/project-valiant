extends WorldEnvironment

@onready var floor_label = $UI/ColorRect/Label

func _ready():
	$LevelManager.add_to_group("level_manager")

	await get_tree().process_frame
	$DungeonManager.regenerate()
	floor_label.text = "Floor: " + str($LevelManager.current_floor)

func _process(delta: float) -> void:
	
	if floor_label:
		$LevelManager.floor_changed.connect(func(new_floor): floor_label.text = "Floor: " + str(new_floor))
		
