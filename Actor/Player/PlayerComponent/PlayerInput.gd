extends Node
class_name PlayerInputController

signal camera_rotated(rotation)
signal UI_Change(state)
signal talk(indx)
signal paused

var mouse_show:bool
var ui_open:bool
var ui_closed:bool
@export var magics = Node

var camera_rotation: float = 0.0



func _input(event):
	if event is InputEventKey and event.pressed && !GlobalSignal.ui_show:
		if event.keycode == KEY_M:
			toggle_mouse_mode()

func toggle_mouse_mode():
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		mouse_show = true
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_show = false


func _unhandled_input(event):
	if Input.is_action_just_pressed("firebolt"):
		magics.cast_spell("firebolt")
	if Input.is_action_just_pressed("blizzard"):
		magics.cast_spell("blizzard")
	if Input.is_action_just_pressed("suicide"):
		get_parent().Hited(1000)
	if Input.is_action_just_pressed("inven"): 
		emit_signal("UI_Change",1)
		if !mouse_show:
			toggle_mouse_mode()
			ui_open = true
		elif !ui_open && mouse_show:
			ui_open = true
		elif ui_closed:
			ui_closed = false
			ui_open = false
			toggle_mouse_mode()
	if Input.is_action_just_pressed("stats"):
		emit_signal("UI_Change",2)
		if !mouse_show:
			toggle_mouse_mode()
			ui_open = true
		elif !ui_open && mouse_show:
			ui_open = true
		elif ui_closed:
			ui_closed = false
			ui_open = false
			toggle_mouse_mode()
	if Input.is_action_just_pressed("Pause") && !GlobalSignal.impaused:
		emit_signal("paused")
		toggle_mouse_mode()

func get_movement_direction(cam_rotation: float) -> Vector3:
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var input_vector3 = Vector3(input_dir.x, 0, input_dir.y)
	
	if input_vector3 != Vector3.ZERO:
		var cam_basis = Transform3D(Basis.from_euler(Vector3(0, cam_rotation, 0)))
		return (cam_basis * input_vector3).normalized()
	
	return Vector3.ZERO
