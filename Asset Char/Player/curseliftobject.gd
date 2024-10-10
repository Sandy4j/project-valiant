extends Area3D

class_name CurseliftObject

signal curselift(body)

func _ready():
	# Set up collision shape
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5  # Adjust as needed
	collision_shape.shape = sphere_shape
	add_child(collision_shape)

	# Set up visual representation
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	sphere_mesh.height = 1.0
	mesh_instance.mesh = sphere_mesh
	add_child(mesh_instance)

	# Set up material for visual feedback
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 0, 0.5)  # Semi-transparent green
	material.emission_enabled = true
	material.emission = Color(0, 1, 0)
	material.emission_energy = 0.5
	mesh_instance.material_override = material

	# Connect the body entered signal
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
	if body.has_method("curse_lift"):
		emit_signal("curselift", body)
		queue_free()
