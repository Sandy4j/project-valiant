extends Control

var tween
@onready var DialogueBox = get_parent().get_node("DialogueBox")
@onready var Dialogue = $Dialogue
@onready var Indicator = $DialogueIndicator


var dialogue_to_me = [
	"Halo diriku yang ada disana?",
	"Apakah kamu menyesal?",
	"Berdoalah dia tetap memilikinya",
	"otherwise it's all useless"
]

var dialogue_conv = []
var dialogue_index = 0
var dialogue_finished:bool = false
var dialogue_stopper = 0
var convo_index

func _ready():
	tween = get_tree().create_tween()
	#Dialogue.rect_global_position = Vector2(-13,700)
	tween.connect("finished",self.on_tween_finished)
	Dialogue.visible = false

func load_dialogue(index:int):
	convo_index = index
	match index:
		1:
			dialogue_conv = dialogue_to_me
			Dialogue.text = dialogue_conv[dialogue_index]
			
		
	
	Dialogue.visible = true
	Indicator.visible = false
	if dialogue_index < dialogue_conv.size():
		dialogue_finished = false
		Dialogue.text = dialogue_conv[dialogue_index]
		Dialogue.visible_ratio = 0
		tween.interpolate_value(Dialogue,Dialogue.visible_ratio, 0,1,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT)
		tween.start()
	else :
		Dialogue.visible = false
		DialogueBox.dial_hide()
		dialogue_index = -1
		convo_index = -1
		dialogue_stopper = 0
	dialogue_index += 1

func on_tween_finished():
	dialogue_finished = true
	Indicator.visible = true

func _on_dialogue_indicator_pressed() -> void:
	load_dialogue(convo_index)
