extends Node
class_name DebuffSystem

var active_debuffs: Dictionary = {}

func _ready():
	add_to_group("debuff_system")

func apply_debuff(target: Object, debuff_type: String):
	if not active_debuffs.has(target):
		active_debuffs[target] = {}
	
	match debuff_type:
		"burn":
			start_burn(target)
		"cold":
			add_cold_stack(target)

func start_burn(target: Object):
	if active_debuffs[target].has("burn"):
		return
	
	active_debuffs[target]["burn"] = {
		"ticks_remaining": 8,
		"timer": Timer.new()
	}
	
	var timer = active_debuffs[target]["burn"]["timer"]
	add_child(timer)
	timer.wait_time = 0.6
	timer.timeout.connect(
		func(): 
			if is_instance_valid(target) and target.has_method("take_damage"):
				target.take_damage(7)
				active_debuffs[target]["burn"]["ticks_remaining"] -= 1
				if active_debuffs[target]["burn"]["ticks_remaining"] <= 0:
					remove_debuff(target, "burn")
	)
	timer.start()

func add_cold_stack(target: Object):
	if not active_debuffs[target].has("cold"):
		active_debuffs[target]["cold"] = {
			"stacks": 0,
			"timer": Timer.new()
		}
	
	var debuff = active_debuffs[target]["cold"]
	debuff["stacks"] = min(5, debuff["stacks"] + 1)
	
	if debuff["timer"].is_connected("timeout", Callable()):
		debuff["timer"].timeout.disconnect(Callable())
		
	debuff["timer"].stop()
	debuff["timer"].wait_time = 5.0
	debuff["timer"].timeout.connect(
		func(): 
			if is_instance_valid(target):
				active_debuffs[target].erase("cold")
				if target.has_method("update_speed"):
					target.update_speed()
	)
	
	if debuff["timer"].get_parent() == null:
		add_child(debuff["timer"])
		
	debuff["timer"].start()
	
	if target.has_method("update_speed"):
		target.update_speed()

func remove_debuff(target: Object, debuff_type: String):
	if is_instance_valid(target) and active_debuffs.has(target) and active_debuffs[target].has(debuff_type):
		active_debuffs[target][debuff_type]["timer"].queue_free()
		active_debuffs[target].erase(debuff_type)

func get_debuff_stacks(target: Object, debuff_type: String) -> int:
	if is_instance_valid(target) and active_debuffs.has(target) and active_debuffs[target].has(debuff_type):
		if debuff_type == "cold":
			return active_debuffs[target][debuff_type]["stacks"]
	return 0

func is_debuff_active(target: Object, debuff_type: String) -> bool:
	return is_instance_valid(target) and active_debuffs.has(target) and active_debuffs[target].has(debuff_type)
