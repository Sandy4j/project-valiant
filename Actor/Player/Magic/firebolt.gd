# firebolt.gd
extends Node3D

var speed = 15.0
var damage = 0
var debuff_type = "burn"
var aoe_radius = 2.0

func _physics_process(delta):
	global_translate(Vector3.FORWARD * speed * delta)

func _on_area_3d_body_entered(body):
	if body.is_in_group("enemy"):
		apply_damage(body)
		explode()
		queue_free()

func apply_damage(target):
	target.take_damage(damage)
	if target.has_method("apply_debuff"):
		target.apply_debuff(debuff_type)

func explode():
	var aoe = Area3D.new()
	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = aoe_radius
	aoe.add_child(shape)
	
	get_tree().current_scene.add_child(aoe)
	aoe.global_transform = global_transform
	
	for body in aoe.get_overlapping_bodies():
		if body.is_in_group("enemy"):
			apply_damage(body)
	
	aoe.queue_free()
