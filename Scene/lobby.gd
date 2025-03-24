extends WorldEnvironment


@export var input_action: String = "interact"
@onready var sp = $lobby/pintu_004/Sprite3D
@export var playerscene: PackedScene

var scene = ""
var player_inside: bool = false
var playerI: CharacterBody3D = null


func _ready() -> void:
	if scene == "":
		scene = "res://Dungeon/Dungeon.tscn"
	sp.visible = false
	playerI = playerscene.instantiate()
	add_child(playerI)
	playerI.global_position = $Marker3D.global_position
	ResourceLoader.load_threaded_request(scene)

func _process(delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		var loading_screen = preload("res://Scene/Loading.tscn").instantiate()
		loading_screen.set_target_scene(scene)
		get_tree().current_scene.add_child(loading_screen)

		if playerI:
			playerI.queue_free()
			playerI = null


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		sp.visible = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		sp.visible = false
