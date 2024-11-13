extends Panel

class_name  item_gui

@onready var ItemTxt = $itm
@onready var Count = $Count

var slot: Inv_Slots

func update():
	if !slot || !slot.item: return
	ItemTxt.visible = true
	ItemTxt.texture = slot.item.item_texture
	Count.text = str(slot.count)
	if slot.count > 1:
		Count.visible = true
	else:
		Count.visible = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
