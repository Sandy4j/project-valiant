extends CanvasLayer
class_name DungeonLoadingScreen

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var progress_bar: ProgressBar = $Bg/LoadingBar

var dungeon_manager: DungeonM
var generation_progress := 0.0
var is_loading := false

func _ready() -> void:
	dungeon_manager = get_tree().get_first_node_in_group("DungeonM")
	dungeon_manager.dungeon_generation_completed.connect(_on_dungeon_generated)
	hide()

func start_loading() -> void:
	show()
	is_loading = true
	generation_progress = 0.0
	animation_player.play("loding")
	update_progress()

func _on_dungeon_generated() -> void:
	is_loading = false
	animation_player.stop()
	hide()
	

func update_progress() -> void:
	if !is_loading:
		return

	var calculated_progress = dungeon_manager.get_generation_progress()
	progress_bar.value = lerp(progress_bar.value, calculated_progress, 0.1)
	
	await get_tree().create_timer(0.05).timeout
	update_progress()
