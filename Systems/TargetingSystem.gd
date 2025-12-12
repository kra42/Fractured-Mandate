class_name TargetingSystem
extends RefCounted

# Enum for clarity (though string passing is often easier in Godot signals/data)
const TARGET_SELF = "SELF"
const TARGET_FRONT_ENEMY = "FRONT_ENEMY"
const TARGET_RANGED_ENEMY = "RANGED_ENEMY"
const TARGET_SELF_ADJACENT_ALLIES = "SELF_ADJACENT_ALLIES"
const TARGET_GLOBAL_ALLIES = "GLOBAL_ALLIES"
const TARGET_GLOBAL_ENEMIES = "GLOBAL_ENEMIES"

# Main entry point for getting valid target cells based on a targeting rule
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
			# Add self
			targets.append(unit.grid_pos)
			# Add adjacent allies
			targets.append_array(get_adjacent_allies(unit.grid_pos, unit.player_id, grid))
			
		TARGET_GLOBAL_ALLIES:
			targets.append_array(get_all_allies(unit.player_id, grid))
			
		TARGET_GLOBAL_ENEMIES:
			targets.append_array(get_all_enemies_on_board(unit.player_id, grid))
			
	return targets

# --- LOW LEVEL HELPERS ---

static func get_enemy_in_row(row: int, attacker_id: String, mode: String, grid: Dictionary, cols: int) -> Vector2i:
	var potential_targets = []
	# Determine direction based on player ID if needed, but usually row scan is 0->Cols
	# Assuming standard left-to-right scan for P1, right-to-left for Enemy
	var range_iter = range(cols) if attacker_id == "PLAYER" or attacker_id == "P1" else range(cols - 1, -1, -1)
	
	for c in range_iter:
		var cell = Vector2i(c, row)
		if grid.has(cell):
			var unit = grid[cell]
			if is_instance_valid(unit) and unit.player_id != attacker_id:
				potential_targets.append(cell)
				if mode == "FIRST": break # Optimization: Stop after first if we only need first
	
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

static func get_adjacent_allies(center_pos: Vector2i, my_team_id: String, grid: Dictionary) -> Array[Vector2i]:
	var targets: Array[Vector2i] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for d in directions:
		var check_pos = center_pos + d
		if grid.has(check_pos):
			var unit = grid[check_pos]
			if is_instance_valid(unit) and unit.player_id == my_team_id and unit.current_hp > 0:
				targets.append(check_pos)
	return targets
