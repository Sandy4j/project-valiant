extends Control

@onready var Name = $item_name
@onready var txt = $item_texture
@onready var desc = $item_desc
@onready var effect:Array = $efcon.get_children()
@onready var btn = $item_btn

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hide_ui()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func hide_ui():
	Name.hide()
	txt.hide()
	desc.hide()
	btn.hide()
	$bg.hide()
	for i in effect:
		i.hide()

func show_ui(item:ItemData):
	Name.text = item.item_name
	txt.texture = item.item_texture
	desc.text = item.item_description
	btn.show()
	if item.type == ItemData.Kelas.MAIN:
		btn.text = "Use"
	elif item.type == ItemData.Kelas.CONSUMABLE:
		btn.text = "Consume"
	else:
		btn.text = "kontol"
	if item.type == ItemData.Kelas.CONSUMABLE:
		if item.health > 0 && item.mana > 0:
			effect[0].text = "Merestorasi " + str(item.health) + " HP yang hilang"
			effect[0].show()
			effect[1].text = "Memulihkan " + str(item.mana) + " Mana"
			effect[1].show()
		elif item.health > 0:
			effect[0].text = "Merestorasi " + str(item.health) + " HP yang hilang"
			effect[0].show()
		elif item.mana > 0:
			effect[0].text = "Memulihkan " + str(item.mana) + " Mana"
			effect[0].show()
	
	Name.show()
	txt.show()
	desc.show()
	btn.show()
	$bg.show()
