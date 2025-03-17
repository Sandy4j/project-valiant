extends Control



var on_menu:bool = false

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
	$ColorRect/Options/Backcon/Back.connect("pressed",Callable(self, "_on_option_back_pressed"))

func ToOption(go:bool):
	if go:
		$AnimationPlayer.play("Option_Show")
		on_menu = true
	else:
		$AnimationPlayer.play_backwards("Option_Show")
		on_menu = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event):
	if Input.is_key_pressed(KEY_SPACE):
		if $AnimationPlayer.is_playing():
			var current_animation_length = $AnimationPlayer.current_animation_length
			$AnimationPlayer.seek(current_animation_length, true)
	if Input.is_key_pressed(KEY_E) && on_menu :
		_on_option_back_pressed()

func _on_entry_btn_pressed() -> void:
	$AnimationPlayer.play("Entry_act")
	GlobalSignal.intro = false

func _on_play_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://Scene/loading.tscn")

func _on_option_btn_pressed() -> void:
	ToOption(true)

func _on_option_back_pressed() ->void:
	ToOption(false)
