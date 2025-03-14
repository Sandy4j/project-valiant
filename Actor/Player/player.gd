extends CharacterBody3D
class_name Player

@export var inv:Inventory
@export var JUMP_VELOCITY = 4.5
@export var MOUSE_SENSITIVITY = 0.05
@export var ROTATION_SPEED = 10.0

@onready var HP_BAR = $"UI Player/IU/HP"
@onready var MANA_BAR = $"UI Player/IU/Mana"
@onready var EXP_BAR = $"UI Player/IU/Exp_Bar"
@onready var Lvl = $"UI Player/IU/Exp_Bar/Lvl"
@onready var animation_controller: PlayerAnimationController = $PlayerFunction/PlayerAnim
@onready var stats_controller: PlayerStatsController = $PlayerFunction/PlayerStats
@onready var input_controller: PlayerInputController = $PlayerFunction/PlayerInput
@onready var combat_controller: PlayerPhysicalCombatController = $PlayerFunction/PlayerCombat
@onready var UI_Player: = %"UI Player"
@onready var Dialogbox = $"UI Player/Chatbox/DialogueBox"
@onready var Dialog = $"UI Player/Chatbox/DialoguePopUp"
@onready var magic_system: MagicSystem = $PlayerFunction/MagicSystem
@onready var spell_spawn_point = $Rogue/SpellSpawn
@onready var model = $Rogue

var saved_stats: Dictionary = {}
var camera_rotation: float = 0.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	add_to_group("player")
	connect_stat()
	#magic_system.stats_controller = stats_controller
	stats_controller.connect("Pdied", Callable(self, "died"))
	input_controller.connect("camera_rotated", Callable(self, "update_camera_rotation"))
	combat_controller.connect("attack_performed", Callable(animation_controller, "play_attack"))
	input_controller.connect("UI_Change",Callable(UI_Player,"UI_State"))
	#input_controller.connect("talk",self.Talking)
	stats_controller.connect("hp_changed", Callable(self, "connect_hp"))
	stats_controller.connect("mana_changed", Callable(self, "connect_mana"))
	stats_controller.connect("exp_changed", Callable(self, "connect_exp"))
	stats_controller.connect("level_changed", Callable(self, "connect_stat"))

func connect_stat():
	connect_hp()
	connect_mana()
	connect_exp()

func connect_hp():
	HP_BAR.max_value = stats_controller.max_hp
	HP_BAR.value = stats_controller.current_hp

func connect_mana():
	MANA_BAR.max_value = stats_controller.max_mana
	MANA_BAR.value = stats_controller.current_mana

func connect_exp():
	EXP_BAR.max_value = stats_controller.xp_to_next_level
	EXP_BAR.value = stats_controller.player_xp
	Lvl.text = str(stats_controller.player_level)

func _physics_process(delta):
	if not is_on_floor():
		velocity += Vector3.DOWN * gravity * delta
		
	# Proses input gerakan dari controller input
	var direction = input_controller.get_movement_direction(camera_rotation)
	
	if direction != Vector3.ZERO:
		velocity.x = direction.x * stats_controller.move_speed
		velocity.z = direction.z * stats_controller.move_speed
		
		var target_rotation = atan2(direction.x, direction.z)
		if model:
			var current_rotation = model.rotation.y
			var new_rotation = lerp_angle(current_rotation, target_rotation, delta * ROTATION_SPEED)
			model.rotation.y = new_rotation
			
		animation_controller.set_walking(true)
	else:
		velocity.x = move_toward(velocity.x, 0, stats_controller.move_speed)
		velocity.z = move_toward(velocity.z, 0, stats_controller.move_speed)
		animation_controller.set_walking(false) 
	move_and_slide()
	animation_controller.update_animation_parameters(is_on_floor())

func update_camera_rotation(cam_rotation: float):
	camera_rotation = cam_rotation

func Hited(damage: int):
	stats_controller.take_damage(damage)

func died():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	saved_stats = stats_controller.save_stats()
	level_manager.reset_to_checkpoint()

func respawn() -> void:
	stats_controller.load_stats(saved_stats)
	velocity = Vector3.ZERO
	stats_controller.reset_stats()
	var dungeon_manager = get_tree().get_first_node_in_group("dungeon_manager")
	if dungeon_manager:
		if is_instance_valid(self):
			var current_parent = get_parent()
			if current_parent:
				current_parent.remove_child(self)
		dungeon_manager.spawn_player()

func Talking(indx:Dialog_Convo):
	Dialogbox.dial_show()
	Dialog.load_dialogue(indx)
	print("DIalog terpanggil")


func _on_player_area_entered(area: Area3D) -> void:
	if area.has_method("collect"):
		area.collect(inv)



func _on_npc_area_entered(area: Area3D) -> void:
	pass # Replace with function body.
