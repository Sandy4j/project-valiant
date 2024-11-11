extends Button

@export var type: ItemData.Type
@onready var ItemTxt = $Center/Panel/itm
@onready var Count = $Center/Panel/Count

#func init(t: ItemData.Type, cms:Vector2) -> void:
	#type = t
	#custom_minimum_size = cms

func update(slot: Inv_Slots):
	if !slot.item:
		ItemTxt.visible = false 
		Count.visible = false
	else:
		ItemTxt.visible = true
		ItemTxt.texture = slot.item.item_texture
		Count.text = str(slot.count)
		if slot.count > 1:
			Count.visible = true



func _drop_data(at_position: Vector2, data: Variant) -> void:
	if get_child_count() > 0:
		var item := get_child(0)
		if item == data:
			return
		item.reparent(data.get_parent)
	data.reparent(self)

func _physics_process(delta: float) -> void:
	#check for equipment
	pass
