extends Node2D

const COLS = 12 
const ROWS = 4
const ZONE_ROWS = 4
const ZONE_COLS = 3
const BASE_TILE_SIZE = 128.0

# --- STATES ---
enum BattleState { DEPLOYMENT, BATTLE_START, PLAYER_TURN, ENEMY_TURN, END }
var current_state = BattleState.DEPLOYMENT

@export var background_texture: Texture2D 
var unit_scene = preload("res://Unit.tscn") 

# Battle Data
var player_roster_data = ["LIU_BEI", "ZHAO_YUN"] # Defined Roster Array
var deployed_units: Array = []
var max_deployment_slots = 4

# Selection / Dragging
var selected_unit: Unit = null
var active_skill_mode: String = "BASIC"
var highlighted_moves: Array[Vector2i] = []
var highlighted_attacks: Array[Vector2i] = []

# Deployment Selection
var selected_hero_id_for_deployment: String = ""

# --- SUB-MANAGERS ---
var battle_ui: BattleUI 
var ai_manager: AIManager
var turn_manager: TurnManager
var grid_manager: GridManager
var board_renderer: BoardRenderer

func _ready():
	get_tree().root.size_changed.connect(_on_viewport_resize)
	
	grid_manager = GridManager.new()
	add_child(grid_manager)
	
	board_renderer = BoardRenderer.new()
	board_renderer.background_texture = background_texture 
	board_renderer.setup(COLS, ROWS, ZONE_COLS, ZONE_ROWS)
	add_child(board_renderer) 
	
	battle_ui = BattleUI.new()
	add_child(battle_ui)
	battle_ui.action_mode_changed.connect(_on_ui_action_mode_changed)
	battle_ui.end_turn_pressed.connect(func(): turn_manager.end_current_turn())
	
	# Connect UI Signals
	if battle_ui.has_signal("start_battle_pressed"):
		battle_ui.start_battle_pressed.connect(_on_start_battle_pressed)
	if battle_ui.has_signal("deployment_hero_selected"):
		battle_ui.deployment_hero_selected.connect(_on_deployment_hero_selected)
	
	ai_manager = AIManager.new()
	add_child(ai_manager)
	ai_manager.turn_finished.connect(func(): turn_manager.end_current_turn()) 
	ai_manager.request_redraw.connect(_refresh_visuals) 
	ai_manager.log_message.connect(_on_unit_log_event)
	
	turn_manager = TurnManager.new()
	add_child(turn_manager)
	turn_manager.turn_changed.connect(_on_active_unit_changed)
	turn_manager.ai_turn_requested.connect(_on_ai_turn_requested)
	turn_manager.round_started.connect(_on_round_started)
	
	call_deferred("_setup_deployment_phase")

func _setup_deployment_phase():
	_on_viewport_resize()
	
	# 1. Spawn Enemies (Fixed positions for now)
	_spawn_unit_on_grid(9, 1, TurnManager.TEAM_ENEMY, "SOLDIER_DUMMY", 1)
	_spawn_unit_on_grid(9, 2, TurnManager.TEAM_ENEMY, "SOLDIER_DUMMY", 2)
	_spawn_unit_on_grid(10, 1, TurnManager.TEAM_ENEMY, "ARCHER_DUMMY", 1)
	
	max_deployment_slots = player_roster_data.size()
	
	# 2. Populate Player Bench (UI)
	battle_ui.setup_deployment_bench(player_roster_data)
	
	current_state = BattleState.DEPLOYMENT
	battle_ui.log_message("--- DEPLOYMENT PHASE ---")
	battle_ui.log_message("Select a hero from the bottom, then click a blue tile to place.")
	_refresh_visuals()

# Called when player clicks "Start Battle"
func _on_start_battle_pressed():
	if deployed_units.size() < max_deployment_slots:
		battle_ui.log_message("You must deploy all available heroes (%d/%d)!" % [deployed_units.size(), max_deployment_slots])
		return
		
	current_state = BattleState.BATTLE_START
	battle_ui.hide_deployment_ui() # Hide the bench
	
	battle_ui.log_message("--- BATTLE START ---")
	
	# Synergy Check
	check_synergies()
	
	# Start Turn Manager
	turn_manager.start_game(grid_manager.get_all_units())

