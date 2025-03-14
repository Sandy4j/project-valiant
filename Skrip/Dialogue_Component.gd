extends Area3D
class_name Dialogue_Component

@export var conversations: Array[Convo_Res] = []
@onready var Trigger = $Trigger
var player_in_area: bool = false  # Apakah pemain berada di area
var player: Node = null  # Referensi ke pemain

func _ready():
	# Hubungkan sinyal area_entered dan area_exited
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	Trigger.visible = false

func _on_body_entered(body: Node):
	# Cek apakah objek yang masuk adalah pemain
	if body.has_method("Talking") :  # Misalnya, pemain memiliki metode "talking"
		player_in_area = true
		player = body
		Trigger.visible = true

func _on_body_exited(body: Node):
	# Cek apakah objek yang keluar adalah pemain
	if body == player:
		player_in_area = false
		player = null
		Trigger.visible = false

func _process(delta):
	# Cek jika pemain berada di area dan menekan tombol "Talk"
	if player_in_area && Input.is_action_just_pressed("Talk"):
		player.Talking(talking())  # Panggil fungsi Talking dengan parameter dari pemain

func talking():
	for conversation in conversations:
		if conversation.convo != null: 
			if conversation.onetime && !conversation.done:
				conversation.done = true  
				return conversation.convo
			elif !conversation.onetime:
				return conversation.convo
	return null 
