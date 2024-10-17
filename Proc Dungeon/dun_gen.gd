@tool
extends Node3D

@onready var grid_map : GridMap = $GridMap

func _ready():
	GlobalSignal.grid_map = grid_map

@export var start : bool = false : set = set_start
func set_start(val:bool)->void:
	if Engine.is_editor_hint():
		generate()
		GlobalSignal.generate_layout()
		
@export_range(0,1) var survival_chance : float = 0.25
@export var border_size : int = 20 : set = set_border_size
func set_border_size(val : int)->void:
	border_size = val
	if Engine.is_editor_hint():
		visualize_border()

@onready var spawn_p_scene : PackedScene = preload("res://Proc Dungeon/level/spawnP.tscn")
@onready var level_change_scene : PackedScene = preload("res://Proc Dungeon/level/levelchange.tscn")
var room_tiles : Array[PackedVector3Array] = []
var room_positions : PackedVector3Array = []
var start_position : Vector3i
var end_position : Vector3i

@export var room_number : int = 4
@export var room_margin : int = 1
@export var room_recursion : int = 15
@export var min_room_size : int = 2 
@export var max_room_size : int = 4
@export_multiline var custom_seed : String = "" : set = set_seed 
func set_seed(val:String)->void:
	custom_seed = val
	seed(val.hash())

func visualize_border():
	grid_map.clear()
	for i in range(-1,border_size+1):
		grid_map.set_cell_item( Vector3i(i,0,-1),3)
		grid_map.set_cell_item( Vector3i(i,0,border_size),3)
		grid_map.set_cell_item( Vector3i(border_size,0,i),3)
		grid_map.set_cell_item( Vector3i(-1,0,i),3)
	
func generate():
	room_tiles.clear()
	room_positions.clear()
	if custom_seed : set_seed(custom_seed)
	visualize_border()
	for i in room_number:
		make_room(room_recursion)
	
	var rpv2 : PackedVector2Array = []
	var del_graph : AStar2D = AStar2D.new()
	var mst_graph : AStar2D = AStar2D.new()
	
	for p in room_positions:
		rpv2.append(Vector2(p.x,p.z))
		del_graph.add_point(del_graph.get_available_point_id(),Vector2(p.x,p.z))
		mst_graph.add_point(mst_graph.get_available_point_id(),Vector2(p.x,p.z))
	
	var delaunay : Array = Array(Geometry2D.triangulate_delaunay(rpv2))
	
	for i in delaunay.size()/3:
		var p1 : int = delaunay.pop_front()
		var p2 : int = delaunay.pop_front()
		var p3 : int = delaunay.pop_front()
		del_graph.connect_points(p1,p2)
		del_graph.connect_points(p2,p3)
		del_graph.connect_points(p1,p3)
		
	var visited_points : PackedInt32Array = []
	visited_points.append(randi() % room_positions.size())
	while visited_points.size() != mst_graph.get_point_count():
		var possible_connections : Array[PackedInt32Array] = []
		for vp in visited_points:
			for c in del_graph.get_point_connections(vp):
				if !visited_points.has(c):
					var con : PackedInt32Array = [vp,c]
					possible_connections.append(con)
					
		var connection : PackedInt32Array = possible_connections.pick_random()
		for pc in possible_connections:
			if rpv2[pc[0]].distance_squared_to(rpv2[pc[1]]) <\
			rpv2[connection[0]].distance_squared_to(rpv2[connection[1]]):
				connection = pc
		
		visited_points.append(connection[1])
		mst_graph.connect_points(connection[0],connection[1])
		del_graph.disconnect_points(connection[0],connection[1])
		
		var hallway_graph : AStar2D = mst_graph
	
		for p in del_graph.get_point_ids():
			for c in del_graph.get_point_connections(p):
				if c>p:
					var kill : float = randf()
					if survival_chance > kill :
						hallway_graph.connect_points(p,c)
		create_hallways(hallway_graph)
	
	create_start_end_positions()
	GlobalSignal.is_layout_generated = true
	GlobalSignal.emit_signal("layout_generated")

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
				grid_map.set_cell_item(tile_from,2)
				grid_map.set_cell_item(tile_to,2)
	var astar : AStarGrid2D = AStarGrid2D.new()
	astar.size = Vector2i.ONE * border_size
	astar.update()
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	
	for t in grid_map.get_used_cells_by_item(0):
		astar.set_point_solid(Vector2i(t.x,t.z))
	var _t : int = 0
	for h in hallways:
		_t +=1
		var pos_from : Vector2i = Vector2i(h[0].x,h[0].z)
		var pos_to : Vector2i = Vector2i(h[1].x,h[1].z)
		var hall : PackedVector2Array = astar.get_point_path(pos_from,pos_to)
		
		for t in hall:
			var pos : Vector3i = Vector3i(t.x,0,t.y)
			if grid_map.get_cell_item(pos) <0:
				grid_map.set_cell_item(pos,1)
		if _t%16 == 15: await  get_tree().create_timer(0).timeout

