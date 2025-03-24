extends Control

var proggres = []
var target_scene = ""
var scene_load_status = 0

func _ready() -> void:
	if target_scene == "":
		target_scene = "res://Scene/Lobby.tscn"

	$AnimationPlayer.play("loding")
	ResourceLoader.load_threaded_request(target_scene)

func _process(delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(target_scene, proggres)
	$Bg/LoadingBar.value = floor(proggres[0] * 100)
	
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var newscene = ResourceLoader.load_threaded_get(target_scene)
		$AnimationPlayer.stop()
		get_tree().change_scene_to_packed(newscene)

func set_target_scene(scene_path: String):
	target_scene = scene_path
