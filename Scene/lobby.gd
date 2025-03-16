extends WorldEnvironment

@export var next_scene: PackedScene
@export var input_action: String = "interact"
@onready var sp = $lobby/pintu/Sprite3D

var player_inside: bool = false

func _process(delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if next_scene:
			get_tree().change_scene_to_packed(next_scene)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		sp.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		sp.visible = false
