extends Node

@onready var inv: Inventory = preload("res://UI/Inventory/Player_Inventory.tres")
@onready var slots:Array = $GridContainer.get_children() 
@onready var grid = get_node("Grid")

func _ready(): 
	connectSlots()
	inv.update.connect(update_slots)
	update_slots()

func connectSlots():
	for slot in slots:
		if slot and slot.has_signal("pressed"): 
			var cal = Callable(onSlotClicked).bind(slot)
			slot.pressed.connect(cal)

func update_slots():
	for i in range(min(inv.slots.size(), slots.size())):
		slots[i].update(inv.slots[i])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func onSlotClicked(slot):
	slot.inv
