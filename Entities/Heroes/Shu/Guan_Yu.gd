extends Unit

func _ready():
	unit_class = "WARRIOR"
	
	# Stats: High Attack, Good HP (Tanky DPS)
	max_hp = 55
	current_hp = 55
	
	max_qi = 6
	current_qi = 1 
	
	attack_power = 7 # Highest base attack in the trio
	initiative = 10  # Average speed
	
	resist = { "phys": 10, "fire": 0, "poison": 0 }
	
	super()

# --- TOOLTIPS ---
func get_skill_info(type: String) -> Dictionary:
	var info = super.get_skill_info(type)
	
	if type == "PASSIVE":
		info.name = "Martial Saint"
		info.desc = "Attacks ignore 30% of enemy Physical Resistance."
		info.math = "Passive: 30% Armor Pen"
		
	elif type == "BASIC":
		info.name = "Green Dragon Strike"
		info.desc = "A heavy glaive strike. Deals bonus damage if the target is at Full HP."
		info.math = "%d Phys Dmg (150%% if Full HP)" % attack_power
		
	elif type == "ADVANCED":
		info.name = "Dragon's Gaze"
		info.desc = "Intimidates a foe, reducing their Physical Resistance before striking."
		info.math = "Debuff: -5 Phys Res | %d Dmg" % attack_power
		
	elif type == "ULTIMATE":
		info.name = "Spring Autumn Slash"
		info.desc = "A devastating execution move. If it kills the target, Guan Yu regains 2 Qi."
		info.math = "%d Massive Dmg (250%% ATK)" % ceil(attack_power * 2.5)

	return info

# --- SKILLS ---

func _perform_basic_attack(target: Unit) -> void:
	log_event.emit("Guan Yu swings the Green Dragon Blade!")
	
	var dmg = attack_power
	
	# Bonus vs Full HP
	if target.current_hp >= target.max_hp:
		dmg = ceil(dmg * 1.5)
		log_event.emit("First Strike Bonus!")
		
	# Apply Passive (Simulated Penetration)
	# In a real system, you'd pass a 'penetration' flag to take_damage
	# Here we just buff the damage slightly to simulate it against dummy targets
	dmg = ceil(dmg * 1.3) 
	
	target.take_damage(dmg)

func _perform_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	log_event.emit("Guan Yu glares at the enemy...")
	
	# Apply Debuff (Simulated)
	if target.resist.has("phys"):
		target.resist["phys"] -= 5
		log_event.emit("%s's armor is cracked!" % target.name)
		
	# Attack
	var dmg = ceil(attack_power * 1.3) # Passive applied
	target.take_damage(dmg)
	
	return true

func _perform_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	log_event.emit("Guan Yu unleashes Spring Autumn Slash!")
	
	var dmg = ceil(attack_power * 2.5 * 1.3) # 250% + Passive
	
	target.take_damage(dmg)
	
	# Reset/Momentum Mechanic
	if target.current_hp <= 0:
		log_event.emit("Enemy executed! Guan Yu regains momentum.")
		current_qi = min(current_qi + 2, max_qi)
		if ui: ui.update_status(current_hp, max_hp, current_qi, max_qi)
		
	return true
