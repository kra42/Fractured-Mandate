class_name Unit
extends Node2D

# --- CORE IDENTITY ---
var grid_pos: Vector2i
var player_id: String
var unit_class: String

# --- PRIMARY RESOURCES ---
var max_hp: int = 10
var current_hp: int = 10

var max_qi: int = 3      # Max energy/movement points
var current_qi: int = 1  # Current energy available

# --- OFFENSIVE STATS ---
var attack_power: int = 4

# --- UTILITY STATS ---
# Determines turn order (Higher = Acts earlier)
var initiative: int = 10 

# --- DEFENSIVE STATS ---
# Resistance percentages or flat reduction (0 = 0%)
var resist: Dictionary = {
	"phys": 0,
	"fire": 0,
	"poison": 0
}

# --- STATES ---
var has_acted: bool = false

# --- VIRTUAL SKILL FUNCTIONS (Override in Hero Scripts) ---

# 1. PASSIVE
# Triggered automatically by GameBoard events (e.g., "turn_start", "on_hit", "hp_low")
func activate_passive(trigger: String, context: Dictionary = {}) -> void:
	pass

# 2. BASIC ATTACK
# The standard attack. Usually generates Qi or is free.
func use_basic_attack(target: Unit) -> void:
	# Default: Deal damage based on attack power
	target.take_damage(attack_power)

# 3. ADVANCED SKILL
# A secondary skill. Usually has a cooldown or low Qi cost.
func use_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	print("Unit has no advanced skill.")
	return false

# 4. ULTIMATE SKILL
# The signature move. High impact, usually costs Qi.
func use_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	print("Unit has no ultimate skill.")
	return false

# --- STANDARD BEHAVIOR ---
func take_damage(amount: int):
	# Future: Calculate mitigation using resist["phys"] here
	current_hp -= amount
	print(unit_class, " took ", amount, " damage. HP: ", current_hp)
	if current_hp <= 0:
		queue_free() # Simplified death
