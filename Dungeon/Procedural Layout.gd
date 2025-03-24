@tool
extends GridMap
signal is_generating()

@export var dunmesh_path: NodePath
@onready var dunmesh: Node3D = get_node(dunmesh_path)
@onready var parent = get_parent()

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
	if Engine.is_editor_hint():
		generate()
		
func get_border_size() -> int:
	return get_parent().border_size
	if Engine.is_editor_hint():
		visualize_border()

func update_seed() -> void:
	if get_parent().custom_seed != "":
		seed(get_parent().custom_seed.hash())

var room_tiles : Array[PackedVector3Array] = []
var room_positions : PackedVector3Array = []

var start_room_instance: Node3D = null
var end_room_instance: Node3D = null
var start_room_pos : Vector3
var end_room_pos : Vector3

func _ready():
	get_parent().custom_seed_changed.connect(_on_custom_seed_changed)

func _on_custom_seed_changed(new_seed: String) -> void:
	if new_seed != "":
		seed(new_seed.hash())

func create_start_room():
	var start_z = randi() % (parent.border_size - 2) + 1  
	start_room_pos = Vector3(0, 0, start_z)

	var start_room = PackedVector3Array([
		Vector3(0, 0, start_z),  # Cell pertama
		Vector3(1, 0, start_z)   # Cell kedua
	])

	for pos in start_room:
		set_cell_item(Vector3i(pos.x, pos.y, pos.z), 4)
	
	room_tiles.append(start_room)
	room_positions.append(start_room_pos)
	if dunmesh:
		dunmesh.instantiate_start_room(start_room_pos)

func create_end_room():
	var end_z = randi() % (parent.border_size - 3) + 1
	var end_x = parent.border_size - 2
	end_room_pos = Vector3(end_x, 0, end_z)
	
	var end_room = PackedVector3Array([
		Vector3(end_x, 0, end_z),
		Vector3(end_x + 1, 0, end_z),
		Vector3(end_x, 0, end_z + 1),
		Vector3(end_x + 1, 0, end_z + 1)
	])
	
	for pos in end_room:
		set_cell_item(Vector3i(pos.x, pos.y, pos.z), 5)

	room_tiles.append(end_room)
	room_positions.append(end_room_pos)
	if dunmesh:
		dunmesh.instantiate_end_room(end_room_pos)

func clear_room_instances():
	if dunmesh:
		dunmesh.clear_room_instances()

func visualize_border():
	clear()
	clear_room_instances()
	for i in range(-1, get_border_size() + 1):  # Use the getter to access the parent's border_size
		set_cell_item(Vector3i(i, 0, -1), 3) 
		set_cell_item(Vector3i(i, 0, get_border_size()), 3)
		set_cell_item(Vector3i(get_border_size(), 0, i), 3)
		set_cell_item(Vector3i(-1, 0, i), 3)

func generate():
	emit_signal("is_generating")
	room_tiles.clear()
	room_positions.clear()
	clear_room_instances()
	update_seed() 
	visualize_border()
	create_start_room()
	create_end_room()
	for i in parent.room_number:
		make_room(parent.room_recursion)
	
	var rpv2 : PackedVector2Array = []
	var del_graph : AStar2D = AStar2D.new()
	var mst_graph : AStar2D = AStar2D.new()
	
	for p in room_positions:
		rpv2.append(Vector2(p.x, p.z))
		del_graph.add_point(del_graph.get_available_point_id(), Vector2(p.x, p.z))
		mst_graph.add_point(mst_graph.get_available_point_id(), Vector2(p.x, p.z))
	
	var delaunay : Array = Array(Geometry2D.triangulate_delaunay(rpv2))
	for i in range(int(delaunay.size() / 3.0)): 
		var p1 : int = delaunay.pop_front()
		var p2 : int = delaunay.pop_front()
		var p3 : int = delaunay.pop_front()
		del_graph.connect_points(p1, p2)
		del_graph.connect_points(p2, p3)
		del_graph.connect_points(p1, p3)
	
	var visited_points : PackedInt32Array = []
	visited_points.append(0)

	while visited_points.size() != mst_graph.get_point_count():
		var possible_connections : Array[PackedInt32Array] = []
		for vp in visited_points:
			for c in del_graph.get_point_connections(vp):
				if !visited_points.has(c):
					var con : PackedInt32Array = [vp, c]
					possible_connections.append(con)
					
		if possible_connections.size() == 0:
			break  # Exit if there are no possible connections
		
		var connection : PackedInt32Array = possible_connections.pick_random()
		for pc in possible_connections:
			if rpv2[pc[0]].distance_squared_to(rpv2[pc[1]]) <\
			rpv2[connection[0]].distance_squared_to(rpv2[connection[1]]):
				connection = pc
				
		visited_points.append(connection[1])
		mst_graph.connect_points(connection[0], connection[1])
		del_graph.disconnect_points(connection[0], connection[1])
		
	var hallway_graph : AStar2D = mst_graph
	
	for p in del_graph.get_point_ids():
		for c in del_graph.get_point_connections(p):
			if c>p:
				var kill : float = randf()
				if parent.survival_chance > kill:
					hallway_graph.connect_points(p,c)
	
	create_hallways(hallway_graph)

