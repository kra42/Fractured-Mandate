class_name AIManager
extends Node

signal request_redraw
signal turn_finished
signal log_message(text: String)

# NEW: Plays a turn for a SPECIFIC unit
func play_single_unit(unit: Unit, grid: Dictionary, cols: int):
	# Narrative Log
	var msg = "%s is preparing to act..." % unit.name
	log_message.emit(msg)
	
	# Artificial delay for "thinking"
	await get_tree().create_timer(0.8).timeout
	
	if not is_instance_valid(unit) or unit.current_hp <= 0:
		turn_finished.emit()
		return

	if unit.has_method("ai_take_turn"):
		unit.ai_take_turn(grid, cols)
		request_redraw.emit()
	else:
		var err = "%s has no 'ai_take_turn' method!" % unit.name
		log_message.emit(err)
		push_error(err)
		
	# Small pause after action
	await get_tree().create_timer(0.5).timeout
	
	# Signal back to GameBoard/TurnManager that we are done
	turn_finished.emit()
