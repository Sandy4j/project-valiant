extends Node

signal layout_generated
signal mesh_generated

var items = {
	"small potion": preload("res://UI/Inventory/Item/S_HP_Potion.tres"),
}
var grid_map: GridMap
var procedural_dungeon: Node
var dun_mesh: Node
var is_layout_generated: bool = false
var is_mesh_generated: bool = false

func initialize(p_dungeon: Node, d_mesh: Node):
	procedural_dungeon = p_dungeon
	dun_mesh = d_mesh
	if procedural_dungeon:
		grid_map = procedural_dungeon.get_node("GridMap")

func generate_layout():
	if grid_map and procedural_dungeon:
		grid_map.clear()
		procedural_dungeon.generate()
		is_layout_generated = true
		emit_signal("layout_generated")
	else:
		print("Error: ProceduralDungeon or GridMap not initialized")

func create_mesh():
	if is_layout_generated and dun_mesh:
		dun_mesh.create_dungeon()
		is_mesh_generated = true
		emit_signal("mesh_generated")
	else:
		print("Error: Layout not generated or DunMesh not initialized")

func reset():
	is_layout_generated = false
	is_mesh_generated = false
	if grid_map:
		grid_map.clear()
