extends Unit

func _ready():
	unit_class = "WARRIOR"
	max_hp = 14
	current_hp = 14
	max_qi = 6
	current_qi = 1 
	attack_power = 5
	initiative = 12 
	resist = { "phys": 10, "fire": 0, "poison": 0 }

func activate_passive(trigger: String, context: Dictionary = {}) -> void:
	if trigger == "on_attack":
		log_event.emit("Passive: Dragon's Courage! (+2 HP)")
		current_hp = min(current_hp + 2, max_hp)

func _perform_basic_attack(target: Unit) -> void:
	log_event.emit("Zhao Yun thrusts spear at " + target.name)
	activate_passive("on_attack") 
	target.take_damage(attack_power)

func _perform_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	log_event.emit("Zhao Yun uses Silver Flurry (Advanced)!")
	for i in range(3):
		if target.current_hp > 0:
			activate_passive("on_attack")
			target.take_damage(attack_power)
		else:
			break
	return true

func _perform_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	log_event.emit("Zhao Yun uses Sevenfold Breach (Ultimate)!")
	var hits_remaining = 7
	var current_target = target
	if current_target == null: return false
	
	while hits_remaining > 0:
		current_target.take_damage(ceil(attack_power * 0.8)) 
		activate_passive("on_attack")
		hits_remaining -= 1
		
		if hits_remaining <= 0: break
		
		var neighbors = TargetingSystem.get_adjacent_enemies(current_target.grid_pos, player_id, grid)
		if neighbors.is_empty(): break
		current_target = neighbors.pick_random()
		
	return true
