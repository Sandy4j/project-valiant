extends Area3D

class_name CurseLiftObject

signal curse_lift_collected(body)

var can_be_collected = false
var collection_delay = 1.0  # Waktu delay dalam detik

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Nonaktifkan collision sementara
	$CollisionShape3D.set_deferred("disabled", true)
	
	# Aktifkan collection setelah delay
	var timer = get_tree().create_timer(collection_delay)
	timer.connect("timeout", Callable(self, "_enable_collection"))
	
	_add_visual_feedback()

func _enable_collection():
	$CollisionShape3D.set_deferred("disabled", false)
	can_be_collected = true
	print("CurseLiftObject can now be collected")

func _on_body_entered(body):
	if can_be_collected and body.has_method("collect_curse_lift"):
		emit_signal("curse_lift_collected", body)
		queue_free()

func _add_visual_feedback():
	# Tambahkan MeshInstance3D untuk representasi visual
	var mesh = MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.5
	mesh.mesh.height = 1.0
	
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0, 1)  # Warna ungu
	material.emission_enabled = true
	material.emission = Color(1, 0, 1)
	material.emission_energy = 1.0
	
	mesh.material_override = material
	
	add_child(mesh)
	
	# Animasi sederhana
	var tween = create_tween().set_loops()
	tween.tween_property(mesh, "scale", Vector3(1.2, 1.2, 1.2), 1.0)
	tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 1.0)
