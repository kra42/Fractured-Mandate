class_name Unit
extends Node2D

signal log_event(text: String)

# Core Stats
var grid_pos: Vector2i
var player_id: String
var unit_class: String

var max_hp: int = 10
var current_hp: int = 10
var max_qi: int = 3
var current_qi: int = 1 

var attack_power: int = 4
var initiative: int = 10 
var resist: Dictionary = { "phys": 0, "fire": 0, "poison": 0 }
var has_acted: bool = false

# Constants
const COST_MOVE = 1
const COST_ADVANCED = 2
const COST_ULTIMATE = 5

# --- VISUALS ---
var ui: UnitUI 

func _ready():
	_setup_ui()

func _setup_ui():
	# Instantiate our separated UI component
	ui = UnitUI.new()
	add_child(ui)
	ui.setup(self) # Tell UI to follow 'self'
	_update_visuals()

func _update_visuals():
	if ui:
		ui.update_status(current_hp, max_hp, current_qi, max_qi)

# --- PUBLIC API ---

func try_use_basic_attack(target: Unit) -> bool:
	_perform_basic_attack(target)
	return true

func try_use_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	if not _can_afford_skill("ADVANCED", COST_ADVANCED):
		log_event.emit("%s: Not enough Qi! (%d/%d)" % [name, current_qi, COST_ADVANCED])
		return false
	if _perform_advanced_skill(target, grid, cols):
		_pay_skill_cost("ADVANCED", COST_ADVANCED)
		return true
	return false

func try_use_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	if not _can_afford_skill("ULTIMATE", COST_ULTIMATE):
		log_event.emit("%s: Not enough Qi! (%d/%d)" % [name, current_qi, COST_ULTIMATE])
		return false
	if _perform_ultimate_skill(target, grid, cols):
		_pay_skill_cost("ULTIMATE", COST_ULTIMATE)
		return true
	return false

# --- VIRTUAL METHODS (Override these in subclasses) ---

func _perform_basic_attack(target: Unit) -> void:
	log_event.emit(name + " attacks " + target.name)
	target.take_damage(attack_power)

func _perform_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	return false 

func _perform_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	return false 

# --- INTERNAL LOGIC ---

func _can_afford_skill(type: String, cost: int) -> bool:
	return current_qi >= cost

func _pay_skill_cost(type: String, cost: int) -> void:
	current_qi -= cost
	_update_visuals() 

func on_turn_start() -> void:
	if current_qi < max_qi:
		current_qi += 1
		log_event.emit("%s gained 1 Qi. (%d/%d)" % [name, current_qi, max_qi])
	_update_visuals() 

func take_damage(amount: int):
	current_hp -= amount
	_update_visuals() 
	
	log_event.emit("%s took %d damage. HP: %d" % [name, amount, current_hp])
	if current_hp <= 0:
		log_event.emit(name + " was defeated!")
		queue_free()
