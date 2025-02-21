extends Button

@export var type: ItemData.Type
@onready var Slot = $Center
var item:Inv_Item

func insert(new_item: Inv_Item):
	item = new_item
	Slot.add_child(item)

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if get_child_count() > 0:
		var item := get_child(0)
		if item == data:
			return
		item.reparent(data.get_parent)
	data.reparent(self)

func _physics_process(delta: float) -> void:
	#check for equipment
	pass
