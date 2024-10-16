class_name  Inventory_Slot
extends PanelContainer

@export var type: ItemData.Type

func init(t: ItemData.Type, cms:Vector2) -> void:
	type = t
	custom_minimum_size = cms
	
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is Inventory_Item:
		if type == ItemData.Type.MAIN:
			if get_child_count() == 0:
				return true
			else :
				if  type == data.get_parent().type:
					return true
				return get_child(0).data.type == data.data.type
		else :
			return data.data.type == type
	else :
		return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if get_child_count() > 0:
		var item := get_child(0)
		if item == data:
			return
		item.reparent(data.get_parent)

func _physics_process(delta: float) -> void:
	#check for equipment
	pass

func _gui_input(event: InputEvent) -> void:
	pass
