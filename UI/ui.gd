extends Control
class_name  UI

@onready var death = $IU/Death
@onready var invt = $IU/Inventory
@onready var stats = $IU/Stats
@onready var current_floor_label = $IU/FLoorLabel



# Called when the node enters the scene tree for the first time.
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func inv_open():
	invt.visible = true

func inv_clos():
	invt.visible = false

func stats_open():
	stats.visible = true

func stats_close():
	stats.visible = false
