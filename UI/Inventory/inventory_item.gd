class_name  Inventory_Item
extends TextureRect

@export var data: ItemData

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if data:
		expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture = data.item_texture
		tooltip_text = "Name: %s \n%s \nStats: %s Damage, %s Defense %s Health" % [data.item_name,data.item_description,data.item_damage,data.item_defense,data.item_health,]
		if data.stackable:
			var label = Label.new()
			label.text = str(data.count)
			label.position = Vector2(24,16)
			add_child(label)

func init(d: ItemData) -> void:
	data = d

func _get_drag_data(at_position: Vector2):
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
