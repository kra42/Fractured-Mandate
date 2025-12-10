extends Unit

func _ready():
	unit_class = "SUPPORT"
	
	# Support Stats: High HP, High Max Qi, Good Starting Qi
	max_hp = 45
	current_hp = 45
	
	max_qi = 8
	current_qi = 3 # Starts with enough to cast Advanced Skill immediately
	
	attack_power = 3 # Low damage, he is a leader not a duelist
	initiative = 9   # Slightly slower than fast warriors
	
	resist = { "phys": 5, "fire": 0, "poison": 0 }
	
	super()

# --- TOOLTIPS ---
func get_skill_info(type: String) -> Dictionary:
	var info = super.get_skill_info(type)
	
	if type == "BASIC":
		info.name = "Twin Sword Strike"
		info.desc = "Strikes a foe and inspires an ally. Restores 1 Qi to a random ally."
		info.math = "%d Phys Dmg (100%% ATK)" % attack_power
		
	elif type == "ADVANCED":
		info.name = "Moral Boost"
		info.desc = "Commands an ally to fight harder. Grants +3 ATK to target ally for 2 turns."
		info.math = "Buff: +3 ATK"
		
	elif type == "ULTIMATE":
		info.name = "Oath of the Peach Garden"
		info.desc = "Heals ALL allies and grants a massive damage boost for 1 round."
		info.math = "Heal: 15 HP | Buff: +50% Dmg"

	elif type == "PASSIVE":
		info.name = "Benevolence"
		info.desc = "Aura of kindness."
		info.math = "Heal adjacent allies for 3 HP at start of turn."
		
	return info

# --- SKILLS ---

# Passive Trigger: Called by TurnManager/BattleController at start of turn
func on_turn_start() -> void:
	super.on_turn_start() # Gain standard 1 Qi
	
	# Passive: Heal Adjacent Allies
	log_event.emit("Passive: Benevolence shines!")
	var board = get_parent().grid_manager # Access grid via parent BattleController
	if board:
		var neighbors = TargetingSystem.get_adjacent_allies(grid_pos, player_id, board.grid)
		for ally in neighbors:
			ally.current_hp = min(ally.current_hp + 3, ally.max_hp)
			ally.ui.update_status(ally.current_hp, ally.max_hp, ally.current_qi, ally.max_qi)
			# Optional: Spawn floating text specifically on ally?
			
func _perform_basic_attack(target: Unit) -> void:
	log_event.emit("Liu Bei strikes with Twin Swords!")
	target.take_damage(attack_power)
	
	# Secondary Effect: Restore Qi to ally
	var board = get_parent().grid_manager
	if board:
		var allies = board.get_all_units().filter(func(u): return u.player_id == player_id and u != self)
		if allies.size() > 0:
			var lucky_ally = allies.pick_random()
			lucky_ally.current_qi = min(lucky_ally.current_qi + 1, lucky_ally.max_qi)
			lucky_ally.ui.update_status(lucky_ally.current_hp, lucky_ally.max_hp, lucky_ally.current_qi, lucky_ally.max_qi)
			log_event.emit("Liu Bei restored 1 Qi to %s!" % lucky_ally.name)

func _perform_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	# Note: Target for this skill should be an ALLY. 
	# The current BattleController input logic might need a tweak to allow selecting allies for buffs.
	# For now, if target is enemy, we can't buff them.
	
	if target.player_id != player_id:
		log_event.emit("Skill Failed: Target must be an ally!")
		return false
		
	log_event.emit("Liu Bei commands: Fight for the people!")
	# Simple stat buff implementation (would ideally use a StatusEffect system)
	target.attack_power += 3
	log_event.emit("%s gained +3 Attack!" % target.name)
	return true

func _perform_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	log_event.emit("Liu Bei swears the Oath of the Peach Garden!")
	
	var board = get_parent().grid_manager
	var all_units = board.get_all_units()
	
	for u in all_units:
		if u.player_id == player_id:
			# Heal
			u.current_hp = min(u.current_hp + 15, u.max_hp)
			# Buff (Simple logic for now)
			u.attack_power = ceil(u.attack_power * 1.5)
			u.ui.update_status(u.current_hp, u.max_hp, u.current_qi, u.max_qi)
			
	log_event.emit("All allies healed and empowered!")
	return true
