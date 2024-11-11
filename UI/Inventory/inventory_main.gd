extends  Resource
class_name Inventory

signal  update

@export var slots: Array[Inv_Slots]

func add(item:ItemData):
	var itemslots = slots.filter(func (slot): return slot.item == item)
	if !itemslots.is_empty():
		itemslots[0].amount += 1
	else :
		var emptyslots = slots.filter(func(slot): return slot.item == null)
		if !emptyslots.is_empty():
			emptyslots[0].item = item
			emptyslots[0].amount = 1
	update.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == 1) and (event.button_mask == 1):
			print("ko")
			if slots.filter(func(slot): return slot.item == null):
				print("song")
