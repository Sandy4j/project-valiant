extends WorldEnvironment

@onready var DungMan = $DungeonManager

func _ready():
	DungMan.regenerate()
