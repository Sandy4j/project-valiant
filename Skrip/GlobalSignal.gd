extends Node


@onready var Player
@onready var Stats = "res://Actor/Player/StatsPlayer.gd"

var ui_show:bool 
var intro:bool = true

var items = {
	"small potion": preload("res://UI/Inventory/Item/Health_potion.tres"),
	"medium potion": preload("res://UI/Inventory/Item/Mana_potion.tres"),
}

func heal_pot(_amount: int):
	#Stats.heal(amount)
	pass
