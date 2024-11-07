extends Control



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GlobalSignal.intro == false  :
		$ColorRect/Entry_Btn.hide()
		$ColorRect/Menu_Btn.show()
	else:
		$ColorRect/Menu_Btn.hide()
		$AnimationPlayer.play("Intro_act")
		#$AnimationPlayer.animation_finished
		#$ColorRect/Logo.set_position(Vector2(178, 164))
		#$ColorRect/Logo.scale = Vector2(0.55, 0.55)
		


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _unhandled_input(event):
	if Input.is_key_pressed(KEY_SPACE):
		if $AnimationPlayer.is_playing():
			var current_animation_length = $AnimationPlayer.current_animation_length
			$AnimationPlayer.seek(current_animation_length, true)


func _on_entry_btn_pressed() -> void:
	$AnimationPlayer.play("Entry_act")
	GlobalSignal.intro = false


func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/loading.tscn")
