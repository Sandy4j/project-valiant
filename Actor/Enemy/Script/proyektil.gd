extends Area3D

var direction: Vector3
var speed: float
var damage: float
var max_lifetime: float = 5.0
var player: Player

func _ready():
	player = get_tree().get_first_node_in_group("player")
	await get_tree().create_timer(max_lifetime).timeout
	queue_free()

func initialize(dir: Vector3, spd: float, dmg: float) -> void:
	direction = dir.normalized()
	speed = spd
	damage = dmg
	look_at(global_position + direction)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_body_entered(body: Node3D) -> void:
	if body == player:
		#body.Hited(damage)
		print("test")
	queue_free()
