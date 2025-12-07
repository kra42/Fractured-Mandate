extends Node2D

# Board Constants
const TILE_SIZE = 64
const COLS = 6
const ROWS = 5

# Game State
var grid: Dictionary = {} # Stores Unit nodes keyed by Vector2i(x,y)
var current_turn: String = "P1" # "P1" or "P2"
var selected_unit: Unit = null

# Highlights
var highlighted_moves: Array[Vector2i] = []
var highlighted_attacks: Array[Vector2i] = []

# Resources
var unit_scene = preload("res://Unit.tscn") # Assumes you have a Unit scene

func _ready():
	# --- Initialize Test Board ---
	# Player 1 (Left side)
	spawn_unit(0, 2, "P1", "WARRIOR")
	spawn_unit(1, 1, "P1", "ARCHER")
	spawn_unit(1, 3, "P1", "STRATEGIST")
	
	# Player 2 (Right side)
	spawn_unit(5, 2, "P2", "TANK")
	spawn_unit(4, 1, "P2", "SUPPORT")
	spawn_unit(4, 3, "P2", "WARRIOR")
	
	check_synergies()
	queue_redraw()

func spawn_unit(x: int, y: int, player_id: String, type: String):
	var unit = unit_scene.instantiate()
	unit.grid_pos = Vector2i(x, y)
	unit.player_id = player_id
	unit.unit_class = type
	
	# Set visual position
	unit.position = calculate_world_position(unit.grid_pos)
	
	# Basic Stats (Simplified)
	unit.max_hp = 10
	unit.current_hp = 10
	unit.current_qi = 1
	
	# Combat Stats (New)
	unit.attack_power = 4
	unit.heal_power = 3
	
	# Optional: Differentiate stats by class
	if type == "TANK":
		unit.max_hp = 15
		unit.current_hp = 15
		unit.attack_power = 2
	elif type == "STRATEGIST":
		unit.attack_power = 6 # Higher base, but AoE scales down
		
	add_child(unit)
	grid[Vector2i(x, y)] = unit

func calculate_world_position(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE) + Vector2(TILE_SIZE/2.0, TILE_SIZE/2.0)

# --- DRAWING ---
func _draw():
	# 1. Draw Grid Lines
	for x in range(COLS + 1):
		draw_line(Vector2(x * TILE_SIZE, 0), Vector2(x * TILE_SIZE, ROWS * TILE_SIZE), Color.GRAY)
	for y in range(ROWS + 1):
		draw_line(Vector2(0, y * TILE_SIZE), Vector2(COLS * TILE_SIZE, y * TILE_SIZE), Color.GRAY)

	# 2. Draw Highlights
	if selected_unit:
		# Selection Box
		draw_rect(Rect2(selected_unit.grid_pos * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE)), Color.GREEN, false, 3.0)
		
		# Valid Moves (Blue)
		for move in highlighted_moves:
			draw_rect(Rect2(move * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE)), Color(0, 0, 1, 0.3), true)
			
		# Valid Attacks/Targets (Red)
		for attack in highlighted_attacks:
			draw_rect(Rect2(attack * TILE_SIZE, Vector2(TILE_SIZE, TILE_SIZE)), Color(1, 0, 0, 0.3), true)

# --- INPUT HANDLING ---
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_cell = Vector2i(event.position) / TILE_SIZE
		
		# Bounds check
		if clicked_cell.x >= 0 and clicked_cell.x < COLS and clicked_cell.y >= 0 and clicked_cell.y < ROWS:
			handle_click(clicked_cell)

func handle_click(cell: Vector2i):
	# 1. Select Own Unit
	if grid.has(cell):
		var unit = grid[cell]
		# If clicking our own unit that hasn't acted yet
		if unit.player_id == current_turn and not unit.has_acted:
			selected_unit = unit
			# Calculate Options
			highlighted_moves = get_valid_formation_moves(unit)
			highlighted_attacks = TargetingSystem.get_valid_attacks(unit, grid, COLS)
			queue_redraw()
			return

		# 2. Clicking an Enemy (Attack)
		if selected_unit and unit.player_id != current_turn:
			if cell in highlighted_attacks:
				perform_attack(selected_unit, unit)
				return
		
		# 3. Clicking an Ally (Support/Buff)
		if selected_unit and unit.player_id == current_turn and unit != selected_unit:
			if selected_unit.unit_class == "SUPPORT" and cell in highlighted_attacks:
				perform_support(selected_unit, unit)
				return
		
		# 4. Clicking an Ally (Swap Position)
		if selected_unit and unit.player_id == current_turn and unit != selected_unit:
			if cell in highlighted_moves:
				perform_formation_move(selected_unit, cell)
				return

	# 5. Move to Empty Space
	elif selected_unit and not grid.has(cell):
		if cell in highlighted_moves:
			perform_formation_move(selected_unit, cell)

