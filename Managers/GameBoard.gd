extends Node2D

const ROWS = 4
const COLS = 12

# State
var grid: Dictionary = {} # Key: Vector2i, Value: Unit Node
var current_turn: String = "P1"
var selected_unit: Unit = null
var highlighted_cells: Array[Vector2i] = [] # For drawing overlays

# Visuals (Drag your TileMapLayer here in Inspector)
@export var tile_map: TileMapLayer 

func _ready():
	# Wait one frame to ensure children are ready, then init
	call_deferred("initialize_board")

func initialize_board():
	# Snap all children units to the grid
	# IMPORTANT: You must have a Node2D named "Units" holding the characters
	var unit_container = get_node_or_null("Units")
	if not unit_container:
		print("Error: No 'Units' node found! Create a Node2D named 'Units' and put characters inside.")
		return

	for child in unit_container.get_children():
		if child is Unit:
			var cell = tile_map.local_to_map(child.position)
			child.grid_pos = cell
			grid[cell] = child
			# Center them visually
			child.position = tile_map.map_to_local(cell)

func _draw():
	# DEBUG: Draw highlights for valid moves (Cyan) or attacks (Red)
	for cell in highlighted_cells:
		var center = tile_map.map_to_local(cell)
		# Draw a semi-transparent square 
		# Size is hardcoded to 48x48 here, adjust to match your tile size!
		var rect = Rect2(center - Vector2(24, 24), Vector2(48, 48))
		var color = Color(0.0, 1.0, 1.0, 0.3) # Default Cyan (Move)
		
		# If it contains an enemy, make it Red (Attack)
		if grid.has(cell):
			if grid[cell].player_id != current_turn:
				color = Color(1.0, 0.2, 0.2, 0.3)
				
		draw_rect(rect, color, true)
		draw_rect(rect, color.lightened(0.5), false, 2.0) # Border

# --- MECHANIC 1: ZONE OF CONTROL (ZOC) ---
# Returns true if an enemy is Orthogonally adjacent
func is_engaged(unit: Unit) -> bool:
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for dir in directions:
		var neighbor_pos = unit.grid_pos + dir
		if grid.has(neighbor_pos):
			var neighbor = grid[neighbor_pos]
			if neighbor.player_id != unit.player_id:
				return true # Locked!
	return false

# --- MECHANIC 2: MOVEMENT (BFS) ---
func get_valid_moves(unit: Unit) -> Array[Vector2i]:
	if unit.has_moved: return []
	
	# ZOC LOCK: If adjacent to enemy at start of turn, CANNOT move.
	if is_engaged(unit):
		print("Unit Locked by ZOC")
		return []

	var valid: Array[Vector2i] = []
	# Queue stores Dictionary: { "pos": Vector2i, "dist": int }
	var queue = [{ "pos": unit.grid_pos, "dist": 0 }]
	var visited = { unit.grid_pos: true }
	
	while queue.size() > 0:
		var current = queue.pop_front()
		
		if current.dist > 0:
			valid.append(current.pos)
			
		if current.dist >= unit.move_range:
			continue
			
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var next = current.pos + dir
			
			# Boundary Check
			if next.x < 0 or next.x >= COLS or next.y < 0 or next.y >= ROWS:
				continue
			
			# Collision: Must be empty
			if grid.has(next):
				continue
				
			if not visited.has(next):
				visited[next] = true
				queue.append({ "pos": next, "dist": current.dist + 1 })
				
	return valid

# --- MECHANIC 3: ATTACK RANGES ---
func get_valid_attacks(unit: Unit) -> Array[Vector2i]:
	if unit.has_acted: return []
	var attacks: Array[Vector2i] = []
	
	if unit.unit_class == "WARRIOR":
		# Melee: Orthogonal only
		for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var target_pos = unit.grid_pos + dir
			if is_valid_target(target_pos, unit.player_id):
				attacks.append(target_pos)
				
	elif unit.unit_class == "ARCHER":
		# Arcing Shot: Entire Row, Ignores Blockers
		var r = unit.grid_pos.y
		for c in range(COLS):
			var target_pos = Vector2i(c, r)
			if is_valid_target(target_pos, unit.player_id):
				attacks.append(target_pos)
				
	return attacks

func is_valid_target(pos: Vector2i, attacker_id: String) -> bool:
	if grid.has(pos):
		var target = grid[pos]
		return target.player_id != attacker_id
	return false

# --- INPUT HANDLING ---
func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell = tile_map.local_to_map(get_global_mouse_position())
		handle_click(cell)

func handle_click(cell: Vector2i):
	# 1. Select Own Unit
	if grid.has(cell):
		var unit = grid[cell]
		if unit.player_id == current_turn:
			selected_unit = unit
			
			# UPDATE VISUALS: Combine Moves + Attacks for highlighting
			highlighted_cells = get_valid_moves(unit) + get_valid_attacks(unit)
			queue_redraw() # Trigger _draw()
			return

	# 2. Action (Move or Attack)
	if selected_unit:
		# Try Move
		var moves = get_valid_moves(selected_unit)
		if cell in moves:
			perform_move(selected_unit, cell)
			return
			
		# Try Attack
		var attacks = get_valid_attacks(selected_unit)
		if cell in attacks:
			perform_attack(selected_unit, grid[cell])
			return
	
	# Deselect if clicking empty space
	selected_unit = null
	highlighted_cells = []
	queue_redraw()

func perform_move(unit: Unit, cell: Vector2i):
	grid.erase(unit.grid_pos)
	unit.grid_pos = cell
	grid[cell] = unit
	
	# Visual Tween
	var tween = create_tween()
	tween.tween_property(unit, "position", tile_map.map_to_local(cell), 0.2)
	
	unit.has_moved = true
	
	# Clear highlights after move
	selected_unit = null
	highlighted_cells = []
	queue_redraw()

func perform_attack(attacker: Unit, defender: Unit):
	var damage = 4 # Flat damage for now
	defender.take_damage(damage)
	
	attacker.has_acted = true
	attacker.has_moved = true # Attacking ends turn
	attacker.modulate = Color(0.5, 0.5, 0.5) # Grey out
	
	selected_unit = null
	highlighted_cells = []
	queue_redraw()
	
	# Check death
	if defender.current_hp <= 0:
		grid.erase(defender.grid_pos)

# --- TURN MANAGEMENT ---
func end_turn():
	# Switch Player
	if current_turn == "P1":
		current_turn = "P2"
	else:
		current_turn = "P1"
	
	print("Turn Ended. New Turn: " + current_turn)
	
	# Reset flags for new active player
	for unit in grid.values():
		if unit.player_id == current_turn:
			unit.start_turn()
			
	# Deselect
	selected_unit = null
	highlighted_cells = []
	queue_redraw()
