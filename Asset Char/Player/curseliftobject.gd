extends Area3D

class_name CurseLiftObject

signal curse_lift_collected(body)

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.has_method("collect_curse_lift"):
		emit_signal("curse_lift_collected", body)
		queue_free()
