extends Unit

func _ready():
	unit_class = "WARRIOR" # Standard front-line behavior
	
	# Weak Stats
	max_hp = 8
	current_hp = 8
	max_qi = 0
	current_qi = 0
	
	# Weak Attack
	attack_power = 2
	
	# Low Initiative (Acts last)
	initiative = 5 
	
	resist = { "phys": 0, "fire": 0, "poison": 0 }
	super()

# --- SKILLS ---

func use_basic_attack(target: Unit) -> void:
	print("Soldier Dummy pokes ", target.name, " with spear.")
	target.take_damage(attack_power)

func use_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	print("Soldier Dummy tries to concentrate but fails.")
	return false

func use_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	print("Soldier Dummy looks confused.")
	return false

# --- AI LOGIC ---
# Soldiers attack the FIRST enemy they see in their row.
func ai_take_turn(grid: Dictionary, cols: int) -> void:
	# 1. Find target (Front-line only)
	var target_pos = TargetingSystem.get_enemy_in_row(grid_pos.y, player_id, "FIRST", grid, cols)
	
	if target_pos != Vector2i(-1, -1):
		var target = grid[target_pos]
		use_basic_attack(target)
	else:
		print("Soldier Dummy sees no target and waits.")
