extends Control
class_name  UI

@onready var death = $IU/Death
@onready var invt = $IU/Inventory
@onready var stats = $IU/Stats
@onready var current_floor_label = $IU/FLoorLabel

var inv_show:bool
var sts_show:bool

func _ready() -> void:
	death.hide()
	inv_clos()
	#invt.hide()
	
func update_floor_label(new_floor: int) -> void:
	current_floor_label.text = "Current Floor: " + str(new_floor)

func hide_p():
	death.hide()

func show_p():
	death.show()


func UI_State(state:int):
	match state:
		1:
			if inv_show:
				var v = self.get_parent().get_child(0).get_child(2)
				v.ui_closed = true
				inv_clos()
			else :
				stats_close()
				inv_open()
		2:
			if sts_show:
				var v = self.get_parent().get_child(0).get_child(2)
				v.ui_closed = true
				stats_close()
			else :
				inv_clos()
				stats_open()

func inv_open():
	GlobalSignal.ui_show = true
	inv_show = true
	invt.visible = true

func inv_clos():
	GlobalSignal.ui_show = false
	inv_show = false
	invt.visible = false

func stats_open():
	GlobalSignal.ui_show = true
	sts_show = true
	stats.visible = true

func stats_close():
	GlobalSignal.ui_show = false
	sts_show = false
	stats.visible = false
