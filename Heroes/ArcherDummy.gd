extends Unit

func _ready():
	unit_class = "ARCHER"
	max_hp = 6
	current_hp = 6
	max_qi = 2
	current_qi = 0
	attack_power = 3 
	initiative = 8
	resist = { "phys": 0, "fire": 0, "poison": 0 }

func use_basic_attack(target: Unit) -> void:
	if not target:
		log_event.emit("Archer error: Target is null!")
		return

	var board = get_parent()
	var damage_to_deal = attack_power
	var is_covered = false
	
	# 1. Check for Cover using generic system
	if board and "grid" in board:
		is_covered = TargetingSystem.is_target_covered_in_row(self, target, board.grid)

	# 2. Apply Penalty if Covered
	if is_covered:
		damage_to_deal = ceil(attack_power * 0.5)
		log_event.emit("Archer fires OVER cover at %s! (50%% Dmg)" % target.name)
	else:
		log_event.emit("Archer fires a clear shot at %s!" % target.name)
		
	target.take_damage(damage_to_deal)

func use_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	return false

func use_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	return false

func ai_take_turn(grid: Dictionary, cols: int) -> void:
	# 1. Scan ONLY the current row
	var potential_targets = TargetingSystem.get_all_enemies_in_row(grid_pos.y, player_id, grid, cols)
	
	if potential_targets.size() > 0:
		# SMART AI: Target the lowest HP unit in the row
		var best_target = null
		var lowest_hp = 999
		
		for pos in potential_targets:
			var unit = grid[pos]
			if unit.current_hp < lowest_hp:
				lowest_hp = unit.current_hp
				best_target = unit
		
		if best_target:
			use_basic_attack(best_target)
	else:
		# STRICT RULE: If no one is in the row, do nothing.
		log_event.emit("Archer sees no targets in row and waits.")
