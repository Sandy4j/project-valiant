extends Node3D

class_name LevelDoor

@export var is_next_floor := true
@onready var interaction_marker = $InteractionMarker

var can_interact = false
var is_door_open = false

func _ready():
	# Sembunyikan marker interaksi saat mulai
	if interaction_marker:
		interaction_marker.hide()

func _input(event):
	if can_interact and event.is_action_pressed("interact"):
		interact()

func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		can_interact = true
		show_interaction_marker()

func _on_area_3d_body_exited(body):
	if body.is_in_group("player"):
		can_interact = false
		hide_interaction_marker()

func show_interaction_marker():
	if interaction_marker:
		interaction_marker.show()
		interaction_marker.scale = Vector3.ONE * 1

func hide_interaction_marker():
	if interaction_marker:
		interaction_marker.hide()

func interact():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if is_door_open or not can_interact:
		return
	
	is_door_open = true
	if level_manager:
		level_manager.advance_floor()
	else:
		push_error("LevelManager not found!")
