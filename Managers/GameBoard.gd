extends Node2D

# --- CONFIGURATION CONSTANTS ---
const COLS = 12 
const ROWS = 4
const ZONE_ROWS = 4
const ZONE_COLS = 3

# Reference size for scaling
const BASE_TILE_SIZE = 128.0

# --- THEMATIC COLORS (Ink Wash Style) ---
# We keep this as a fallback tint
const COLOR_PAPER = Color("f4f1ea") 
const COLOR_INK = Color(0.15, 0.15, 0.15, 0.8) 
const COLOR_WASH_BLUE = Color(0.2, 0.3, 0.6, 0.15)
const COLOR_WASH_RED = Color(0.7, 0.2, 0.2, 0.15)
const COLOR_WASH_GREEN = Color(0.3, 0.6, 0.3, 0.3)

# --- DYNAMIC DISPLAY VARIABLES ---
var tile_size: float = BASE_TILE_SIZE 
var board_offset: Vector2 = Vector2.ZERO

# --- RESOURCES ---
# Add a slot for a real texture in the Inspector
@export var background_texture: Texture2D 
var unit_scene = preload("res://Unit.tscn") 

# --- HERO DATABASE ---
const HERO_DB = {
	"ZHAO_YUN": {
		"script": "res://Heroes/Zhao_Yun.gd", 
		"base_stats": {} 
	},
	"SOLDIER_DUMMY": {
		"script": "res://Heroes/DummySoldier.gd",
		"base_stats": {}
	},
	"ARCHER_GENERIC": {
		"script": "", 
		"base_stats": {"hp": 8, "atk": 4, "class": "ARCHER"}
	}
}

var grid: Dictionary = {} 
var current_turn: String = "P1" 
var selected_unit: Unit = null

var highlighted_moves: Array[Vector2i] = []
var highlighted_attacks: Array[Vector2i] = []

func _ready():
	# 1. Connect signal
	get_tree().root.size_changed.connect(_on_viewport_resize)
	
	# 2. Wait one frame before calculating layout! 
	call_deferred("_initial_setup")

func _initial_setup():
	# Calculate layout first
	_on_viewport_resize()
	
	# THEN spawn units
	spawn_unit(1, 2, "P1", "ZHAO_YUN")
	
	# Player 2 Army
	spawn_unit(9, 1, "P2", "SOLDIER_DUMMY")
	spawn_unit(9, 2, "P2", "SOLDIER_DUMMY")
	spawn_unit(9, 3, "P2", "SOLDIER_DUMMY")
	spawn_unit(10, 1, "P2", "SOLDIER_DUMMY")
	spawn_unit(10, 2, "P2", "SOLDIER_DUMMY")
	spawn_unit(10, 3, "P2", "SOLDIER_DUMMY")
	
	check_synergies()
	queue_redraw()

# --- RESPONSIVE LOGIC ---
func _on_viewport_resize():
	var screen_size = get_viewport_rect().size
	
	# MARGINS: Reserved space for UI
	var margin_x = screen_size.x * 0.05
	var margin_top = screen_size.y * 0.05
	var margin_bottom = screen_size.y * 0.20 
	
	var available_w = screen_size.x - (margin_x * 2)
	var available_h = screen_size.y - (margin_top + margin_bottom)
	
	# Calculate max possible tile size
	var possible_tile_w = available_w / COLS
	var possible_tile_h = available_h / ROWS
	
	# Pick the smaller one
	tile_size = min(possible_tile_w, possible_tile_h)
	
	# Recalculate Offset to Center the Board
	var total_board_w = tile_size * COLS
	var total_board_h = tile_size * ROWS
	
	board_offset = Vector2(
		(screen_size.x - total_board_w) / 2.0,
		margin_top + ((available_h - total_board_h) / 2.0)
	)
	
	# Update positions/scale of existing units
	for unit in grid.values():
		unit.position = calculate_world_position(unit.grid_pos)
		var scale_factor = tile_size / BASE_TILE_SIZE
		unit.scale = Vector2(scale_factor, scale_factor)
		
	queue_redraw()

