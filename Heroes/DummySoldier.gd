# Save this file at: res://Heroes/Hero_SoldierDummy.gd
extends Unit

func _ready():
	unit_class = "WARRIOR" # Standard front-line behavior
	
	# Weak Stats
	max_hp = 8
	current_hp = 8
	max_qi = 2
	current_qi = 0
	
	# Weak Attack
	attack_power = 2
	
	# Low Initiative (Acts last)
	initiative = 5 
	
	resist = { "phys": 0, "fire": 0, "poison": 0 }

# --- SKILLS ---

# Dummies only have a basic attack
func use_basic_attack(target: Unit) -> void:
	print("Soldier Dummy pokes with spear.")
	target.take_damage(attack_power)

# Dummies fail at advanced skills
func use_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	print("Soldier Dummy tries to concentrate but fails.")
	return false

# Dummies have no ultimate
func use_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	print("Soldier Dummy looks confused.")
	return false
