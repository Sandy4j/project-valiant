extends  Resource
class_name Inventory

signal  update

@export var slots: Array[Inv_Slots]

func add(item:ItemData):
	#aliran 2
	for i in range(slots.size()):
		if slots[i].item == item:
			slots[i].count += 1
			break
		if !slots[i].item :
			slots[i].item = item
			break
	update.emit()

func check():
	for i in range(slots.size()):
		if slots[i].count == 0:
			slots[i].item = null

func update_inven():
	for i in range(slots.size()-1):
		if !slots[i].item && slots[i+1].item:
			slots[i].item = slots[i+1].item
			slots[i].count = slots[i+1].count
			slots[i+1].item = null
			slots[i+1].count = 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if (event.button_index == 1) and (event.button_mask == 1):
			print("ko")
			if slots.filter(func(slot): return slot.item == null):
				print("song")

#aliran 1 ( update)
	#var Slot = slots.filter(func(slot): return slot.item == item)
	#if !Slot.is_empty():
		#Slot[0].count += 1
	#else :
		#var emptySlot = slots.filter(func (slot): return slot.item == null)
		#if !emptySlot.is_empty():
			#emptySlot[0].item = item
			#emptySlot[0].count = 1
