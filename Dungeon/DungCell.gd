@tool
extends Node3D


func remove_wall_up():
	if $wall_up != null:
		$wall_up.queue_free()
func remove_wall_down():
	if $wall_down != null:
		$wall_down.queue_free()
func remove_wall_left():
	if $wall_left != null:
		$wall_left.queue_free()
func remove_wall_right():
	if $wall_right != null:
		$wall_right.queue_free()
func remove_door_up():
	if $door_up != null:
		$door_up.queue_free()
func remove_door_down():
	if $door_down != null:
		$door_down.queue_free()
func remove_door_left():
	if $door_left != null:
		$door_left.queue_free()
func remove_door_right():
	if $door_right != null:
		$door_right.queue_free()
	
