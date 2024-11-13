extends  Resource
class_name Inventory

signal  update

@export var slots: Array[Inv_Slots]

func add(item:ItemData):
	#aliran 1
	var Slot = slots.filter(func(slot): return slot.item == item)
	if !Slot.is_empty():
		Slot[0].count += 1
	else :
		var emptySlot = slots.filter(func (slot): return slot.item == null)
		if !emptySlot.is_empty():
			emptySlot[0].item = item
			emptySlot[0].count = 1
	#ngalir dewe
	#for i in range(slots.size()):
		#if slots[i].item == item:
			#slots[i].count += 1
			#break
		#if !slots[i].item :
			#slots[i].item = item
			#break
	update.emit()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == 1) and (event.button_mask == 1):
			print("ko")
			if slots.filter(func(slot): return slot.item == null):
				print("song")
