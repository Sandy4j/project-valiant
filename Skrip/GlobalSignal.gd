extends Node


@onready var Player
@onready var Stats: PlayerStatsController
@onready var Inv_Item:Inv_Slots

var impaused:bool = false
var ui_show:bool 
var intro:bool = true

var items = {
	"small potion": preload("res://UI/Inventory/Item/Health_potion.tres"),
	"medium potion": preload("res://UI/Inventory/Item/Mana_potion.tres"),
}
