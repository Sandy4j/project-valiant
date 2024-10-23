@tool
extends Node3D

# References to required nodes
@export var grid_map_path: NodePath
@export var dunmesh_path: NodePath

@onready var grid_map = get_node(grid_map_path)
@onready var dunmesh = get_node(dunmesh_path)

# Export variable to trigger generation in editor
@export var generate_dungeon: bool = false : set = set_generate_dungeon

# Optional parameters for customization
@export var hide_grid_after_generation: bool = true
@export var generation_delay: float = 0.1

# Internal state tracking
var is_generating: bool = false

func set_generate_dungeon(value: bool) -> void:
	generate_dungeon = value
	if value and !is_generating:
		generate()

func _ready() -> void:
	# Ensure all required nodes are available
	if !grid_map:
		push_warning("GridMap node not assigned in LevelManager!")
		return
		
	if !dunmesh:
		push_warning("DunMesh node not assigned in LevelManager!")
		return

func generate() -> void:
	if !grid_map or !dunmesh:
		push_warning("Required nodes not assigned in LevelManager!")
		return
	
	if is_generating:
		return
		
	is_generating = true
	
	# Step 1: Clear existing dungeon
	clear_level()
	
	# Add small delay after clearing
	if Engine.is_editor_hint():
		await get_tree().create_timer(generation_delay).timeout
	
	# Step 2: Generate the procedural layout
	grid_map.generate()
	
	# Add small delay after grid generation
	if Engine.is_editor_hint():
		await get_tree().create_timer(generation_delay).timeout
	
	# Step 3: Hide the GridMap if specified
	if hide_grid_after_generation:
		grid_map.visible = false
	
	# Step 4: Create the dungeon meshes
	dunmesh.create_dungeon()
	
	# Reset states
	is_generating = false
	generate_dungeon = false

# Public function to trigger generation from code
func generate_level() -> void:
	generate_dungeon = true  # This will trigger set_generate_dungeon

# Function to reset/clear the level
func clear_level() -> void:
	if grid_map:
		grid_map.clear()
		grid_map.visible = true
	
	if dunmesh:
		for child in dunmesh.get_children():
			dunmesh.remove_child(child)
			child.queue_free()
