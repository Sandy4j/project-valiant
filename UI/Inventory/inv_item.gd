extends Panel

@onready var ItemTxt = $Center/Panel/itm
@onready var Count = $Center/Panel/Count

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func update():
	if
	ItemTxt.visible = true
		ItemTxt.texture = slot.item.item_texture
		Count.text = str(slot.count)
		if slot.count > 1:
			Count.visible = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
