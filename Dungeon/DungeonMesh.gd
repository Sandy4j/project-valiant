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

# Dictionary untuk mengidentifikasi tipe ruangan
var room_types : Dictionary = {
	0: "normal",    # Ruangan normal
	1: "hallway",   # Koridor
	2: "junction",  # Persimpangan
	3: "border",    # Border zone - tidak perlu mesh
	4: "start",     # Ruang awal
	5: "end"        # Ruang akhir
}


func calculate_grid_to_world(grid_pos: Vector3) -> Vector3:
	var cell_size = grid_map.cell_size
	return Vector3(
		grid_pos.x * cell_size.x + cell_size.x * 0.5,
		0,
		grid_pos.z * cell_size.z + cell_size.y * 0.5
	)

# Fungsi baru untuk instantiate start room
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

# Fungsi baru untuk instantiate end room
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

# Fungsi untuk membersihkan instance room
func clear_room_instances():
	if start_room_instance:
		start_room_instance.queue_free()
		start_room_instance = null
	if end_room_instance:
		end_room_instance.queue_free()
		end_room_instance = null


func get_cell_world_position(cell: Vector3i) -> Vector3:
	var cell_size = grid_map.cell_size
	return Vector3(
		cell.x * cell_size.x,
		0,
		cell.z * cell_size.z
	)

func create_dungeon():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var t : int = 0
	
	var used_cells = grid_map.get_used_cells()
	var start_cells = []
	
	# Pertama, identifikasi semua cell start room
	for cell in used_cells:
		if grid_map.get_cell_item(cell) == 4:
			start_cells.append(cell)
	
	for cell in used_cells:
		var cell_index : int = grid_map.get_cell_item(cell)
		if cell_index == 3:
			continue
			
		if cell_index >= 0 && cell_index <= 5 && cell_index != 3:
			var dun_cell : Node3D = parent.dun_cell_scene.instantiate()
			
			var world_pos = get_cell_world_position(cell)
			
			if parent.mesh_size == 0.25:
				dun_cell.position = world_pos + (grid_map.cell_size * 0.5)
				dun_cell.scale = Vector3.ONE
			else:
				dun_cell.position = world_pos + (grid_map.cell_size * 0.5)
				dun_cell.scale = Vector3.ONE * 4.0
			
			# Penanganan khusus untuk start room
			if cell_index == 4:
				dun_cell.add_to_group("start_room")
				# Cek apakah ini cell paling kiri dari start room
				var is_leftmost = true
				for start_cell in start_cells:
					if start_cell.x < cell.x and start_cell.z == cell.z:
						is_leftmost = false
						break
				
				if is_leftmost:
					# Hapus dinding kanan untuk cell paling kiri
					dun_cell.call("remove_wall_right")
					dun_cell.call("remove_door_right")
				else:
					# Hapus dinding kiri untuk cell kedua
					dun_cell.call("remove_wall_left")
					dun_cell.call("remove_door_left")
			elif cell_index == 5:
				dun_cell.add_to_group("end_room")
			
			add_child(dun_cell)
			dun_cell.set_owner(owner)
			t += 1
			
			# Pengecekan tetangga untuk setiap arah
			for i in 4:
				var dir = directions.keys()[i]
				var cell_n : Vector3i = cell + directions.values()[i]
				var cell_n_index : int = grid_map.get_cell_item(cell_n)
				
				if cell_n_index == -1 || cell_n_index == 3:
					handle_none(dun_cell, dir)
				else:
					var current_type = min(cell_index, 2) if cell_index < 4 else cell_index
					var neighbor_type = min(cell_n_index, 2) if cell_n_index < 4 else cell_n_index
					
					if current_type >= 4 or neighbor_type >= 4:
						handle_special_room(dun_cell, dir, current_type, neighbor_type)
					else:
						var key : String = str(current_type) + str(neighbor_type)
						call("handle_" + key, dun_cell, dir)
						
		if t % 10 == 9:
			await get_tree().create_timer(0).timeout

func handle_special_room(cell: Node3D, dir: String, current_type: int, neighbor_type: int):
	# Khusus untuk koneksi antar cell start room
	if current_type == 4 and neighbor_type == 4:
		cell.call("remove_wall_" + dir)
		cell.call("remove_door_" + dir)
		return
		
	# Khusus untuk koneksi antara start room dan end room
	if (current_type == 4 and neighbor_type == 5) or (current_type == 5 and neighbor_type == 4):
		# Perlakukan keduanya seperti ruangan normal
		handle_00(cell, dir)
		return
		
	# Konversi tipe ruangan spesial ke tipe normal untuk penanganan standar
	var converted_current = current_type
	var converted_neighbor = neighbor_type
	
	# Konversi start room (4) dan end room (5) ke ruangan normal (0)
	if converted_current >= 4:
		converted_current = 0
	if converted_neighbor >= 4:
		converted_neighbor = 0
		
	var key : String = str(converted_current) + str(converted_neighbor)
	call("handle_" + key, cell, dir)

# Fungsi handle lainnya tetap sama
func handle_none(cell:Node3D,dir:String):
	cell.call("remove_door_"+dir)
	
func handle_00(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_01(cell:Node3D,dir:String):
	cell.call("remove_door_"+dir)
func handle_02(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_10(cell:Node3D,dir:String):
	cell.call("remove_door_"+dir)
func handle_11(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_12(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_20(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_21(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_22(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
