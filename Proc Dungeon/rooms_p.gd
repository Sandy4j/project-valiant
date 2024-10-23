extends Node3D

func clear_rooms():
	for child in get_children():
		child.free()
