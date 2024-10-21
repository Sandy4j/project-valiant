extends Node2D
class_name  UI

@onready var death = $IU/Death
@onready var invt = $IU/Inventory

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	death.hide()
	#invt.hide()

func hide_p():
	death.hide()

func show_p():
	death.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
