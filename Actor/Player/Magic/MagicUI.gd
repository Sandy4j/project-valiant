extends MarginContainer

@onready var firebolt_slot = $HBoxContainer/SpellSlot1
@onready var blizzard_slot = $HBoxContainer/SpellSlot2

func _ready():
	update_spell_ui()
	
	var magic_system = self.get_parent().get_parent().get_parent().get_child(0).get_child(4)

	if magic_system:
		magic_system.spell_cooldown_updated.connect(update_cooldown)
	else:
		push_error("MagicSystem tidak ditemukan!")

func update_spell_ui():
	# Firebolt
	firebolt_slot.get_node("ManaCost").text = str(30)
	firebolt_slot.get_node("cdBar").max_value = 3.0
	
	# Blizzard
	blizzard_slot.get_node("ManaCost").text = str(45)
	blizzard_slot.get_node("cdBar").max_value = 5.0

func update_cooldown(spell_name: String, cooldown: float):
	match spell_name:
		"firebolt":
			firebolt_slot.get_node("cdBar").value = cooldown
		"blizzard":
			blizzard_slot.get_node("cdBar").value = cooldown
