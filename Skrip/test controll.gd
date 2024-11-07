extends Control

@onready var player = Player
@onready var lebal = $CanvasLayer/Label

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _on_button_pressed():
	LevelManager._ready()
	lebal.text = player.get_position()
