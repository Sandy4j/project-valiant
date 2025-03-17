extends Control
class_name  UI

@onready var death = $IU/Death
@onready var invt = $IU/Inventory
@onready var stats = $IU/Stats
@onready var current_floor_label = $IU/FLoorLabel
@onready var Stats: PlayerStatsController
@onready var Inv_Item:Inv_Slots
@onready var PauseM = $IU/Pause
@onready var Resume_Btn = $IU/Pause/Resume

var inv_show:bool
var sts_show:bool
var ui_show:bool
var on_menu:bool

func _ready() -> void:
	death.hide()
	inv_clos()
	#invt.hide()
	PauseM.hide()
	$IU/Options/Backcon/Back.connect("pressed",Callable(self, "_on_option_back_pressed"))

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

func paused():
	PauseM.visible = !PauseM.visible
	get_tree().paused = PauseM.visible

func _on_resume_pressed() -> void:
	PauseM.visible = false
	get_tree().paused = PauseM.visible

func _unhandled_input(event):
	if Input.is_key_pressed(KEY_E) && on_menu :
		_on_option_back_pressed()

func _on_option_pressed() -> void:
	$IU/Options.visible = true
	on_menu = true
	PauseM.visible = !PauseM.visible

func _on_option_back_pressed() ->void:
	$IU/Options.visible = false
	on_menu = false
	PauseM.visible = !PauseM.visible

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
