extends Resource

class_name Inv_Slots

@export var item: ItemData
@export var count: int

func use(item):
	#if item.health > 1:
		#GlobalSignal.heal_pot(item.health)
	#if item.mana > 1:
		#GlobalSignal.mana_pot(item.mana)
	count -= 1
	print(count)