func create_hallways(hallway_graph:AStar2D):
	var hallways :Array[PackedVector3Array] = []
	for p in hallway_graph.get_point_ids():
		for c in hallway_graph.get_point_connections(p):
			if c>p:
				var room_from : PackedVector3Array = room_tiles[p]
				var room_to : PackedVector3Array = room_tiles[c]
				var tile_from : Vector3 = room_from[0]
				var tile_to : Vector3 = room_to[0]
				for t in room_from:
					if t.distance_squared_to(room_positions[c])<\
					tile_from.distance_squared_to(room_positions[c]):
						tile_from = t
				for t in room_to:
					if t.distance_squared_to(room_positions[p])<\
					tile_to.distance_squared_to(room_positions[p]):
						tile_to = t
				var hallway : PackedVector3Array = [tile_from,tile_to]
				hallways.append(hallway)
				set_cell_item(tile_from,2)
				set_cell_item(tile_to,2) 
	
	var astar : AStarGrid2D = AStarGrid2D.new()
	var grid_size = Vector2i.ONE * parent.border_size
	astar.region = Rect2i(Vector2i.ZERO, grid_size)
	astar.update()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	for t in get_used_cells_by_item(0):
		astar.set_point_solid(Vector2i(t.x,t.z))
		
	var _t : int = 0
	for h in hallways:
		_t +=1
		var pos_from : Vector2i = Vector2i(int(h[0].x), int(h[0].z))
		var pos_to : Vector2i = Vector2i(int(h[1].x), int(h[1].z)) 
		var hall : PackedVector2Array = astar.get_point_path(pos_from,pos_to)

		for i in range(hall.size()):
			var current_pos = hall[i]
			var pos1 : Vector3i = Vector3i(int(current_pos.x), 0, int(current_pos.y))
			
			if get_cell_item(pos1) < 0 or get_cell_item(pos1) == 1:
				set_cell_item(pos1, 1)

			if i == 0 or i == hall.size() - 1:
				set_cell_item(pos1, 2)
		
		if _t%16 == 15: 
			await get_tree().create_timer(0).timeout

func make_room(rec:int):
	if !rec>0:
		return
	var width : int = (randi() % (parent.max_room_size - parent.min_room_size)) + parent.min_room_size
	var height : int = (randi() % (parent.max_room_size - parent.min_room_size)) + parent.min_room_size
	var start_pos : Vector3i 
	start_pos.x = randi() % (parent.border_size - width - 2) + 2
	start_pos.z = randi() % (parent.border_size - height + 1)

	for r in range(-parent.room_margin, height+parent.room_margin):
		for c in range(-parent.room_margin, width+parent.room_margin):
			var pos : Vector3i = start_pos + Vector3i(c,0,r)
			if get_cell_item(pos) == 0:
				make_room(rec-1)
				return
	var room : PackedVector3Array = []
	for r in height:
		for c in width:
			var pos : Vector3i = start_pos + Vector3i(c,0,r)
			set_cell_item(pos,0)
			room.append(pos)
	room_tiles.append(room)
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos_avg : Vector3 = Vector3(avg_x,0,avg_z)
	room_positions.append(pos_avg)
