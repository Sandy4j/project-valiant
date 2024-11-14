extends Control

var proggres = []
var scene
var scene_load_status = 0

func _ready() -> void:
	scene = "res://main.tscn"
	$AnimationPlayer.play("loding")
	ResourceLoader.load_threaded_request(scene)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	scene_load_status = ResourceLoader.load_threaded_get_status(scene,proggres)
	$Bg/LBar.value = floor(proggres[0]*100)
	if scene_load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var newscene = ResourceLoader.load_threaded_get(scene)
		$AnimationPlayer.stop()
		get_tree().change_scene_to_packed(newscene)
