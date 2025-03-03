extends Node

@onready var inv: Inventory = preload("res://UI/Inventory/Player_Inventory.tres")
@onready var slots:Array = $GridContainer.get_children() 
@onready var grid = get_node("Grid")
@onready var desc = $Container/Item_desc

var cur_slot:Inv_Slots

func _ready(): 
	connectSlots()
	inv.update.connect(update_slots)
	update_slots()
	print(cur_slot)

func connectSlots():
	for slot in slots:
		var cal = Callable(onSlotClicked)
		cal = cal.bind(slot)
		slot.pressed.connect(cal)

func update_slots():
	for i in range(min(inv.slots.size(), slots.size())):
		slots[i].update(inv.slots[i])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func onSlotClicked(slot):
	if slot.Slot.item:
		cur_slot = slot.Slot
		desc.hide_ui()
		desc.show_ui(slot.Slot.item)
	else:
		cur_slot = null
		desc.hide_ui()
	print(cur_slot)


func _on_item_btn_pressed() -> void:
	cur_slot.use(cur_slot.item)
	if cur_slot.count == 0:
		inv.check()
		inv.update_inven()
		desc.hide_ui()
	update_slots()