func _on_deployment_hero_selected(hero_id: String):
	selected_hero_id_for_deployment = hero_id

# --- DEPLOYMENT LOGIC ---

# Attempt to place a unit from the bench onto the grid
func try_deploy_unit(hero_id: String, target_cell: Vector2i) -> bool:
	if current_state != BattleState.DEPLOYMENT: return false
	
	# Check if cell is valid player zone (Cols 0-2)
	if target_cell.x < 0 or target_cell.x >= ZONE_COLS:
		battle_ui.log_message("Invalid Deployment Zone!")
		return false
		
	if target_cell.y < 0 or target_cell.y >= ROWS: return false
	
	# Check occupancy
	if grid_manager.is_occupied(target_cell):
		battle_ui.log_message("Cell occupied!")
		return false
		
	# Check if this hero is already deployed (Unique heroes)
	for u in deployed_units:
		if u.get_meta("hero_id") == hero_id:
			battle_ui.log_message("Hero already deployed! Move them instead.")
			return false

	# Spawn the actual unit on the grid
	var unit = _spawn_unit_on_grid(target_cell.x, target_cell.y, TurnManager.TEAM_PLAYER, hero_id)
	if unit:
		deployed_units.append(unit)
		battle_ui.update_deployment_status(deployed_units.size(), max_deployment_slots)
		return true
		
	return false

# Removing a unit (right click or drag back to bench?)
func undeploy_unit(unit: Unit):
	if current_state != BattleState.DEPLOYMENT: return
	
	grid_manager.remove_unit(unit)
	deployed_units.erase(unit)
	unit.queue_free()
	battle_ui.update_deployment_status(deployed_units.size(), max_deployment_slots)

# --- SPAWNING ---

func _spawn_unit_on_grid(x: int, y: int, team: String, hero_id: String, index: int = 1) -> Unit:
	var pos = Vector2i(x, y)
	var unit = UnitFactory.create_unit(hero_id, team, pos, unit_scene)
	if not unit: return null
	
	if team == TurnManager.TEAM_ENEMY:
		unit.name = "%s %d" % [unit.name, index]
	
	add_child(unit)
	grid_manager.add_unit(unit)
	
	unit.position = grid_manager.grid_to_world(pos)
	unit.log_event.connect(_on_unit_log_event)
	unit.tree_exiting.connect(func(): _on_unit_died(unit))
	_scale_unit_sprite(unit)
	return unit

func _on_unit_died(unit: Unit):
	if grid_manager:
		grid_manager.remove_unit(unit)
	_refresh_visuals()
	_check_game_over_condition()

func _check_game_over_condition():
	if current_state == BattleState.DEPLOYMENT: return # Don't lose during setup
	
	var all_units = grid_manager.get_all_units()
	var player_alive = false
	var enemy_alive = false
	
	for u in all_units:
		if is_instance_valid(u) and u.current_hp > 0:
			if u.player_id == TurnManager.TEAM_PLAYER:
				player_alive = true
			elif u.player_id == TurnManager.TEAM_ENEMY:
				enemy_alive = true
	
	if not player_alive:
		battle_ui.log_message("--- DEFEAT ---")
		set_process_unhandled_input(false)
	elif not enemy_alive:
		battle_ui.log_message("--- VICTORY ---")
		set_process_unhandled_input(false)

# --- SYNERGY CHECK ---
func check_synergies():
	# Placeholder
	pass

# --- TURN LOGIC ---

func _on_round_started(round_num: int):
	battle_ui.log_message("--- ROUND %d START ---" % round_num)
	for unit in grid_manager.get_all_units():
		if is_instance_valid(unit):
			unit.has_acted = false
			unit.modulate = Color.WHITE

func _on_active_unit_changed(active_unit: Unit):
	battle_ui.update_turn_queue(turn_manager.turn_queue, active_unit)
	selected_unit = null
	highlighted_moves = []
	highlighted_attacks = []
	
	if is_instance_valid(active_unit) and active_unit.has_method("on_turn_start"):
		active_unit.on_turn_start()
	
	if is_instance_valid(active_unit) and active_unit.player_id == TurnManager.TEAM_PLAYER:
		_select_unit(active_unit)
		battle_ui.log_message("It is %s's turn." % active_unit.name)
	else:
		battle_ui.update_stats(null) 
	
	_refresh_visuals()

