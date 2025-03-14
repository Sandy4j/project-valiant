extends Node3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var area: Area3D = $Area3D  # Ganti RayCast3D dengan Area3D

var damage: int = 0
var debuff_type: String = "cold"
var penetration: bool = false
var delay: float = 2.0
var is_magic_damage = true
var current_targets: Array = []  # Untuk melacak musuh di dalam area

func _ready():
	anim_player.play("beam")
	$Beam.emitting = true
	$Timer.wait_time = delay  # Pastikan Timer menggunakan delay
	$Timer.start()
	
	$sprinkle.emitting = true
	if penetration:
		$sprinkle.amount = 100
	
	# Timer untuk damage berulang
	$DamageTimer.wait_time = 0.5  # Interval damage (0.5 detik)
	$DamageTimer.start()

func _on_damage_timer_timeout():
	for target in current_targets:
		apply_damage(target)

func apply_damage(target):
	if target.has_method("take_damage"):
		var success = false
		if target.has_method("is_magic_damager"):
			target.take_damage(damage, is_magic_damage)
			success = true
		else:
			target.take_damage(damage)
	
	if target.has_method("apply_debuff"):
		target.apply_debuff(debuff_type)
		if target.has_method("update_speed"):
			target.update_speed()

func _on_timer_timeout():
	anim_player.play_backwards("beam")
	await anim_player.animation_finished
	queue_free()

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemy"):
		current_targets.append(body)


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body in current_targets:
		current_targets.erase(body)
