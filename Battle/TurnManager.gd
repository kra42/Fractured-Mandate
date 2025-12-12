class_name TurnManager
extends Node

# Emitted when a specific unit starts their turn
signal turn_changed(active_unit: Unit)
# Emitted when a new round begins (timeline reset)
signal round_started(round_num: int)
# Emitted when an enemy unit needs to act
signal ai_turn_requested(unit: Unit)

const TEAM_PLAYER = "PLAYER"
const TEAM_ENEMY = "ENEMY"

var turn_queue: Array = []
var current_index: int = -1
var round_count: int = 0

# Start the game loop with a list of units
func start_game(all_units: Array):
	round_count = 0
	_start_new_round(all_units)

func _start_new_round(all_units: Array):
	round_count += 1
	# 1. Filter out dead units
	turn_queue = all_units.filter(func(u): return u != null and u.current_hp > 0)
	# --- FIX START ---
	if turn_queue.is_empty():
		print("TurnManager: No units left to act in this round.")
		return # Stop execution to prevent infinite recursion
	# --- FIX END ---
	# 2. Sort by Initiative
	turn_queue.sort_custom(func(a, b): return a.initiative > b.initiative)
	current_index = -1
	round_started.emit(round_count)
	# 3. Start first turn
	_advance_turn()

# Called when "End Turn" is pressed or AI finishes
func end_current_turn():
	_advance_turn()

func _advance_turn():
	current_index += 1
	
	# If we passed the last unit, start a new round
	if current_index >= turn_queue.size():
		# We need to refresh the list in case units died or spawned.
		# Ideally GameBoard passes us the fresh list, but for now we assume 
		# turn_queue objects are valid references. 
		# A safer way is to re-sort the existing survivors.
		_start_new_round(turn_queue)
		return

	var unit = turn_queue[current_index]
	
	# Skip if unit died pending their turn
	if not is_instance_valid(unit) or unit.current_hp <= 0:
		_advance_turn()
		return

	print("Turn Manager: Active Unit is ", unit.name)
	
	# Notify GameBoard/UI
	turn_changed.emit(unit)
	
	# If it's an enemy, request AI logic
	if unit.player_id == TEAM_ENEMY:
		ai_turn_requested.emit(unit)

# Helper to check if input is allowed
func is_player_turn() -> bool:
	var u = get_current_unit()
	return u != null and u.player_id == TEAM_PLAYER

func get_current_unit() -> Unit:
	if current_index >= 0 and current_index < turn_queue.size():
		return turn_queue[current_index]
	return null
