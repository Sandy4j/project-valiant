# Modifikasi pada dunmesh.gd
@tool
extends Node3D

@export var grid_map_path : NodePath
@onready var grid_map : GridMap = get_node(grid_map_path)

#@export var start : bool = false : set = set_start
#func set_start(val:bool)->void:
	#if Engine.is_editor_hint():
		#create_dungeon()
var dun_cell_scene : PackedScene = preload("res://Proc Dungeon/test dun/mesh_dun.tscn")

var directions : Dictionary = {
	"up" : Vector3i.FORWARD,"down" : Vector3i.BACK,
	"left" : Vector3i.LEFT,"right" : Vector3i.RIGHT
}

# Tambahkan dictionary untuk mengidentifikasi tipe ruangan
var room_types : Dictionary = {
	0: "normal",    # Ruangan normal
	1: "hallway",   # Koridor
	2: "junction",  # Persimpangan
	3: "border",    # Border zone - tidak perlu mesh
	4: "start",     # Ruang awal
	5: "end"        # Ruang akhir
}

func create_dungeon():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var t : int = 0
	
	# Dapatkan semua cell yang digunakan
	var used_cells = grid_map.get_used_cells()
	
	# Filter cell yang bukan borderzone (index != 3)
	for cell in used_cells:
		var cell_index : int = grid_map.get_cell_item(cell)
		if cell_index == 3:
			continue
			
		# Proses mesh hanya untuk cell valid (index 0-2, 4-5)
		if cell_index >= 0 && cell_index <= 5 && cell_index != 3:
			var dun_cell : Node3D = dun_cell_scene.instantiate()
			dun_cell.position = Vector3(cell) + Vector3(0.5,0,0.5)
			
			# Setup khusus berdasarkan tipe ruangan
			match cell_index:
				4: # Start room
					dun_cell.add_to_group("start_room")
				5: # End room
					dun_cell.add_to_group("end_room")
			
			add_child(dun_cell)
			dun_cell.set_owner(owner)
			t += 1
			
			# Periksa neighbors
			for i in 4:
				var cell_n : Vector3i = cell + directions.values()[i]
				var cell_n_index : int = grid_map.get_cell_item(cell_n)
				
				# Jika neighbor adalah borderzone atau di luar grid, handle sebagai none
				if cell_n_index == -1 || cell_n_index == 3:
					handle_none(dun_cell, directions.keys()[i])
				else:
					# Penanganan untuk cell valid
					var current_type = min(cell_index, 2) if cell_index < 4 else cell_index
					var neighbor_type = min(cell_n_index, 2) if cell_n_index < 4 else cell_n_index
					
					# Penanganan khusus untuk ruang start dan end
					if current_type >= 4 or neighbor_type >= 4:
						handle_special_room(dun_cell, directions.keys()[i], current_type, neighbor_type)
					else:
						var key : String = str(current_type) + str(neighbor_type)
						call("handle_" + key, dun_cell, directions.keys()[i])
						
		if t % 10 == 9:
			await get_tree().create_timer(0).timeout

func handle_none(cell:Node3D,dir:String):
	cell.call("remove_door_"+dir)
	
func handle_special_room(cell: Node3D, dir: String, current_type: int, neighbor_type: int):
	# Jika salah satu adalah ruang start atau end, perlakukan seperti ruang normal
	if current_type == 4 or current_type == 5:
		current_type = 0
	if neighbor_type == 4 or neighbor_type == 5:
		neighbor_type = 0
		
	var key : String = str(current_type) + str(neighbor_type)
	call("handle_" + key, cell, dir)

# Fungsi handle lainnya tetap sama
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
func handle_22(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)
