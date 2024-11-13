extends Button

@export var type: ItemData.Type
@onready var bg = $Bg
@onready var CC: = $Center

var item: item_gui

func insert(itm: item_gui):
	item = itm
	CC.add_child(item)
	

func takeitem():
	var item: item_gui
	
	CC.remove_child(item)
	item = null
	
	return item
