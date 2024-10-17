extends Area3D

signal level_completed

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("level_completed")