func _on_ai_turn_requested(unit: Unit):
	if is_instance_valid(unit):
		ai_manager.play_single_unit(unit, grid_manager.grid, COLS)
	else:
		turn_manager.end_current_turn()

# --- INPUT HANDLING (Updated for Drag & Drop) ---

func _unhandled_input(event):
	# Handle Deployment Drag & Drop
	if current_state == BattleState.DEPLOYMENT:
		_handle_deployment_input(event)
		return

	# Normal Battle Input
	if not turn_manager.is_player_turn(): return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_cell = grid_manager.world_to_grid(event.position)
		if _is_valid_cell(clicked_cell):
			handle_click(clicked_cell)

func _handle_deployment_input(event):
	if event is InputEventMouseButton:
		var clicked_cell = grid_manager.world_to_grid(event.position)
		
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 1. Check if we have a hero selected from bench
			if selected_hero_id_for_deployment != "":
				try_deploy_unit(selected_hero_id_for_deployment, clicked_cell)
				return # Handled placement
			
			# 2. Check if we clicked an existing unit on grid to select/move/undeploy
			var unit = grid_manager.get_unit_at(clicked_cell)
			if unit and unit.player_id == TurnManager.TEAM_PLAYER:
				# Simple toggle for undeploy on click for now (or select for move)
				# For simplicity: Click deployed unit to remove it
				undeploy_unit(unit)
				return

func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < COLS and cell.y >= 0 and cell.y < ROWS

func handle_click(cell: Vector2i):
	# Always hide swap prompt on new clicks to avoid stale state
	battle_ui.hide_swap_prompt()
	
	var active_unit = turn_manager.get_current_unit()
	if not is_instance_valid(active_unit) or active_unit.player_id != TurnManager.TEAM_PLAYER: return

	var clicked_unit = grid_manager.get_unit_at(cell)

	if clicked_unit:
		if clicked_unit == active_unit:
			_select_unit(active_unit)
			return

		if clicked_unit.player_id != TurnManager.TEAM_PLAYER:
			if cell in highlighted_attacks:
				perform_action(active_skill_mode, active_unit, clicked_unit)
				return
		
		if clicked_unit.player_id == TurnManager.TEAM_PLAYER:
			if active_unit.unit_class == "SUPPORT" and cell in highlighted_attacks:
				perform_support(active_unit, clicked_unit)
				return
			if cell in highlighted_moves:
				# Show prompt for swapping
				var screen_pos = clicked_unit.get_global_transform_with_canvas().origin
				battle_ui.show_swap_prompt(screen_pos, func():
					perform_formation_move(active_unit, cell)
				)
				return

	elif not clicked_unit:
		if cell in highlighted_moves:
			perform_formation_move(active_unit, cell)

func _select_unit(unit: Unit):
	selected_unit = unit
	if active_skill_mode == "": active_skill_mode = "BASIC"
	battle_ui.update_stats(unit)
	battle_ui.set_active_mode(active_skill_mode)
	highlighted_moves = get_valid_formation_moves(unit)
	_refresh_highlights()
	_refresh_visuals()

# --- ACTIONS ---

func perform_action(action_type: String, attacker: Unit, defender: Unit):
	var success = false
	if action_type == "BASIC": success = attacker.try_use_basic_attack(defender)
	elif action_type == "ADVANCED": success = attacker.try_use_advanced_skill(defender, grid_manager.grid, COLS)
	elif action_type == "ULTIMATE": success = attacker.try_use_ultimate_skill(defender, grid_manager.grid, COLS)
	if success: finalize_action(attacker)

func perform_support(healer: Unit, target: Unit):
	target.current_hp = min(target.current_hp + 3, target.max_hp)
	finalize_action(healer)

