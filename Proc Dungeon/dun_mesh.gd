@tool
extends Node3D

@export var grid_map_path : NodePath
var grid_map : GridMap

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
	start = val
	if Engine.is_editor_hint() and start:
		call_deferred("create_dungeon")

var dun_cell_scene : PackedScene = preload("res://Proc Dungeon/imports/DunCell.tscn")
var start_position : Vector3i
var end_position : Vector3i
var border_size : int

var directions : Dictionary = {
	"up" : Vector3i.FORWARD,"down" : Vector3i.BACK,
	"left" : Vector3i.LEFT,"right" : Vector3i.RIGHT
}
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

func handle_22(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)

func handle_default(cell:Node3D,dir:String):
	cell.call("remove_wall_"+dir)
	cell.call("remove_door_"+dir)

func create_dungeon():
	if not is_inside_tree():
		push_warning("Node not inside tree, deferring dungeon creation.")
		call_deferred("create_dungeon")
		return

	if not grid_map:
		grid_map = get_node_or_null(grid_map_path)
		if not grid_map:
			push_error("GridMap not found. Please check the GridMap path.")
			return

	for c in get_children():
		remove_child(c)
		c.queue_free()
	
	find_start_end_positions()
	
	# Get the border size
	var used_cells = grid_map.get_used_cells()
	border_size = 0
	for cell in used_cells:
		border_size = max(border_size, max(cell.x, cell.z))
	border_size += 1  # Add 1 because indices start at 0
	
	var t : int = 0
	for cell in used_cells:
		var cell_index : int = grid_map.get_cell_item(cell)
		if cell_index <= 5 && cell_index >= 0 && !is_border_cell(cell):
			var dun_cell : Node3D = dun_cell_scene.instantiate()
			dun_cell.position = Vector3(cell) + Vector3(0.5,0,0.5)
			add_child(dun_cell)
			t += 1
			
			if cell == start_position:
				handle_special_room(dun_cell, cell, true)
			elif cell == end_position:
				handle_special_room(dun_cell, cell, false)
			else:
				for i in 4:
					var cell_n : Vector3i = cell + directions.values()[i]
					var cell_n_index : int = grid_map.get_cell_item(cell_n)
					if cell_n_index == -1 || cell_n_index == 3 || is_border_cell(cell_n):
						handle_none(dun_cell, directions.keys()[i])
					else:
						var key : String = str(cell_index) + str(cell_n_index)
						var method_name = "handle_" + key
						if has_method(method_name):
							call(method_name, dun_cell, directions.keys()[i])
						else:
							handle_default(dun_cell, directions.keys()[i])
		
		if t % 10 == 9 : await get_tree().create_timer(0).timeout

func find_start_end_positions():
	for cell in grid_map.get_used_cells():
		var cell_index : int = grid_map.get_cell_item(cell)
		if cell_index == 4:
			start_position = cell
		elif cell_index == 5:
			end_position = cell

func handle_special_room(cell: Node3D, position: Vector3i, is_start: bool):
	for dir in directions.keys():
		var neighbor_pos = position + directions[dir]
		if is_border_cell(neighbor_pos):
			if is_start:
				# For start position, keep the wall/door facing the border
				continue
			else:
				# For end position, remove wall and door facing the border
				cell.call("remove_wall_" + dir)
				cell.call("remove_door_" + dir)
		else:
			# Remove both wall and door in other directions
			cell.call("remove_wall_" + dir)
			cell.call("remove_door_" + dir)

func is_border_cell(pos: Vector3i) -> bool:
	return pos.x == 0 or pos.x == border_size - 1 or pos.z == 0 or pos.z == border_size - 1

func _ready():
	if not Engine.is_editor_hint():
		grid_map = get_node_or_null(grid_map_path)
		if not grid_map:
			push_error("GridMap not found. Please check the GridMap path.")
	elif start:
		call_deferred("create_dungeon")

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()
	if not grid_map_path or not has_node(grid_map_path):
		warnings.append("GridMap path is not set or invalid.")
	return warnings
