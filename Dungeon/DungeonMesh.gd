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
	
	# Cari posisi end room yang paling kanan
	var rightmost_end_cell = null
	var max_x = -999999  # Nilai awal yang sangat kecil
	
	# First pass: collect start and end room positions
	for cell in used_cells:
		var cell_index = grid_map.get_cell_item(cell)
		if cell_index == 4:  # Start room
			start_cells.append(cell)
		elif cell_index == 5:  # End room
			# Perbarui rightmost_end_cell jika menemukan cell dengan x lebih besar
			if cell.x > max_x:
				max_x = cell.x
				rightmost_end_cell = cell
			end_cells.append(cell)
	
	# Instantiate start room
	if start_cells.size() > 0:
		instantiate_start_room(Vector3(start_cells[0]))
	
	# Instantiate end room di posisi paling kanan
	if rightmost_end_cell != null:
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

			if cell_index == 4:
				var is_leftmost = true
				for start_cell in start_cells:
					if start_cell.x < cell.x and start_cell.z == cell.z:
						is_leftmost = false
						break
				
				if is_leftmost:
					dun_cell.call("remove_wall_right")
					dun_cell.call("remove_door_right")
				else:
					dun_cell.call("remove_wall_left")
					dun_cell.call("remove_door_left")

			add_child(dun_cell)
			dun_cell.set_owner(owner)
			t += 1
			
			# Cek tetangga untuk setiap arah
			for i in 4:
				var dir = directions.keys()[i]
				var cell_n : Vector3i = cell + directions.values()[i]
				var cell_n_index : int = grid_map.get_cell_item(cell_n)
				
				# Jika cell saat ini adalah end room dan tetangga di sisi kanan
				if cell_index == 5 and dir == "right":
					# Cek apakah cell saat ini adalah tile paling kanan
					if cell_n_index != 5:
						# Jika bukan tile paling kanan, hapus dinding dan pintu di sisi kanan
						dun_cell.call("remove_wall_" + dir)
						dun_cell.call("remove_door_" + dir)
					
					# Lanjutkan ke loop berikutnya, tidak perlu lagi mengecek tetangga lain
					continue
				
				if cell_n_index == -1 || cell_n_index == 3:
					handle_none(dun_cell, dir)
				else:
					# Konversi tipe ruangan untuk penanganan
					var current_type = cell_index
					var neighbor_type = cell_n_index
					
					# Jika salah satu adalah special room (tipe 4 atau 5)
					if current_type >= 4 or neighbor_type >= 4:
						handle_special_room(dun_cell, dir, current_type, neighbor_type)
					else:
						# Untuk ruangan normal (tipe 0-2)
						var key : String = str(min(current_type, 2)) + str(min(neighbor_type, 2))
						call("handle_" + key, dun_cell, dir)
						
		if t % 10 == 9:
			await get_tree().create_timer(0).timeout

func handle_special_room(cell: Node3D, dir: String, current_type: int, neighbor_type: int):
	# Handling untuk start room (tipe 4)
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
	elif neighbor_type == 5:
		# Koneksi ke end room
		cell.call("remove_wall_" + dir)
		cell.call("remove_door_" + dir)
		return

	# Konversi untuk tipe ruangan normal
	var converted_current = min(current_type, 2)
	var converted_neighbor = min(neighbor_type, 2)
	var key : String = str(converted_current) + str(converted_neighbor)
	call("handle_" + key, cell, dir)

func handle_none(cell:Node3D,dir:String):
	cell.call("remove_door_"+dir)
func handle_00(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
func handle_01(cell:Node3D,dir:String):
	pass
func handle_02(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
func handle_10(cell:Node3D,dir:String):
	pass
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