func spawn_unit(x: int, y: int, player_id: String, hero_id: String):
	if not HERO_DB.has(hero_id):
		push_error("Hero ID not found: " + hero_id)
		return

	var data = HERO_DB[hero_id]
	var unit_instance = unit_scene.instantiate()
	
	if data.has("script") and data["script"] != "":
		var hero_script = load(data["script"])
		if hero_script:
			unit_instance.set_script(hero_script)
	
	add_child(unit_instance)
	
	unit_instance.grid_pos = Vector2i(x, y)
	unit_instance.player_id = player_id
	unit_instance.position = calculate_world_position(Vector2i(x,y))
	
	# Scale unit
	var scale_factor = tile_size / BASE_TILE_SIZE
	unit_instance.scale = Vector2(scale_factor, scale_factor)
	
	unit_instance.z_index = y 
	unit_instance.set_meta("hero_id", hero_id)
	
	if data.has("base_stats") and not data["base_stats"].is_empty():
		var stats = data["base_stats"]
		if stats.has("hp"): unit_instance.max_hp = stats["hp"]
		if stats.has("hp"): unit_instance.current_hp = stats["hp"]
		if stats.has("atk"): unit_instance.attack_power = stats["atk"]
		if stats.has("class"): unit_instance.unit_class = stats["class"]
	
	grid[Vector2i(x, y)] = unit_instance

func calculate_world_position(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size) + Vector2(tile_size/2.0, tile_size/2.0) + board_offset

func _draw():
	var viewport_rect = get_viewport_rect()
	
	# 0. Draw "Paper" Background
	if background_texture:
		# Draw the texture tiled/stretched to cover the screen
		draw_texture_rect(background_texture, viewport_rect, false)
	else:
		# Fallback to the solid color
		draw_rect(viewport_rect, COLOR_PAPER)
		# Draw random "noise" dots to simulate paper grain if no texture
		draw_paper_grain(viewport_rect)
	
	# 1. Draw Team Zones (Ink Washes)
	var p1_zone = Rect2(board_offset.x, board_offset.y, ZONE_COLS * tile_size, ZONE_ROWS * tile_size)
	draw_rect(p1_zone, COLOR_WASH_BLUE)

	var p2_start_x = (COLS - ZONE_COLS) * tile_size + board_offset.x
	var p2_zone = Rect2(p2_start_x, board_offset.y, ZONE_COLS * tile_size, ZONE_ROWS * tile_size)
	draw_rect(p2_zone, COLOR_WASH_RED)

	# 2. Draw Grid Lines (Ink Strokes)
	for x in range(COLS + 1):
		var start = Vector2(x * tile_size, 0) + board_offset
		var end = Vector2(x * tile_size, ROWS * tile_size) + board_offset
		draw_line(start, end, COLOR_INK, 2.0)
		
	for y in range(ROWS + 1):
		var start = Vector2(0, y * tile_size) + board_offset
		var end = Vector2(COLS * tile_size, y * tile_size) + board_offset
		draw_line(start, end, COLOR_INK, 2.0)

	# 3. Draw Highlights
	if selected_unit:
		var rect_pos = (selected_unit.grid_pos * tile_size) + board_offset
		draw_rect(Rect2(rect_pos, Vector2(tile_size, tile_size)), COLOR_WASH_GREEN)
		draw_rect(Rect2(rect_pos, Vector2(tile_size, tile_size)), COLOR_INK, false, 4.0)
		
		for move in highlighted_moves:
			var move_pos = (move * tile_size) + board_offset
			draw_rect(Rect2(move_pos, Vector2(tile_size, tile_size)), COLOR_WASH_BLUE)
			
		for attack in highlighted_attacks:
			var attack_pos = (attack * tile_size) + board_offset
			draw_rect(Rect2(attack_pos, Vector2(tile_size, tile_size)), COLOR_WASH_RED)

# Helper to draw fake paper grain if no texture is loaded
func draw_paper_grain(rect: Rect2):
	var rng = RandomNumberGenerator.new()
	rng.seed = 1234 # Static seed so it doesn't flicker
	
	# Draw 500 random faint dots
	for i in range(500):
		var x = rng.randf_range(rect.position.x, rect.end.x)
		var y = rng.randf_range(rect.position.y, rect.end.y)
		var opacity = rng.randf_range(0.05, 0.1)
		draw_circle(Vector2(x, y), 1.0, Color(0,0,0, opacity))

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var local_pos = event.position - board_offset
		var clicked_cell = Vector2i(local_pos / tile_size)
		
		if clicked_cell.x >= 0 and clicked_cell.x < COLS and clicked_cell.y >= 0 and clicked_cell.y < ROWS:
			handle_click(clicked_cell)

