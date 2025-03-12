extends Node2D

@onready var animate = $AnimationPlayer
@onready var bg = $bg

func _ready():
	bg.visible = false

func dial_show():
	animate.play("dialogue_appear")

func dial_hide():
	animate.play_backwards("dialogue_appear")
