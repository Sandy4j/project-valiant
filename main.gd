extends Node

@onready var Player
@onready var damage_area = $StaticBody3D2/tes
@onready var damage_timer = $cd

var is_damaging = false

func _ready():
	#damaged.connect(Player.Hited)
	pass

func _on_tes_body_entered(body):
	if body is Player:
		start_damaging()

func _on_tes_body_exited(body):
	if body is Player:
		stop_damaging()

func start_damaging():
	if not is_damaging:
		is_damaging = true
		damage_timer.start()
		apply_damage()  # Apply damage immediately

func stop_damaging():
	is_damaging = false
	damage_timer.stop()
	print("stop")

func apply_damage():
	if is_damaging:
		GlobalSignal.damaged.emit(20)
		print("damage applied")

func _on_cd_timeout():
	apply_damage()
