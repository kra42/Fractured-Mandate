class_name TargetingSystem
extends RefCounted

# Static helper to determine valid attack targets based on Unit Class
static func get_valid_attacks(unit: Unit, grid: Dictionary, cols: int) -> Array[Vector2i]:
	if unit.has_acted: return []
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
		
	# SUPPORT: Range 1 in any direction (Omni-Heal/Buff)
	elif unit.unit_class == "SUPPORT":
		var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
		for dir in directions:
			var target_pos = unit.grid_pos + dir
			if grid.has(target_pos) and grid[target_pos].player_id == unit.player_id:
				attacks.append(target_pos)
					
	return attacks

static func get_enemy_in_row(row: int, attacker_id: String, mode: String, grid: Dictionary, cols: int) -> Vector2i:
	var potential_targets = []
	# Scan direction depends on player
	var range_iter = range(cols) if attacker_id == "P1" else range(cols - 1, -1, -1)
	
	for c in range_iter:
		var cell = Vector2i(c, row)
		if grid.has(cell) and grid[cell].player_id != attacker_id:
			potential_targets.append(cell)
	
	if potential_targets.is_empty(): return Vector2i(-1, -1)
	if mode == "FIRST": return potential_targets[0]
	if mode == "LAST": return potential_targets[-1]
	return Vector2i(-1, -1)

static func get_all_enemies_in_row(row: int, attacker_id: String, grid: Dictionary, cols: int) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for c in range(cols):
		var cell = Vector2i(c, row)
		if grid.has(cell) and grid[cell].player_id != attacker_id:
			targets.append(cell)
	return targets

# Returns TRUE if there is an enemy between attacker and target
static func is_shot_obstructed(attacker: Unit, target: Unit, grid: Dictionary) -> bool:
	var row = attacker.grid_pos.y
	if attacker.grid_pos.y != target.grid_pos.y: return false # Should match row
	
	var start = min(attacker.grid_pos.x, target.grid_pos.x)
	var end = max(attacker.grid_pos.x, target.grid_pos.x)
	
	# Check tiles strictly between start and end
	for x in range(start + 1, end):
		var check_pos = Vector2i(x, row)
		if grid.has(check_pos):
			var obstacle = grid[check_pos]
			if obstacle.player_id != attacker.player_id:
				return true
	return false

# --- NEW ADJACENCY LOGIC (Required for Zhao Yun Ult) ---
# Returns a list of UNIT objects (not just positions) that are enemies adjacent to the center_pos
static func get_adjacent_enemies(center_pos: Vector2i, attacker_id: String, grid: Dictionary) -> Array[Unit]:
	var enemies: Array[Unit] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for d in directions:
		var check_pos = center_pos + d
		if grid.has(check_pos):
			var unit = grid[check_pos]
			# Must be enemy and alive
			if unit.player_id != attacker_id and unit.current_hp > 0:
				enemies.append(unit)
				
	return enemies
