extends Control

var stats:PlayerStats 
@onready var EXP_Bar =$stat_menu/left_cont/EXP
@onready var HP_Bar = $stat_menu/left_cont/HP
@onready var Mana_Bar =$stat_menu/left_cont/Mana
@export var condition:Dictionary = {
	"label1": NodePath(""),"label2": NodePath(""),"label3": NodePath(""),"label4" :NodePath(""),"label5" :NodePath(""),
	"label6" :NodePath(""),"label7" :NodePath("")
}
@export var basic_stat:Dictionary = {
	"label1": NodePath(""),"label2": NodePath(""),"label3": NodePath(""),"label4" :NodePath(""),"label5":NodePath(""),
	"label6":NodePath(""),"label7":NodePath("")
}
@export var offensive_stat:Dictionary = {
	"label1": NodePath(""),"label2": NodePath(""),"label3": NodePath(""),"label4" :NodePath(""),"label5":NodePath(""),
	"label6":NodePath("")
}
@export var deffensive_stat:Dictionary = {
	"label1": NodePath(""),"label2": NodePath(""),"label3": NodePath("")
}
@export var regen_stat:Dictionary = {
	"label1": NodePath(""),"label2": NodePath(""),"label3": NodePath(""),"label4": NodePath("")
}
var tx: Dictionary = {}

func _ready() -> void:
	stats = self.get_parent().get_parent().get_parent().get_child(0)
	print(stats.name)
	connect_condition()
	connect_basic_stats()
	connect_offensive_stats()
	connect_defensive_stats()
	connect_regen_stats()

func connect_condition():
	for key in condition:
		var path = condition[key]
		if path:
			tx[key] = get_node(path)
		else:
			print("NodePath untuk {key} belum diatur.")
	tx["label1"].text = "Lv." + str(stats.level)
	tx["label2"].text = str(stats.current_exp)
	tx["label3"].text = str(stats.max_exp)
	tx["label4"].text = str(stats.current_hp)
	tx["label5"].text = str(stats.max_hp)
	tx["label6"].text = str(stats.current_mana)
	tx["label7"].text = str(stats.max_mana)
	HP_Bar.max_value = stats.max_hp
	Mana_Bar.max_value = stats.max_mana
	EXP_Bar.max_value = stats.max_exp
	HP_Bar.value = stats.current_hp
	Mana_Bar.value = stats.current_mana
	EXP_Bar.value = stats.current_exp

func connect_basic_stats():
	for key in basic_stat:
		var path = basic_stat[key]
		if path:
			tx[key] = get_node(path)
		else:
			print("NodePath untuk {key} belum diatur.")
	tx["label1"].text = str(stats.level)
	tx["label2"].text = str(stats.current_exp)
	tx["label3"].text = str(stats.max_exp)
	tx["label4"].text = str(stats.current_hp)
	tx["label5"].text = str(stats.max_hp)
	tx["label6"].text = str(stats.current_mana)
	tx["label7"].text = str(stats.max_mana)

func connect_offensive_stats():
	for key in offensive_stat:
		var path = offensive_stat[key]
		if path:
			tx[key] = get_node(path)
		else:
			print("NodePath untuk {key} belum diatur.")
	tx["label1"].text = str(stats.physical_atk)
	tx["label2"].text = str(stats.crit_chance)
	tx["label3"].text = str(stats.physical_penetration)
	tx["label4"].text = str(stats.magical_atk)
	tx["label5"].text = str(stats.crit_damage)
	tx["label6"].text = str(stats.magical_penetration)

func connect_defensive_stats():
	for key in deffensive_stat:
		var path = deffensive_stat[key]
		if path:
			tx[key] = get_node(path)
		else:
			print("NodePath untuk {key} belum diatur.")
	tx["label1"].text = str(stats.physical_defense)
	tx["label2"].text = str(stats.magical_defense)
	tx["label3"].text = str(stats.hp_regen)

func connect_regen_stats():
	for key in regen_stat:
		var path = regen_stat[key]
		if path:
			tx[key] = get_node(path)
		else:
			print("NodePath untuk {key} belum diatur.")
	tx["label1"].text = str(stats.max_stamina)
	tx["label2"].text = str(stats.stamina_regen)
	tx["label3"].text = str(stats.mana_regen)
	tx["label4"].text = str(stats.move_speed)


func _on_str_btn_pressed() -> void:
	pass 

func _on_int_btn_pressed() -> void:
	pass # Replace with function body.

func _on_agi_btn_pressed() -> void:
	pass # Replace with function body.

func _on_end_btn_pressed() -> void:
	pass # Replace with function body.

func _on_vit_btn_pressed() -> void:
	pass # Replace with function body.
