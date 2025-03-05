@tool
extends Node3D

@export var grid_map_path : NodePath
@onready var grid_map : GridMap = get_node(grid_map_path)
@onready var parent = get_parent()

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
	if Engine.is_editor_hint():
		create_dungeon()

var start_room_instance: Node3D = null
var end_room_instance: Node3D = null

var directions : Dictionary = {
	"up" : Vector3i.FORWARD,"down" : Vector3i.BACK,
	"left" : Vector3i.LEFT,"right" : Vector3i.RIGHT
}

var room_types : Dictionary = {
	0: "normal",    # Ruangan normal
	1: "hallway",   # Koridor
	2: "junction",  # Persimpangan
	3: "border",    # Border zone
	4: "start",     # Ruang awal
	5: "end"        # Ruang akhir
}

func calculate_grid_to_world(grid_pos: Vector3) -> Vector3:
	var cell_size = grid_map.cell_size
	return Vector3(
		grid_pos.x * cell_size.x + cell_size.x * 0.5,
		0,
		grid_pos.z * cell_size.z + cell_size.z * 0.5
	)

func instantiate_start_room(start_pos: Vector3):
	if !parent.start_room_scene:
		push_warning("Start room scene belum di-set!")
		return
		
	if start_room_instance:
		start_room_instance.queue_free()
		
	start_room_instance = parent.start_room_scene.instantiate()
	add_child(start_room_instance)
	if Engine.is_editor_hint():
		start_room_instance.owner = get_tree().edited_scene_root
	
	var world_pos = calculate_grid_to_world(start_pos)
	start_room_instance.position = world_pos

func instantiate_end_room(end_pos: Vector3):
	if !parent.end_room_scene:
		push_warning("End room scene belum di-set!")
		return
		
	if end_room_instance:
		end_room_instance.queue_free()
		
	end_room_instance = parent.end_room_scene.instantiate()
	add_child(end_room_instance)
	if Engine.is_editor_hint():
		end_room_instance.owner = get_tree().edited_scene_root
	
	var world_pos = calculate_grid_to_world(end_pos)
	end_room_instance.position = world_pos

func clear_room_instances():
	if start_room_instance:
		start_room_instance.queue_free()
		start_room_instance = null
	if end_room_instance:
		end_room_instance.queue_free()
		end_room_instance = null

func create_dungeon():
	clear_room_instances()
	
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var t : int = 0
	
	var used_cells = grid_map.get_used_cells()
	var start_cells = []
	var end_cells = []
	
	var leftmost_start_x = 999999
	var rightmost_end_x = -999999
	
	for cell in used_cells:
		var cell_index = grid_map.get_cell_item(cell)
		if cell_index == 4:
			start_cells.append(cell)
			if cell.x < leftmost_start_x:
				leftmost_start_x = cell.x
		elif cell_index == 5:
			end_cells.append(cell)
			if cell.x > rightmost_end_x:  # Cari posisi x paling kanan untuk end room
				rightmost_end_x = cell.x
	
	if start_cells.size() > 0:
		instantiate_start_room(Vector3(start_cells[0]))
	
	if end_cells.size() > 0:
		# Cari end cell yang memiliki posisi x paling kanan
		var rightmost_end_cell = null
		for end_cell in end_cells:
			if end_cell.x == rightmost_end_x:
				rightmost_end_cell = end_cell
				break
		if rightmost_end_cell:
			instantiate_end_room(Vector3(rightmost_end_cell))

	for cell in used_cells:
		var cell_index : int = grid_map.get_cell_item(cell)
		if cell_index == 3:
			continue
			
		if cell_index >= 0 && cell_index <= 5 && cell_index != 3:
			var dun_cell : Node3D = parent.dun_cell_scene.instantiate()
			
			var world_pos = calculate_grid_to_world(Vector3(cell))
			
			if parent.mesh_size == 0.25:
				dun_cell.position = world_pos
				dun_cell.scale = Vector3.ONE
			else:
				dun_cell.position = world_pos
				dun_cell.scale = Vector3.ONE * 2.0

			if cell_index == 4:  # Untuk start room
				if cell.x == leftmost_start_x:
					dun_cell.call("remove_wall_left")
					dun_cell.call("remove_door_left")
			elif cell_index == 5:  # Untuk end room
				if cell.x == rightmost_end_x:
					dun_cell.call("remove_wall_right")  # Hapus dinding kanan untuk end room paling kanan
					dun_cell.call("remove_door_right")

			add_child(dun_cell)
			dun_cell.set_owner(owner)
			t += 1
			
			for i in 4:
				var dir = directions.keys()[i]
				var cell_n : Vector3i = cell + directions.values()[i]
				var cell_n_index : int = grid_map.get_cell_item(cell_n)
			
				if cell_index == 4 and cell.x == leftmost_start_x and dir == "left":
					continue
				if cell_index == 5 and cell.x == rightmost_end_x and dir == "right":  # Kondisi khusus untuk end room paling kanan
					continue
				
				if cell_n_index == -1 || cell_n_index == 3:
					handle_none(dun_cell, dir)
				else:
					var current_type = cell_index
					var neighbor_type = cell_n_index
					if current_type >= 4 or neighbor_type >= 4:
						handle_special_room(dun_cell, dir, current_type, neighbor_type)
					else:
						var key : String = str(min(current_type, 2)) + str(min(neighbor_type, 2))
						call("handle_" + key, dun_cell, dir)

			if t % 10 == 9:
				await get_tree().create_timer(0).timeout

func handle_special_room(cell: Node3D, dir: String, current_type: int, neighbor_type: int):
	if current_type == 4:
		# Koneksi start room ke ruangan normal
		cell.call("remove_wall_" + dir)
		cell.call("remove_door_" + dir)
		return
	elif neighbor_type == 4:
		# Koneksi ruangan normal ke start room
		cell.call("remove_wall_" + dir)
		cell.call("remove_door_" + dir)
		return
	elif current_type == 5 or neighbor_type == 5:
		# Koneksi ke/dari end room
		cell.call("remove_wall_" + dir)
		cell.call("remove_door_" + dir)
		return

	var converted_current = min(current_type, 2)
	var converted_neighbor = min(neighbor_type, 2)
	var key : String = str(converted_current) + str(converted_neighbor)
	call("handle_" + key, cell, dir)

func handle_none(cell:Node3D,dir:String):
	cell.call("remove_door_"+dir)
func handle_00(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_01(cell:Node3D, dir:String):
	cell.call("remove_door_" + dir)
func handle_10(cell:Node3D, dir:String):
	cell.call("remove_wall_" + dir)
	cell.call("remove_door_" + dir)
func handle_02(cell:Node3D,dir:String):
	cell.call("remove_wall_" + dir)
	cell.call("remove_door_" + dir)
func handle_11(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_12(cell:Node3D, dir:String):
	cell.call("remove_wall_" + dir)
func handle_20(cell:Node3D, dir:String):
	cell.call("remove_wall_" + dir)
	cell.call("remove_door_" + dir)
func handle_21(cell:Node3D, dir:String):
	cell.call("remove_wall_" + dir)
	cell.call("remove_door_" + dir)
func handle_22(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
