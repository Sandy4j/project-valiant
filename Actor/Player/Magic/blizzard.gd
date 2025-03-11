# blizzard_beam.gd
extends Node3D

var damage = 0
var debuff_type = "cold"
var penetrated_targets = []

func _ready():
	$Timer.wait_time = 2.0
	$Timer.start()

func _process(delta):
	update_beam()

func update_beam():
	if $RayCast3D.is_colliding():
		var target = $RayCast3D.get_collider()
		if target.is_in_group("enemy") && !penetrated_targets.has(target):
			target.take_damage(damage)
			target.apply_debuff(debuff_type)
			penetrated_targets.append(target)

func _on_timer_timeout():
	queue_free()
