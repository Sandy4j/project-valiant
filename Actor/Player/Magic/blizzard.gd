extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer

var damage: int = 0
var debuff_type: String = "cold"
var penetration: bool = false
var delay: float = 2.0
var penetrated_targets: Array = []
var is_magic_damage = true

func _ready():
	anim_player.play("beam")
	$Beam.emitting = true
	$Timer.wait_time = 2.0
	$Timer.start()
	
	$sprinkle.emitting = true
	if penetration:
		$sprinkle.amount = 100

func _process(delta):
	update_beam()

func update_beam():
	if $RayCast3D.is_colliding():
		var target = $RayCast3D.get_collider()
		if target.is_in_group("enemy") && !penetrated_targets.has(target):
			apply_damage(target)
			penetrated_targets.append(target)

func apply_damage(target):
	if target.has_method("take_damage"):
		# Try to call with two parameters, fall back to one if it fails
		var success = false
		if target.has_method("is_magic_damager"):  # Check if target has a method to determine damage type
			target.take_damage(damage, is_magic_damage)
			success = true
		else:
			# For backward compatibility with older enemy types
			target.take_damage(damage)
	
	if target.has_method("apply_debuff"):
		target.apply_debuff(debuff_type)

		if target.has_method("update_speed"):
			target.update_speed()

func _on_timer_timeout():
	anim_player.play_backwards("beam")
	await anim_player.animation_finished
	queue_free()