func make_room(rec:int):
	if !rec>0:
		return
	
	var width : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	var height : int = (randi() % (max_room_size - min_room_size)) + min_room_size
	
	var start_pos : Vector3i 
	start_pos.x = randi() % (border_size - width + 1)
	start_pos.z = randi() % (border_size - height + 1)
	
	for r in range(-room_margin,height+room_margin):
		for c in range(-room_margin,width+room_margin):
			var pos : Vector3i = start_pos + Vector3i(c,0,r)
			if grid_map.get_cell_item(pos) == 0:
				make_room(rec-1)
				return
	
	var room : PackedVector3Array = []
	for r in height:
		for c in width:
			var pos : Vector3i = start_pos + Vector3i(c,0,r)
			grid_map.set_cell_item(pos,0)
			room.append(pos)
	room_tiles.append(room)
	var avg_x : float = start_pos.x + (float(width)/2)
	var avg_z : float = start_pos.z + (float(height)/2)
	var pos : Vector3 = Vector3(avg_x,0,avg_z)
	room_positions.append(pos)

func create_start_end_positions():
	var room_indices = range(room_tiles.size())
	room_indices.shuffle()
	
	# Pilih ruangan untuk posisi start
	var start_room = room_tiles[room_indices[0]]
	start_position = select_edge_position_near_border(start_room)
	grid_map.set_cell_item(start_position, 4)  # Gunakan mesh index 4 untuk start
	
	# Pilih ruangan untuk posisi end (pastikan berbeda dengan ruangan start)
	var end_room = room_tiles[room_indices[1]]
	end_position = select_edge_position_near_border(end_room)
	grid_map.set_cell_item(end_position, 5)  # Gunakan mesh index 5 untuk end
	
	print("Start position: ", start_position)
	print("End position: ", end_position)
	spawn_scene_at_position(spawn_p_scene, start_position)
	var existing_spawn_points = get_tree().get_nodes_in_group("spawn_point")
	for sp in existing_spawn_points:
		sp.queue_free()
	spawn_scene_at_position(spawn_p_scene, start_position)
	
	spawn_scene_at_position(level_change_scene, end_position)
	
func spawn_scene_at_position(scene: PackedScene, position: Vector3i):
	if scene:
		var instance = scene.instantiate()
		if instance.is_in_group("spawn_point"):
			# Pastikan hanya ada satu spawn point
			var existing_spawn_points = get_tree().get_nodes_in_group("spawn_point")
			for sp in existing_spawn_points:
				sp.queue_free()
		add_child(instance)
		instance.global_transform.origin = Vector3(position.x, 0, position.z)
	else:
		print("Warning: Scene not assigned for position ", position)

func select_edge_position_near_border(room: PackedVector3Array) -> Vector3i:
	var min_x = room[0].x
	var max_x = room[0].x
	var min_z = room[0].z
	var max_z = room[0].z

	for tile in room:
		min_x = min(min_x, tile.x)
		max_x = max(max_x, tile.x)
		min_z = min(min_z, tile.z)
		max_z = max(max_z, tile.z)
	var distances = {
		"top": min_z,
		"right": border_size - max_x,
		"bottom": border_size - max_z,
		"left": min_x
	}
	var closest_side = "top"
	for side in distances:
		if distances[side] < distances[closest_side]:
			closest_side = side
	match closest_side:
		"top":
			return Vector3i(randi_range(min_x, max_x), 0, min_z)
		"right":
			return Vector3i(max_x, 0, randi_range(min_z, max_z))
		"bottom":
			return Vector3i(randi_range(min_x, max_x), 0, max_z)
		"left":
			return Vector3i(min_x, 0, randi_range(min_z, max_z))
	return Vector3i(min_x, 0, min_z)
