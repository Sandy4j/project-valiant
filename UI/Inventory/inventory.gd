extends Control

@onready var inv: Inventory = preload("res://UI/Inventory/Player_Inventory.tres")
@onready var item_class = preload("res://UI/Inventory/Item/item.tscn")
@onready var slots:Array = $GridContainer.get_children() 
@onready var grid = get_node("Grid")
@onready var item_logo = $Desc_Container/Panel/logo
@onready var item_name = $Desc_Container/Name
@onready var item_desc = $Desc_Container/Desc
@onready var item_btn = $Desc_Container/use_btn
@onready var desc = $Desc_Container.get_children()

var item_moved: item_gui

func _ready():
	desc_hide()
	connectSlots()
	inv.update.connect(update_slots)
	update_slots()

func connectSlots():
	for slot in slots:
		var cal = Callable(onSlotClicked)
		cal = cal.bind(slot)
		slot.pressed.connect(cal)

func update_slots():
	for i in range(min(inv.slots.size(), slots.size())):
		var inv_slot: Inv_Slots = inv.slots[i]
		
		if !inv_slot.item: continue
		
		var item: item_gui = slots[i].item
		if !item:
			item = item_class.instantiate()
			slots[i].insert(item)
			
		item.slot = inv_slot
		item.update()
		

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func onSlotClicked(slot):
	if slot.item: 
		desc_show()
		item_showed(slot.item.slot.item)
		return
	else:
		print("kosong")
		desc_hide()

func updateMoving():
	if !item_moved: return
	item_moved.global_position = get_global_mouse_position() - item_moved.size/2

func _input(event: InputEvent):
	updateMoving()

func item_showed(item:ItemData):
	item_logo.texture = item.item_texture
	item_name.text = item.item_name
	item_desc.text = item.item_description
	
	pass

func desc_hide():
	item_logo.visible = false
	item_name.visible = false
	item_desc.visible = false
	item_btn.visible = false

func desc_show():
	item_logo.visible = true
	item_name.visible = true
	item_desc.visible = true
	item_btn.visible = true
