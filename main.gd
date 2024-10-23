extends Node

@onready var level_manager = $Levelmanager

func _ready():
	#level_manager.generate_level()
	#level_manager.level_generated.connect(_on_level_generated)
	pass


func _on_level_generated():
	print("Level telah selesai di-generate!")
