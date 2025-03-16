extends Node
class_name PlayerAnimationController

# Nama node animasi
var idle_node_name: String = "Idle"
var walk_node_name: String = "Walk"
var run_node_name: String = "Run"
var jump_node_name: String = "Jump"
var attacku1_node_name: String = "AttackU1"
var attacku2_node_name:String = "AttackU2"
var attacku3_node_name:String = "AttackU3"
var death_node_name: String = "Death"
var hitted_node_name: String = "Hitted"

# Status animasi
var is_attacking: bool = false
var is_walking: bool = false
var is_running: bool = false
var is_dying: bool = false
var is_hitted: bool = false

@onready var animation_tree = $"../../AnimationTree"
@onready var playback = animation_tree.get("parameters/playback")


func update_animation_parameters(on_floor: bool) -> void:
	animation_tree["parameters/conditions/IsOnFloor"] = on_floor
	animation_tree["parameters/conditions/IsInAir"] = !on_floor
	animation_tree["parameters/conditions/IsWalking"] = is_walking
	animation_tree["parameters/conditions/IsNotWalking"] = !is_walking
	animation_tree["parameters/conditions/IsRunning"] = is_running
	animation_tree["parameters/conditions/IsNotRunning"] = !is_running
	animation_tree["parameters/conditions/IsDying"] = is_dying
	animation_tree["parameters/conditions/IsHitted"] = is_hitted

	if (attacku1_node_name in playback.get_current_node()): 
		is_attacking = true
	elif (attacku2_node_name in playback.get_current_node()):
		is_attacking = true
	elif (attacku3_node_name in playback.get_current_node()):
		is_attacking = true
	else: 
		is_attacking = false

func set_walking(walking: bool) -> void:
	is_walking = walking
	
func set_running(running: bool) -> void:
	is_running = running
	
func set_dying(dying: bool) -> void:
	is_dying = dying
	
func set_hit(hit: bool) -> void:
	is_hitted = hit
	
func play_attack() -> void:
	playback.travel(attacku1_node_name)

func play_attack1() -> void:
	playback.travel(attacku1_node_name)

func play_attack2() -> void:
	playback.travel(attacku2_node_name)

func play_attack3() -> void:
	playback.travel(attacku3_node_name)

func play_hit() -> void:
	playback.travel(hitted_node_name)
	
func play_death() -> void:
	playback.travel(death_node_name)
