extends Unit

# --- EQUIPMENT FLAGS ---
var has_shuang_gu_jian: bool = false
var has_dilu_horse: bool = false

func _ready():
	unit_class = "SUPPORT"
	
	# Stats: Durable Support (需要高血量来支撑卖血技能)
	max_hp = 55 
	current_hp = 55
	
	max_qi = 8
	current_qi = 3 
	
	attack_power = 4 
	initiative = 9
	
	resist = { "phys": 10, "fire": 0, "poison": 0 }
	
	super()

# --- TOOLTIPS ---
func get_skill_info(type: String) -> Dictionary:
	var info = super.get_skill_info(type)
	
	if type == "PASSIVE": #复兴汉室
		info.name = "Restore the Han"
		info.desc = "The blood of emperors."
		info.math = "Basic Attacks generate Qi for the team."
		
	elif type == "BASIC":
		if has_shuang_gu_jian:
			info.name = "Twin Dragon Strike (Legendary)"
			info.desc = "[Shuang Gu Jian] Strikes twice! Both hits trigger passive Qi restoration."
			var total = attack_power * 2
			info.math = "%d Total Dmg (2 hits x %d)" % [total, attack_power]
		else:
			info.name = "Virtuous Strike"
			info.desc = "Strikes a foe. If the hit lands, restores 1 Qi to a random ally."
			info.math = "%d Phys Dmg (100%% ATK)" % attack_power
		
	elif type == "ADVANCED":
		info.name = "Virtue's Rebuke" # 使用“以德服人”作为 ADV
		info.desc = "Shames an enemy with righteousness. Deals light damage and reduces their Attack Power by 50% for 1 turn."
		info.math = "%d Dmg + Weaken (50%%)" % ceil(attack_power * 0.5)
		
	elif type == "ULTIMATE":
		info.name = "The People's Shield" # 携民渡江
		info.desc = "Sacrifices his own vitality to protect the team. Liu Bei loses 30% Current HP to grant adjacent allies a Shield equal to 30% of their Max HP."
		info.math = "Buff: Shield (30% Max HP) | Cost: 30% Self Current HP"

	return info

# --- SKILLS ---

func _perform_basic_attack(target: Unit) -> void:
	if has_shuang_gu_jian:
		_perform_legendary_basic_attack(target)
	else:
		_perform_standard_basic_attack(target)

func _perform_standard_basic_attack(target: Unit):
	log_event.emit("Liu Bei uses Virtuous Strike!")
	if target.current_hp > 0:
		target.take_damage(attack_power)
		_restore_ally_qi()

func _perform_legendary_basic_attack(target: Unit):
	log_event.emit("Liu Bei uses Twin Dragon Strike!")
	var dmg_per_hit = attack_power 
	
	if target.current_hp > 0:
		target.take_damage(dmg_per_hit)
		_restore_ally_qi() 
		
	if target.current_hp > 0:
		target.take_damage(dmg_per_hit)
		_restore_ally_qi()

func _perform_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	# Virtue's Rebuke (Debuff)
	log_event.emit("Liu Bei rebukes the enemy!")
	
	var dmg = ceil(attack_power * 0.5)
	target.take_damage(dmg)
	
	# Apply Weakness (Simplified: Direct stat mod)
	# TODO: Use Status Effect system when ready
	target.attack_power = max(1, floor(target.attack_power * 0.5))
	log_event.emit("%s is shamed! Attack halved." % target.name)
		
	return true

func _perform_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	log_event.emit("Liu Bei sacrifices himself for the people!")
	
	# 1. Cost: 30% Current HP
	var sacrifice_amount = floor(current_hp * 0.3)
	# Ensure he doesn't kill himself completely (leave at least 1 HP unless you want heroic death)
	current_hp = max(1, current_hp - sacrifice_amount) 
	
	log_event.emit("Liu Bei sacrifices %d HP!" % sacrifice_amount)
	if ui: ui.update_status(current_hp, max_hp, current_qi, max_qi)
	
	# 2. Effect: Shield for Adjacent Allies
	# Note: Only affects ADJACENT allies (to encourage positioning / formation)
	# If you want GLOBAL, change get_adjacent_allies to get_all_allies logic
	var board = get_parent().grid_manager
	var neighbors = TargetingSystem.get_adjacent_allies(grid_pos, player_id, board.grid)
	
	for ally in neighbors:
		var shield_amount = floor(ally.max_hp * 0.3)
		_apply_shield(ally, shield_amount)
			
	log_event.emit("Adjacent allies shielded by Liu Bei's sacrifice!")
	return true

# --- HELPERS ---

func _restore_ally_qi():
	var board = get_parent().grid_manager
	if board:
		var allies = board.get_all_units().filter(func(u): return u.player_id == player_id and u != self)
		if allies.size() > 0:
			var lucky_ally = allies.pick_random()
			lucky_ally.current_qi = min(lucky_ally.current_qi + 1, lucky_ally.max_qi)
			if lucky_ally.ui:
				lucky_ally.ui.update_status(lucky_ally.current_hp, lucky_ally.max_hp, lucky_ally.current_qi, lucky_ally.max_qi)
			log_event.emit("Liu Bei restores 1 Qi to %s!" % lucky_ally.name)

func _apply_shield(unit: Unit, amount: int):
	# Placeholder for Shield System: Adds Temp HP
	# This effectively heals them past max HP for this battle logic
	unit.current_hp = unit.current_hp + amount
	# We don't cap at max_hp here to simulate a "Shield" on top of health
	
	if unit.ui: unit.ui.update_status(unit.current_hp, unit.max_hp, unit.current_qi, unit.max_qi)
	log_event.emit("%s gained %d Shield!" % [unit.name, amount])