# --- MOVEMENT LOGIC ---
func get_valid_formation_moves(unit: Unit) -> Array[Vector2i]:
	if unit.current_qi <= 0: return []
	
	var moves: Array[Vector2i] = []
	# Simple adjacent movement (Cardinal directions)
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for d in directions:
		var target = unit.grid_pos + d
		if target.x >= 0 and target.x < COLS and target.y >= 0 and target.y < ROWS:
			moves.append(target)
			
	return moves

func perform_formation_move(unit: Unit, target_cell: Vector2i):
	unit.current_qi -= 1

	if grid.has(target_cell):
		# SWAP logic (Formation change)
		var other_unit = grid[target_cell]
		
		# Update Grid Dictionary
		grid[unit.grid_pos] = other_unit
		grid[target_cell] = unit
		
		# Update Internal Positions
		var temp_pos = unit.grid_pos
		unit.grid_pos = target_cell
		other_unit.grid_pos = temp_pos
		
		# Update Visuals
		unit.position = calculate_world_position(unit.grid_pos)
		other_unit.position = calculate_world_position(other_unit.grid_pos)
		
	else:
		# MOVE logic (Empty tile)
		grid.erase(unit.grid_pos)
		grid[target_cell] = unit
		unit.grid_pos = target_cell
		unit.position = calculate_world_position(unit.grid_pos)

	check_synergies()
	
	# Update highlights for new position
	highlighted_moves = get_valid_formation_moves(unit)
	highlighted_attacks = TargetingSystem.get_valid_attacks(unit, grid, COLS)
	queue_redraw()

# --- COMBAT LOGIC ---
func perform_attack(attacker: Unit, defender: Unit):
	var damage = attacker.attack_power
	
	if attacker.unit_class == "STRATEGIST":
		# Strategist hits EVERYONE in row for reduced damage (e.g., 50% of ATK)
		damage = ceil(attacker.attack_power * 0.5)
		
		var targets = TargetingSystem.get_all_enemies_in_row(defender.grid_pos.y, attacker.player_id, grid, COLS)
		for t_pos in targets:
			if grid.has(t_pos): grid[t_pos].take_damage(damage)
	
	elif attacker.unit_class == "ARCHER":
		# Archer: Check obstruction using TargetingSystem
		if TargetingSystem.is_shot_obstructed(attacker, defender, grid):
			damage = ceil(attacker.attack_power * 0.5) # 50% damage penalty
			print("Shot Obstructed! Reduced Damage.")
		else:
			print("Clean Shot!")
		defender.take_damage(damage)
		
	else:
		# Warrior/Tank/Standard Melee
		defender.take_damage(damage)
	
	finalize_action(attacker)

func perform_support(healer: Unit, target: Unit):
	# Use healer's heal_power stat
	target.current_hp = min(target.current_hp + healer.heal_power, target.max_hp)
	print("Healed unit at ", target.grid_pos)
	finalize_action(healer)

func finalize_action(unit: Unit):
	unit.has_acted = true
	unit.modulate = Color.GRAY
	
	selected_unit = null
	highlighted_moves = []
	highlighted_attacks = []
	queue_redraw()
	check_synergies()

# --- PASSIVES & SYNERGIES ---
func check_synergies():
	# First, reset colors of non-acted units
	for pos in grid:
		if not grid[pos].has_acted:
			grid[pos].modulate = Color.WHITE
			
	# Check horizontal adjacencies for "Formation Bonding"
	for pos in grid:
		var unit = grid[pos]
		# If there is a right-neighbor of the same team
		if grid.has(pos + Vector2i.RIGHT) and grid[pos + Vector2i.RIGHT].player_id == unit.player_id:
			# Visual feedback for synergy
			unit.modulate = Color(1.0, 0.84, 0.0) # Gold
			grid[pos + Vector2i.RIGHT].modulate = Color(1.0, 0.84, 0.0)

# --- TURN MANAGEMENT ---
func end_turn():
	current_turn = "P2" if current_turn == "P1" else "P1"
	print("Turn Changed: ", current_turn)
	
	# Reset Units for new turn
	for pos in grid:
		var unit = grid[pos]
		unit.has_acted = false
		unit.current_qi = 1 # Recharge Movement Resource
		unit.modulate = Color.WHITE
		
	selected_unit = null
	highlighted_moves = []
	highlighted_attacks = []
	check_synergies()
	queue_redraw()
