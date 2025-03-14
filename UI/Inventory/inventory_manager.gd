extends Node
class_name InventoryManager

signal heal_pot(amount: int)
signal mana_pot(amount: int)
signal update()

@export var inventory: Inventory

func add(item: ItemData):
	inventory.add(item)
	emit_signal("update")

func use_item(slot: Inv_Slots):
	if slot.item:
		if slot.item.health > 1:
			emit_signal("heal_pot", slot.item.health)
		if slot.item.mana > 1:
			emit_signal("mana_pot", slot.item.mana)
		slot.count -= 1
		if slot.count <= 0:
			slot.item = null
		emit_signal("update")
