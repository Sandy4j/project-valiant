extends Area3D

@export var itemres: ItemData

func collect(inv: Inventory):
	inv.add(itemres)
	queue_free()

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
