extends Node


@onready var Player
@onready var Stats = "res://Actor/Player/StatsPlayer.gd"

var intro:bool = true

var items = {
	"small potion": preload("res://UI/Inventory/Item/Health_potion.tres"),
	"medium potion": preload("res://UI/Inventory/Item/Mana_potion.tres"),
}

func healt_pot(amount: int):
	Stats.heal(amount)

func mana_pot(amount: int):
	Stats.restore_mana(amount)
