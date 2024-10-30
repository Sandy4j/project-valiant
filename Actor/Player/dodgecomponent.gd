class_name DodgeComponent
extends Node

signal dodge_started
signal dodge_ended
signal iframe_ended

@export var dodge_speed: float = 10.0
@export var dodge_duration: float = 0.5
@export var dodge_cooldown: float = 1.0
@export var iframe_duration: float = 0.3

var _is_dodging: bool = false
var _can_dodge: bool = true
var _is_invincible: bool = false

var dodge_timer: Timer
var dodge_cooldown_timer: Timer
var iframe_timer: Timer

var parent: CharacterBody3D

func _ready():
	parent = get_parent() as CharacterBody3D
	if not parent:
		push_error("DodgeComponent must be a child of a CharacterBody3D")
		return

	_setup_timers()

func _setup_timers():
	dodge_timer = Timer.new()
	dodge_timer.one_shot = true
	dodge_timer.connect("timeout", Callable(self, "_on_dodge_finished"))
	add_child(dodge_timer)

	dodge_cooldown_timer = Timer.new()
	dodge_cooldown_timer.one_shot = true
	dodge_cooldown_timer.connect("timeout", Callable(self, "_on_dodge_cooldown_finished"))
	add_child(dodge_cooldown_timer)

	iframe_timer = Timer.new()
	iframe_timer.one_shot = true
	iframe_timer.connect("timeout", Callable(self, "_on_iframe_finished"))
	add_child(iframe_timer)

func dodge(direction: Vector3):
	if not _can_dodge:
		return

	_is_dodging = true
	_can_dodge = false
	_is_invincible = true

	parent.velocity = direction * dodge_speed

	dodge_timer.start(dodge_duration)
	iframe_timer.start(iframe_duration)
	dodge_cooldown_timer.start(dodge_cooldown)

	emit_signal("dodge_started")

func _on_dodge_finished():
	_is_dodging = false
	emit_signal("dodge_ended")

func _on_dodge_cooldown_finished():
	_can_dodge = true

func _on_iframe_finished():
	_is_invincible = false
	emit_signal("iframe_ended")

func is_dodging() -> bool:
	return _is_dodging

func is_invincible() -> bool:
	return _is_invincible

func can_dodge() -> bool:
	return _can_dodge
