extends Node
class_name DebuffSystem

var active_debuffs: Dictionary = {}

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
	debuff["timer"].stop()
	debuff["timer"].wait_time = 5.0
	debuff["timer"].timeout.connect(
		func(): 
			active_debuffs[target].erase("cold")
			target.update_speed()
	)
	add_child(debuff["timer"])
	debuff["timer"].start()
	target.update_speed()

func remove_debuff(target: Object, debuff_type: String):
	if active_debuffs[target].has(debuff_type):
		active_debuffs[target][debuff_type]["timer"].queue_free()
		active_debuffs[target].erase(debuff_type)
