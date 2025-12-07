extends Node2D
class_name Unit

# --- CONFIGURATION ---
@export_enum("WARRIOR", "ARCHER") var unit_class: String = "WARRIOR"
@export_enum("P1", "P2") var player_id: String = "P1"

# --- STATS ---
@export var max_hp: int = 12
@export var max_qi: int = 3
@export var move_range: int = 3

# --- DYNAMIC STATE ---
var current_hp: int
var current_qi: int
var has_moved: bool = false
var has_acted: bool = false
var grid_pos: Vector2i

func _ready():
	if unit_class == "ARCHER":
		max_hp = 8
		move_range = 3
	elif unit_class == "WARRIOR":
		max_hp = 12
		move_range = 3
	
	current_hp = max_hp
	current_qi = max_qi
	
	if player_id == "P1":
		modulate = Color(0.4, 0.8, 1.0)
	else:
		modulate = Color(1.0, 0.4, 0.6)

func start_turn():
	has_moved = false
	has_acted = false
	current_qi = min(max_qi, current_qi + 1)
	
	if player_id == "P1":
		modulate = Color(0.4, 0.8, 1.0)
	else:
		modulate = Color(1.0, 0.4, 0.6)

func take_damage(amount: int):
	current_hp -= amount
	print(name + " took " + str(amount) + " damage. HP: " + str(current_hp))
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if current_hp <= 0:
		die()

func die():
	print(name + " died!")
	queue_free()
