extends Node


@onready var Player
@onready var Stats = "res://Actor/Player/StatsPlayer.gd"

var items = {
	"small potion": preload("res://UI/Inventory/Item/S_HP_Potion.tres"),
}

func heal_pot(_amount: int):
	#Stats.heal(amount)
	pass
