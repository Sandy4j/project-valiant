@tool
extends Node3D

@export var room_scene: PackedScene
@export var roomStart : PackedScene
@export var dungeon_width: int = 5
@export var dungeon_height: int = 5
@export var room_size: Vector3 = Vector3(10,10,10)



var rooms =[]

func _ready():
	generate_dungeon()

func place_room(x: int, y: int) -> Node3D:
	var room_instance = room_scene.instantiate()
	room_instance.transform.origin = Vector3(x * room_size.x, 0, y * room_size.z)
	add_child(room_instance)
	return room_instance

func generate_dungeon():
	rooms = []
	for x in range(dungeon_width):
		var column = []
		for y in range(dungeon_height):
			var room = place_room(x, y)
			column.append(room)
		rooms.append(column)
	
	var random_room_x = randi_range(0, dungeon_width-1)
	var random_room_y = randi_range(0, dungeon_height-1)
	rooms[random_room_x][random_room_y].queue_free()
	rooms[random_room_x][random_room_y] = null

	for x in range(dungeon_width):
		for y in range(dungeon_height):
			var room = rooms[x][y]
			if room != null:
				var has_north_room = (y > 0) and (rooms[x][y - 1] !=null)
				var has_south_room = (y < dungeon_height - 1) and (rooms[x][y + 1] != null)
				var has_east_room = (x > 0) and (rooms[x - 1][y] != null)
				var has_west_room = (x < dungeon_width - 1) and (rooms[x + 1][y] != null)
				
				set_door_and_wall_visibility(room, "North", has_north_room)
				set_door_and_wall_visibility(room, "South", has_south_room)
				set_door_and_wall_visibility(room, "East", has_east_room)
				set_door_and_wall_visibility(room, "West", has_west_room)
				
func set_door_and_wall_visibility(room: Node3D, direction: String, has_neighbor: bool):
		var door = room.get_node("Door" + direction)
		var wall = room.get_node("Wall" + direction)
		if has_neighbor:
			door.visible = true
			wall.visible = false
		else:
			door.visible = false
			wall.visible = true
			
