extends Resource
class_name Inv_Slots
signal heal_pot(amount:int)
signal  mana_pot(amount:int)

@export var item: ItemData
@export var count: int

func use(item):
	if item.health > 1:
		emit_signal("heal_pot", item.health)
	if item.mana > 1:
		emit_signal("mana_pot", item.mana)
	count -= 1
	print(count)
