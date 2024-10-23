extends Node


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var slot = Inventory_Slot.new()
	var slot1 = Inventory_Slot.new()
	$Grid.add_child(slot)
	$Grid.add_child(slot1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
