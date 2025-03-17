extends Node


@onready var Player
@onready var Stats: PlayerStatsController
@onready var Inv_Item:Inv_Slots

var impaused:bool = false
var ui_show:bool 
var intro:bool = true
var saved_stats: Dictionary = {} 

var items = {
	"small potion": preload("res://UI/Inventory/Item/Health_potion.tres"),
	"medium potion": preload("res://UI/Inventory/Item/Mana_potion.tres"),
}

func save_player_stats(stats_controller: PlayerStatsController) -> void:
	saved_stats = stats_controller.save_stats()

func apply_saved_stats_to_player(player_node: Node) -> bool:
	if saved_stats.is_empty():
		print("GlobalSignal: No saved stats to apply")
		return false
		
	var stats_controller = player_node.get_node_or_null("PlayerFunction/PlayerStats")
	if stats_controller:
		print("GlobalSignal: Applying saved stats: ", saved_stats)
		stats_controller.load_stats(saved_stats)
		return true
	else:
		print("GlobalSignal: Could not find PlayerStats node")
		return false

func change_scene_and_save_stats(target_scene_path: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var stats = player.get_node_or_null("PlayerFunction/PlayerStats")
		if stats:
			saved_stats = stats.save_stats()
	get_tree().change_scene_to_file(target_scene_path)
