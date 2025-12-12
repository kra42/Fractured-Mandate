extends Unit

func _ready():
	unit_class = "ARCHER"
	max_hp = 6
	current_hp = 6
	max_qi = 0
	current_qi = 0
	attack_power = 3 
	initiative = 8
	resist = { "phys": 0, "fire": 0, "poison": 0 }
	super()

# FIX: Override targeting type so UI/System knows this unit targets the whole row
func get_skill_target_type(skill_mode: String) -> String:
	return TargetingSystem.TARGET_RANGED_ENEMY

func use_basic_attack(target: Unit) -> void:
	if not target:
		log_event.emit("Archer error: Target is null!")
		return

	var board = get_parent()
	var damage_to_deal = attack_power
	var is_covered = false
	
	# FIX: Retrieve grid correctly (BattleController has 'grid_manager', not 'grid')
	var current_grid = {}
	if board and "grid_manager" in board:
		current_grid = board.grid_manager.grid
	
	# FIX: Use local helper for cover check since TargetingSystem method is missing
	if not current_grid.is_empty():
		is_covered = _is_target_covered(self, target, current_grid)

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

# --- HELPER ---
# Local implementation of cover logic
func _is_target_covered(attacker: Unit, target: Unit, grid: Dictionary) -> bool:
	var start_x = attacker.grid_pos.x
	var end_x = target.grid_pos.x
	var row = attacker.grid_pos.y
	
	var min_x = min(start_x, end_x)
	var max_x = max(start_x, end_x)
	
	# Check every cell strictly between attacker and target
	for x in range(min_x + 1, max_x):
		if grid.has(Vector2i(x, row)):
			return true
			
	return false
