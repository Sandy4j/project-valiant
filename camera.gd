extends Node3D

@export var pitch_max := 50.0
@export var pitch_min := -50.0
@export var mouse_sensitivity := 0.2

var yaw := 0.0
var pitch := 0.0
var rotation_smoothness := 10.0

func _ready():
	# Mengatur mouse mode
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Reset rotasi awal
	rotation = Vector3.ZERO

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Konversi mouse movement ke rotasi dengan sensitivity
		yaw += -event.relative.x * mouse_sensitivity * 0.001
		pitch += -event.relative.y * mouse_sensitivity * 0.001
		
		# Membatasi rotasi vertikal (pitch)
		pitch = clamp(pitch, deg_to_rad(pitch_min), deg_to_rad(pitch_max))
		
	# Toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Smooth rotation
	rotation.x = lerpf(rotation.x, pitch, delta * rotation_smoothness)
	rotation.y = lerpf(rotation.y, yaw, delta * rotation_smoothness)
