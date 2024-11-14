extends WorldEnvironment

@onready var DungMan = $DungeonManager
@onready var enemyp = $EnemySP


func _ready():
	DungMan.regenerate()
	enemyp.debug_spawn_enemies()
	