func handle_click(cell: Vector2i):
	if grid.has(cell):
		var unit = grid[cell]
		if unit.player_id == current_turn and not unit.has_acted:
			selected_unit = unit
			highlighted_moves = get_valid_formation_moves(unit)
			highlighted_attacks = TargetingSystem.get_valid_attacks(unit, grid, COLS)
			queue_redraw()
			return

		if selected_unit and unit.player_id != current_turn:
			if cell in highlighted_attacks:
				perform_action("BASIC", selected_unit, unit)
				return
		
		if selected_unit and unit.player_id == current_turn and unit != selected_unit:
			if selected_unit.unit_class == "SUPPORT" and cell in highlighted_attacks:
				perform_support(selected_unit, unit)
				return
		
		if selected_unit and unit.player_id == current_turn and unit != selected_unit:
			if cell in highlighted_moves:
				perform_formation_move(selected_unit, cell)
				return

	elif selected_unit and not grid.has(cell):
		if cell in highlighted_moves:
			perform_formation_move(selected_unit, cell)

func get_valid_formation_moves(unit: Unit) -> Array[Vector2i]:
	if unit.current_qi <= 0: return []
	
	var moves: Array[Vector2i] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	
	for d in directions:
		var target = unit.grid_pos + d
		if target.x >= 0 and target.x < COLS and target.y >= 0 and target.y < ROWS:
			moves.append(target)
			
	return moves

func perform_formation_move(unit: Unit, target_cell: Vector2i):
	unit.current_qi -= 1

	if grid.has(target_cell):
		var other_unit = grid[target_cell]
		
		grid[unit.grid_pos] = other_unit
		grid[target_cell] = unit
		
		var temp_pos = unit.grid_pos
		unit.grid_pos = target_cell
		other_unit.grid_pos = temp_pos
		
		unit.position = calculate_world_position(unit.grid_pos)
		other_unit.position = calculate_world_position(other_unit.grid_pos)
		
		unit.z_index = unit.grid_pos.y
		other_unit.z_index = other_unit.grid_pos.y
		
	else:
		grid.erase(unit.grid_pos)
		grid[target_cell] = unit
		unit.grid_pos = target_cell
		unit.position = calculate_world_position(unit.grid_pos)
		
		unit.z_index = unit.grid_pos.y

	check_synergies()
	
	highlighted_moves = get_valid_formation_moves(unit)
	highlighted_attacks = TargetingSystem.get_valid_attacks(unit, grid, COLS)
	queue_redraw()

func perform_action(action_type: String, attacker: Unit, defender: Unit):
	if action_type == "BASIC":
		attacker.use_basic_attack(defender)
	elif action_type == "ADVANCED":
		attacker.use_advanced_skill(defender, grid, COLS)
	elif action_type == "ULTIMATE":
		attacker.use_ultimate_skill(defender, grid, COLS)
	
	finalize_action(attacker)

func perform_support(healer: Unit, target: Unit):
	target.current_hp = min(target.current_hp + 3, target.max_hp)
	finalize_action(healer)

func finalize_action(unit: Unit):
	unit.has_acted = true
	unit.modulate = Color.GRAY
	
	selected_unit = null
	highlighted_moves = []
	highlighted_attacks = []
	queue_redraw()
	check_synergies()

func check_synergies():
	pass

func end_turn():
	current_turn = "P2" if current_turn == "P1" else "P1"
	print("Turn Changed: ", current_turn)
	
	for pos in grid:
		var unit = grid[pos]
		unit.has_acted = false
		unit.current_qi = 1
		unit.modulate = Color.WHITE
		if unit.has_method("on_turn_start"):
			unit.on_turn_start()
		
	selected_unit = null
	highlighted_moves = []
	highlighted_attacks = []
	check_synergies()
	queue_redraw()
