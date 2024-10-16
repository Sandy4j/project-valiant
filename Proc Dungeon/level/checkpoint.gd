extends Area3D

signal checkpoint_reached(checkpoint_position)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.is_in_group("player"):
		emit_signal("checkpoint_reached", global_transform.origin)
