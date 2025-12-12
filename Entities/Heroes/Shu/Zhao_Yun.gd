extends Unit

func _ready():
	unit_class = "WARRIOR"
	max_hp = 50
	current_hp = 50
	max_qi = 6
	current_qi = 1 
	attack_power = 5
	initiative = 12 
	resist = { "phys": 10, "fire": 0, "poison": 0 }
	
	super()

# --- TARGETING CONFIGURATION ---
func get_skill_target_type(skill_mode: String) -> String:
	if skill_mode == "BASIC":
		return TargetingSystem.TARGET_FRONT_ENEMY
	elif skill_mode == "ADVANCED":
		return TargetingSystem.TARGET_FRONT_ENEMY 
	elif skill_mode == "ULTIMATE":
		return TargetingSystem.TARGET_FRONT_ENEMY 
	return TargetingSystem.TARGET_SELF

# --- TOOLTIPS ---
func get_skill_info(type: String) -> Dictionary:
	var info = super.get_skill_info(type)
	
	if type == "PASSIVE":
		info.name = "Dragon's Courage"
		info.desc = "Innate Battle Spirit."
		info.math = "Recover 2 HP whenever you land a direct hit."
		
	elif type == "BASIC":
		info.name = "Spear Thrust"
		info.desc = "Thrusts spear at target. Triggers Passive and on-hit effects."
		info.math = "%d Phys Dmg (100%% ATK)" % attack_power
		
	elif type == "ADVANCED":
		info.name = "Silver Flurry"
		info.desc = "Attacks 3 times continuously. Each hit triggers Passive and on-hit effects."
		var per_hit = ceil(attack_power * 0.8)
		var total = per_hit * 3
		info.math = "%d Total Dmg (3 hits x %d) (80%% ATK)" % [total, per_hit]
		
	elif type == "ULTIMATE":
		info.name = "Sevenfold Breach"
		info.desc = "Attacks 7 times. Each hit triggers Passive and on-hit effects."
		var per_hit = ceil(attack_power * 0.8)
		var total = per_hit * 7
		info.math = "%d Total Dmg (7 hits x %d) (80%% ATK)" % [total, per_hit]
		
	return info

# --- SKILLS ---

func activate_passive(trigger: String, context: Dictionary = {}) -> void:
	if trigger == "on_attack":
		log_event.emit("Passive: Dragon's Courage! (+2 HP)")
		current_hp = min(current_hp + 2, max_hp)
		if ui: ui.update_status(current_hp, max_hp, current_qi, max_qi)

func _perform_basic_attack(target: Unit) -> void:
	log_event.emit("Zhao Yun thrusts spear at " + target.name)
	activate_passive("on_attack") 
	target.take_damage(attack_power)

func _perform_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	log_event.emit("Zhao Yun uses Silver Flurry (Advanced)!")
	
	var dmg = ceil(attack_power * 0.8) # 80% Damage
	
	for i in range(3):
		if target.current_hp > 0:
			activate_passive("on_attack")
			target.take_damage(dmg)
		else:
			break
	return true
func _perform_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	log_event.emit("Zhao Yun uses Sevenfold Breach (Ultimate)!")
	
	var dmg = ceil(attack_power * 0.8) # 80% Damage
	var hits_remaining = 7
	var current_target = target
	
	if not is_instance_valid(current_target):
		return false
	
	while hits_remaining > 0:
		# 1. Deal Damage
		# Check instance validity (in case they were freed in a previous iteration)
		if not is_instance_valid(current_target):
			break

		current_target.take_damage(dmg) 
		activate_passive("on_attack")
		hits_remaining -= 1
		
		# If we finished all hits, stop immediately
		if hits_remaining <= 0:
			break
		
		# 2. Bounce Logic
		# We look for the TARGET'S allies (which are our enemies) to bounce to.
		# Note: We pass current_target.player_id to find units on THEIR team.
		var bounce_candidates = TargetingSystem.get_adjacent_allies(
			current_target.grid_pos, 
			current_target.player_id, 
			grid
		)
		
		if bounce_candidates.size() > 0:
			# If neighbors exist, bounce to a random one for the next hit
			var next_pos = bounce_candidates.pick_random()
			var next_unit = grid[next_pos]
			
			# Log the bounce if the target changed
			if next_unit != current_target:
				log_event.emit("Sevenfold Breach bounces to %s!" % next_unit.name)
				current_target = next_unit
		else:
			# No neighbors to bounce to
			if current_target.current_hp <= 0:
				# Target is dead AND no neighbors -> Chain breaks
				log_event.emit("Target eliminated. No adjacent enemies to chain to.")
				break
			else:
				# Target is alive but isolated -> Continue hitting the same target
				pass 
		
	return true
