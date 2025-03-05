extends Node
class_name PlayerInputController

signal camera_rotated(rotation)
signal toggle_inventory(is_open)

var camera_rotation: float = 0.0
var inventory_open: bool = false


func _unhandled_input(event):
	
	if Input.is_action_just_pressed("suicide"):
		get_parent().Hited(1000)
		
	if Input.is_action_just_pressed("inven"):
		inventory_open = !inventory_open
		emit_signal("toggle_inventory", inventory_open)

func get_movement_direction(cam_rotation: float) -> Vector3:
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var input_vector3 = Vector3(input_dir.x, 0, input_dir.y)
	
	if input_vector3 != Vector3.ZERO:
		var cam_basis = Transform3D(Basis.from_euler(Vector3(0, cam_rotation, 0)))
		return (cam_basis * input_vector3).normalized()
	
	return Vector3.ZERO