func perform_formation_move(unit: Unit, target_cell: Vector2i):
	if unit.current_qi <= 0: return
	
	# FIX: Deduct Qi AND Update Visuals IMMEDIATELY
	unit.current_qi -= 1
	
	# Update Floating Bar
	if unit.ui:
		unit.ui.update_status(unit.current_hp, unit.max_hp, unit.current_qi, unit.max_qi)
	
	# FIX: Update Main UI Bar (BattleUI) if this unit is currently selected
	if selected_unit == unit:
		battle_ui.update_stats(unit)
		
	var other_unit = grid_manager.get_unit_at(target_cell)
	if other_unit:
		grid_manager.swap_units(unit, other_unit)
		unit.position = grid_manager.grid_to_world(unit.grid_pos)
		other_unit.position = grid_manager.grid_to_world(other_unit.grid_pos)
		unit.z_index = unit.grid_pos.y
		other_unit.z_index = other_unit.grid_pos.y
	else:
		grid_manager.move_unit(unit, target_cell)
		unit.position = grid_manager.grid_to_world(unit.grid_pos)
		unit.z_index = unit.grid_pos.y
	highlighted_moves = get_valid_formation_moves(unit)
	_refresh_highlights()
	_refresh_visuals()

func finalize_action(unit: Unit):
	unit.has_acted = true
	unit.modulate = Color.GRAY
	selected_unit = null
	highlighted_moves = []
	highlighted_attacks = []
	battle_ui.update_stats(null)
	_refresh_visuals()
	turn_manager.end_current_turn()

# --- UTILS ---

func _on_ui_action_mode_changed(mode: String):
	active_skill_mode = mode
	if selected_unit:
		_refresh_highlights()
		_refresh_visuals()

func _on_unit_log_event(msg: String):
	if battle_ui: battle_ui.log_message(msg)
	print(msg) 

func _refresh_highlights():
	if not selected_unit: return
	var target_type = selected_unit.get_skill_target_type(active_skill_mode)
	highlighted_attacks = TargetingSystem.get_valid_targets(selected_unit, target_type, grid_manager.grid, COLS)

func _refresh_visuals():
	if current_state == BattleState.DEPLOYMENT:
		board_renderer.set_highlights(Vector2i(-1,-1), [], [])
		return

	var s_pos = selected_unit.grid_pos if selected_unit else Vector2i(-1, -1)
	board_renderer.set_highlights(s_pos, highlighted_moves, highlighted_attacks)

func get_valid_formation_moves(unit: Unit) -> Array[Vector2i]:
	if unit.current_qi <= 0: return []
	var moves: Array[Vector2i] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d in directions:
		var target = unit.grid_pos + d
		if _is_valid_cell(target):
			moves.append(target)
	return moves

func _on_viewport_resize():
	var screen_size = get_viewport_rect().size
	var margin_x = screen_size.x * 0.05
	var margin_top = screen_size.y * 0.05
	var margin_bottom = screen_size.y * 0.20 
	var available_w = screen_size.x - (margin_x * 2)
	var available_h = screen_size.y - (margin_top + margin_bottom)
	var possible_tile_w = available_w / COLS
	var possible_tile_h = available_h / ROWS
	var new_tile_size = min(possible_tile_w, possible_tile_h)
	var total_board_w = new_tile_size * COLS
	var total_board_h = new_tile_size * ROWS
	var new_offset = Vector2((screen_size.x - total_board_w) / 2.0, margin_top + ((available_h - total_board_h) / 2.0))
	
	if grid_manager:
		grid_manager.tile_size = new_tile_size
		grid_manager.board_offset = new_offset
	if board_renderer:
		board_renderer.update_layout(new_tile_size, new_offset)
	if grid_manager:
		for unit in grid_manager.get_all_units():
			unit.position = grid_manager.grid_to_world(unit.grid_pos)
			_scale_unit_sprite(unit)

func _scale_unit_sprite(unit: Unit):
	var t_size = grid_manager.tile_size
	var sprite = unit.get_node_or_null("Sprite2D")
	if not sprite or not sprite.texture:
		var scale_factor = t_size / BASE_TILE_SIZE
		unit.scale = Vector2(scale_factor, scale_factor)
		return
	var tex_size = sprite.texture.get_size()
	var target_size = Vector2(t_size, t_size)
	var scale_x = (target_size.x * 0.9) / tex_size.x
	var scale_y_limit = (target_size.y * 2.5) / tex_size.y
	var final_scale = min(scale_x, scale_y_limit)
	unit.scale = Vector2(final_scale, final_scale)
	var visual_height = tex_size.y * final_scale
	var vertical_shift = (visual_height - t_size) / 2.0
	sprite.position.y = -vertical_shift / final_scale
