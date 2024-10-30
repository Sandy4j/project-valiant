extends Node

signal layout_generated


@onready var Player = "res://Actor/Player/Player.tscn"
@onready var Stats = "res://Actor/Player/StatsPlayer.gd"

var items = {
	"small potion": preload("res://UI/Inventory/Item/S_HP_Potion.tres"),
}

func heal_pot(amount: int):
	#Stats.heal(amount)
	pass
