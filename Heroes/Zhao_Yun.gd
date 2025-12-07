# This file would be saved as res://Heroes/Hero_ZhaoYun.gd
extends Unit

func _ready():
	unit_class = "WARRIOR"
	
	# Resources
	max_hp = 14
	current_hp = 14
	max_qi = 6
	current_qi = 1 
	
	# Offensive
	attack_power = 5
	
	# Utility
	initiative = 12 
	
	# Defensive
	resist = {
		"phys": 10,
		"fire": 0,
		"poison": 0
	}

# --- 1. PASSIVE: Dragon's Courage ---
# Effect: Recover +2 HP whenever he attacks.
func activate_passive(trigger: String, context: Dictionary = {}) -> void:
	if trigger == "on_attack":
		print("Passive Triggered: Dragon's Courage! (+2 HP)")
		current_hp = min(current_hp + 2, max_hp)

# --- 2. BASIC: Spear Thrust ---
# Simple damage based on stats.
func use_basic_attack(target: Unit) -> void:
	print("Zhao Yun uses Basic Attack.")
	activate_passive("on_attack") # Trigger passive
	
	# Deal base attack damage (5)
	target.take_damage(attack_power)

# --- 3. ADVANCED: Silver Flurry ---
# Effect: Strike a single target 3 times.
func use_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	print("Zhao Yun uses Advanced Skill: Silver Flurry!")
	
	for i in range(3):
		if target.current_hp > 0:
			print("Flurry Hit ", i + 1)
			activate_passive("on_attack") # Trigger passive per hit
			target.take_damage(attack_power) # Deals 5 damage per hit
		else:
			break
			
	return true

# --- 4. ULTIMATE: Sevenfold Breach ---
# Effect: Hits 7 times, strictly bouncing between ADJACENT targets.
func use_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	print("Zhao Yun casts ULTIMATE: Sevenfold Breach!")
	
	var hits_remaining = 7
	var current_target = target
	
	if current_target == null: return false
	
	while hits_remaining > 0:
		# 1. Hit current target (80% damage scaling for ult hits)
		print("Sevenfold hit on ", current_target.grid_pos)
		current_target.take_damage(ceil(attack_power * 0.8)) 
		activate_passive("on_attack") # Trigger passive
		hits_remaining -= 1
		
		if hits_remaining <= 0: break
		
		# 2. Find valid ADJACENT neighbors to bounce to
		var neighbors = TargetingSystem.get_adjacent_enemies(current_target.grid_pos, player_id, grid)
		
		if neighbors.is_empty():
			print("Chain broken! No adjacent enemies to bounce to.")
			break
			
		# 3. Pick random neighbor (Allows A -> B -> A bouncing)
		current_target = neighbors.pick_random()
		
		# Optional: await get_tree().create_timer(0.1).timeout
		
	return true
