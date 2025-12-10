extends Node2D

const COLS = 12 
const ROWS = 4
const ZONE_ROWS = 4
const ZONE_COLS = 3
const BASE_TILE_SIZE = 128.0

@export var background_texture: Texture2D 
var unit_scene = preload("res://Unit.tscn") 

# Battle State
var selected_unit: Unit = null
var active_skill_mode: String = "BASIC"
var highlighted_moves: Array[Vector2i] = []
var highlighted_attacks: Array[Vector2i] = []

# --- SUB-MANAGERS ---
var battle_ui: BattleUI # RENAMED from GameUI
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
	
	# UPDATED: Use BattleUI
	battle_ui = BattleUI.new()
	add_child(battle_ui)
	battle_ui.action_mode_changed.connect(_on_ui_action_mode_changed)
	battle_ui.end_turn_pressed.connect(func(): turn_manager.end_current_turn())
	
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
	
	call_deferred("_setup_battle")

func _setup_battle():
	_on_viewport_resize()
	
	_spawn_unit(1, 2, TurnManager.TEAM_PLAYER, "ZHAO_YUN", 1)
	
	_spawn_unit(9, 1, TurnManager.TEAM_ENEMY, "SOLDIER_DUMMY", 1)
	_spawn_unit(9, 2, TurnManager.TEAM_ENEMY, "SOLDIER_DUMMY", 2)
	_spawn_unit(9, 3, TurnManager.TEAM_ENEMY, "SOLDIER_DUMMY", 3)
	
	_spawn_unit(10, 1, TurnManager.TEAM_ENEMY, "ARCHER_DUMMY", 1)
	_spawn_unit(10, 2, TurnManager.TEAM_ENEMY, "ARCHER_DUMMY", 2)
	_spawn_unit(10, 3, TurnManager.TEAM_ENEMY, "ARCHER_DUMMY", 3)
	
	check_synergies()
	_refresh_visuals()
	
	turn_manager.start_game(grid_manager.get_all_units())

func _spawn_unit(x: int, y: int, team: String, hero_id: String, index: int = 1):
	var pos = Vector2i(x, y)
	var unit = UnitFactory.create_unit(hero_id, team, pos, unit_scene)
	if not unit: return
	
	if team == TurnManager.TEAM_ENEMY:
		unit.name = "%s %d" % [unit.name, index]
	
	add_child(unit)
	grid_manager.add_unit(unit)
	
	unit.position = grid_manager.grid_to_world(pos)
	unit.log_event.connect(_on_unit_log_event)
	unit.tree_exiting.connect(func(): _on_unit_died(unit))
	_scale_unit_sprite(unit)

func _on_unit_died(unit: Unit):
	if grid_manager:
		grid_manager.remove_unit(unit)
	_refresh_visuals()
	
	# Win/Loss Check
	_check_game_over_condition()

func _check_game_over_condition():
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
		battle_ui.log_message("--- DEFEAT: All heroes have fallen! ---")
		# Optional: Disable input or show game over screen here
		set_process_unhandled_input(false)
		
	elif not enemy_alive:
		battle_ui.log_message("--- VICTORY: All enemies defeated! ---")
		# Optional: Show victory screen here
		set_process_unhandled_input(false)

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

# --- INPUT (Player Turn Only) ---

func _unhandled_input(event):
	if not turn_manager.is_player_turn(): return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_cell = grid_manager.world_to_grid(event.position)
		if clicked_cell.x >= 0 and clicked_cell.x < COLS and clicked_cell.y >= 0 and clicked_cell.y < ROWS:
			handle_click(clicked_cell)

func handle_click(cell: Vector2i):
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
				perform_formation_move(active_unit, cell)
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
	if action_type == "BASIC":
		success = attacker.try_use_basic_attack(defender)
	elif action_type == "ADVANCED":
		success = attacker.try_use_advanced_skill(defender, grid_manager.grid, COLS)
	elif action_type == "ULTIMATE":
		success = attacker.try_use_ultimate_skill(defender, grid_manager.grid, COLS)
	
	if success:
		finalize_action(attacker)

func perform_support(healer: Unit, target: Unit):
	target.current_hp = min(target.current_hp + 3, target.max_hp)
	finalize_action(healer)

func perform_formation_move(unit: Unit, target_cell: Vector2i):
	if unit.current_qi <= 0: return
	unit.current_qi -= 1
	
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
	highlighted_attacks = TargetingSystem.get_valid_attacks(selected_unit, grid_manager.grid, COLS)

func _refresh_visuals():
	var s_pos = selected_unit.grid_pos if selected_unit else Vector2i(-1, -1)
	board_renderer.set_highlights(s_pos, highlighted_moves, highlighted_attacks)

func get_valid_formation_moves(unit: Unit) -> Array[Vector2i]:
	if unit.current_qi <= 0: return []
	var moves: Array[Vector2i] = []
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for d in directions:
		var target = unit.grid_pos + d
		if target.x >= 0 and target.x < COLS and target.y >= 0 and target.y < ROWS:
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
	
	var new_offset = Vector2(
		(screen_size.x - total_board_w) / 2.0,
		margin_top + ((available_h - total_board_h) / 2.0)
	)
	
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

func check_synergies(): pass
