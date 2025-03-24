extends Node

@onready var inv: Inventory = preload("res://UI/Inventory/Player_Inventory.tres")
@onready var slots:Array = $GridContainer.get_children() 
#@onready var grid = get_node("Grid")
@onready var desc = $Container/Item_desc
var inv_path = "res://UI/Inventory/Player_Inventory.tres"
var cur_slot:Inv_Slots
@onready var stats: PlayerStatsController = get_parent().get_parent().get_parent().get_child(0).get_child(1)
@onready var inventory_manager: InventoryManager = $InventoryManager

func _ready(): 
	inventory_manager.inventory = inv
	inventory_manager.update.connect(update_slots)
	inventory_manager.heal_pot.connect(stats.heal)
	inventory_manager.mana_pot.connect(stats.restore_mana)
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
	if cur_slot:
		inventory_manager.use_item(cur_slot)  # Gunakan InventoryManager
		if cur_slot.count == 0:
			inv.check()
			inv.update_inven()
			desc.hide_ui()
		update_slots()


func _on_save_btn_pressed() -> void:
	ResourceSaver.save(inv,inv_path)

func _on_heal_pot(amount: int):
	print("Heal pot used:", amount)
	

# Fungsi untuk menangani sinyal mana_pot
func _on_mana_pot(amount: int):
	print("Mana pot used:", amount)
