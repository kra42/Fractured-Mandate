class_name TargetingSystem
extends RefCounted

# Static helper to determine valid attack targets based on Unit Class
static func get_valid_attacks(unit: Unit, grid: Dictionary, cols: int) -> Array[Vector2i]:
	if not is_instance_valid(unit) or unit.has_acted: return []
	var attacks: Array[Vector2i] = []
	var row = unit.grid_pos.y
	
	# WARRIOR / TANK: Only Hits the FRONT line (First Enemy)
	if unit.unit_class == "WARRIOR" or unit.unit_class == "TANK":
		var target = get_enemy_in_row(row, unit.player_id, "FIRST", grid, cols)
		if target != Vector2i(-1, -1):
			attacks.append(target)
	
	# ARCHER: Can target ANY enemy in the row
	elif unit.unit_class == "ARCHER":
		attacks.append_array(get_all_enemies_in_row(row, unit.player_id, grid, cols))

	# STRATEGIST: Hits EVERYONE in the lane (Pierce)
	elif unit.unit_class == "STRATEGIST":
		attacks.append_array(get_all_enemies_in_row(row, unit.player_id, grid, cols))
		
	# SUPPORT: Flexible Range 1 (Can hit Enemies OR Buff Allies)
	elif unit.unit_class == "SUPPORT":
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var target_pos = unit.grid_pos + dir
			if grid.has(target_pos):
				var target_unit = grid[target_pos]
				if is_instance_valid(target_unit):
					# Supports can interact with ANYONE adjacent (Attack foe / Buff friend)
					attacks.append(target_pos)
					
	return attacks

static func get_enemy_in_row(row: int, attacker_id: String, mode: String, grid: Dictionary, cols: int) -> Vector2i:
	var potential_targets = []
	var range_iter = range(cols) if attacker_id == "PLAYER" or attacker_id == "P1" else range(cols - 1, -1, -1)
	
	for c in range_iter:
		var cell = Vector2i(c, row)
		if grid.has(cell):
			var unit = grid[cell]
			if is_instance_valid(unit) and unit.player_id != attacker_id:
				potential_targets.append(cell)
	
	if potential_targets.is_empty(): return Vector2i(-1, -1)
	if mode == "FIRST": return potential_targets[0]
	if mode == "LAST": return potential_targets[-1]
	return Vector2i(-1, -1)

static func get_all_enemies_in_row(row: int, attacker_id: String, grid: Dictionary, cols: int) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for c in range(cols):
		var cell = Vector2i(c, row)
		if grid.has(cell):
			var unit = grid[cell]
			if is_instance_valid(unit) and unit.player_id != attacker_id:
				targets.append(cell)
	return targets

static func is_shot_obstructed(attacker: Unit, target: Unit, grid: Dictionary) -> bool:
	var row = attacker.grid_pos.y
	if attacker.grid_pos.y != target.grid_pos.y: return false 
	
	var start = min(attacker.grid_pos.x, target.grid_pos.x)
	var end = max(attacker.grid_pos.x, target.grid_pos.x)
	
	for x in range(start + 1, end):
		var check_pos = Vector2i(x, row)
		if grid.has(check_pos):
			var obstacle = grid[check_pos]
			if is_instance_valid(obstacle) and obstacle.player_id != attacker.player_id:
				return true
	return false

# --- ADJACENCY HELPERS ---

static func get_adjacent_enemies(center_pos: Vector2i, attacker_id: String, grid: Dictionary) -> Array[Unit]:
	var enemies: Array[Unit] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for d in directions:
		var check_pos = center_pos + d
		if grid.has(check_pos):
			var unit = grid[check_pos]
			if is_instance_valid(unit) and unit.player_id != attacker_id and unit.current_hp > 0:
				enemies.append(unit)
				
	return enemies

# NEW: For Auras and Buffs (Liu Bei Passive)
static func get_adjacent_allies(center_pos: Vector2i, my_team_id: String, grid: Dictionary) -> Array[Unit]:
	var allies: Array[Unit] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for d in directions:
		var check_pos = center_pos + d
		if grid.has(check_pos):
			var unit = grid[check_pos]
			# Check same team, exclude dead
			if is_instance_valid(unit) and unit.player_id == my_team_id and unit.current_hp > 0:
				allies.append(unit)
				
	return allies

# --- COVER CALCULATION ---
# Returns TRUE if there is another enemy closer to the attacker in the same row
static func is_target_covered_in_row(attacker: Unit, target: Unit, grid: Dictionary) -> bool:
	if attacker.grid_pos.y != target.grid_pos.y:
		return false
	
	var enemies_in_row: Array[Unit] = []
	for pos in grid:
		var unit = grid[pos]
		if is_instance_valid(unit) and unit.grid_pos.y == attacker.grid_pos.y and unit.player_id != attacker.player_id:
			enemies_in_row.append(unit)
	
	if enemies_in_row.is_empty():
		return false
		
	enemies_in_row.sort_custom(func(a, b):
		var dist_a = abs(a.grid_pos.x - attacker.grid_pos.x)
		var dist_b = abs(b.grid_pos.x - attacker.grid_pos.x)
		return dist_a < dist_b
	)
	
	return enemies_in_row[0] != target
