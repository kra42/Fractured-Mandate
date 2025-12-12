class_name TargetingSystem
extends RefCounted

const TARGET_SELF = "SELF"
const TARGET_FRONT_ENEMY = "FRONT_ENEMY"
const TARGET_RANGED_ENEMY = "RANGED_ENEMY"
const TARGET_SELF_ADJACENT_ALLIES = "SELF_ADJACENT_ALLIES" # Uses include_self=true
const TARGET_ADJACENT_ALLIES = "ADJACENT_ALLIES"         # Uses include_self=false
const TARGET_GLOBAL_ALLIES = "GLOBAL_ALLIES"
const TARGET_GLOBAL_ENEMIES = "GLOBAL_ENEMIES"

static func get_valid_targets(unit: Unit, type: String, grid: Dictionary, cols: int) -> Array[Vector2i]:
	if not is_instance_valid(unit) or unit.has_acted: return []
	
	var targets: Array[Vector2i] = []
	
	match type:
		TARGET_SELF:
			targets.append(unit.grid_pos)
			
		TARGET_FRONT_ENEMY:
			var target = get_enemy_in_row(unit.grid_pos.y, unit.player_id, "FIRST", grid, cols)
			if target != Vector2i(-1, -1):
				targets.append(target)
				
		TARGET_RANGED_ENEMY:
			targets.append_array(get_all_enemies_in_row(unit.grid_pos.y, unit.player_id, grid, cols))
			
		TARGET_SELF_ADJACENT_ALLIES:
			# Use the new flag: include_self = true
			targets.append_array(get_adjacent_allies(unit.grid_pos, unit.player_id, grid, true))
			
		TARGET_ADJACENT_ALLIES:
			# New Type: include_self = false
			targets.append_array(get_adjacent_allies(unit.grid_pos, unit.player_id, grid, false))
			
		TARGET_GLOBAL_ALLIES:
			targets.append_array(get_all_allies(unit.player_id, grid))
			
		TARGET_GLOBAL_ENEMIES:
			targets.append_array(get_all_enemies_on_board(unit.player_id, grid))
			
	return targets

# --- LOW LEVEL HELPERS ---

# ... [Keep existing get_enemy_in_row, get_all_enemies_in_row, get_all_allies, get_all_enemies_on_board] ...
# (You can copy them from your previous file content to ensure they stay)

static func get_enemy_in_row(row: int, attacker_id: String, mode: String, grid: Dictionary, cols: int) -> Vector2i:
	var range_iter = range(cols) if attacker_id == "PLAYER" or attacker_id == "P1" else range(cols - 1, -1, -1)
	for c in range_iter:
		var cell = Vector2i(c, row)
		if grid.has(cell):
			var unit = grid[cell]
			if is_instance_valid(unit) and unit.player_id != attacker_id:
				if mode == "FIRST": return cell
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

static func get_all_allies(my_team_id: String, grid: Dictionary) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for pos in grid:
		var unit = grid[pos]
		if is_instance_valid(unit) and unit.player_id == my_team_id and unit.current_hp > 0:
			targets.append(pos)
	return targets

static func get_all_enemies_on_board(attacker_id: String, grid: Dictionary) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	for pos in grid:
		var unit = grid[pos]
		if is_instance_valid(unit) and unit.player_id != attacker_id and unit.current_hp > 0:
			targets.append(pos)
	return targets

# --- UPDATED ADJACENCY HELPERS ---

# Now accepts include_self (default false)
static func get_adjacent_allies(center_pos: Vector2i, my_team_id: String, grid: Dictionary, include_self: bool = false) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	if include_self:
		if grid.has(center_pos):
			var u = grid[center_pos]
			if is_instance_valid(u) and u.player_id == my_team_id and u.current_hp > 0:
				targets.append(center_pos)

	for d in directions:
		var check_pos = center_pos + d
		if grid.has(check_pos):
			var unit = grid[check_pos]
			if is_instance_valid(unit) and unit.player_id == my_team_id and unit.current_hp > 0:
				targets.append(check_pos)
	return targets

# Added for Zhao Yun Logic (and symmetry)
static func get_adjacent_enemies(center_pos: Vector2i, my_team_id: String, grid: Dictionary, include_self: bool = false) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	if include_self:
		if grid.has(center_pos):
			var u = grid[center_pos]
			if is_instance_valid(u) and u.player_id != my_team_id and u.current_hp > 0:
				targets.append(center_pos)

	for d in directions:
		var check_pos = center_pos + d
		if grid.has(check_pos):
			var unit = grid[check_pos]
			if is_instance_valid(unit) and unit.player_id != my_team_id and unit.current_hp > 0:
				targets.append(check_pos)
	return targets
