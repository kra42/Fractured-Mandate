class_name Unit
extends Node2D

signal log_event(text: String)

var grid_pos: Vector2i
var player_id: String
var unit_class: String

var max_hp: int = 10
var current_hp: int = 10
var max_qi: int = 3
var current_qi: int = 1 

const COST_MOVE = 1
const COST_ADVANCED = 2
const COST_ULTIMATE = 5

var attack_power: int = 4
var initiative: int = 10 
var resist: Dictionary = { "phys": 0, "fire": 0, "poison": 0 }
var has_acted: bool = false

# --- VISUAL COMPONENTS ---
var overhead_container: Node2D 
var overhead_bar: ProgressBar
var overhead_label: Label
var qi_container: HBoxContainer

# LOAD THE REAL TEXTURE
var qi_texture: Texture2D = load("res://Image_Icons/qi.png")

func _ready():
	_setup_overhead_ui()

func _process(delta):
	# FORCE VISIBILITY FIX:
	# If we use set_as_top_level(true), the container ignores parent transform.
	# We must manually sync its position to the unit.
	if overhead_container:
		# Keep it above the unit. 
		# Adjust Y offset (-80) based on your tile/sprite size.
		overhead_container.global_position = global_position + Vector2(-40, -80)
		overhead_container.global_scale = Vector2(1, 1) # Ensure 1:1 scale

func _setup_overhead_ui():
	# 1. Container Node 
	overhead_container = Node2D.new()
	# Detach from parent transform so it doesn't shrink with the unit sprite
	overhead_container.set_as_top_level(true) 
	overhead_container.z_index = 100 # Extreme Z-Index to be sure
	add_child(overhead_container)
	
	# The actual layout container
	var layout = VBoxContainer.new()
	# Position is now relative to the overhead_container (which is at unit pos)
	layout.position = Vector2.ZERO 
	layout.custom_minimum_size = Vector2(80, 0)
	layout.add_theme_constant_override("separation", 2)
	overhead_container.add_child(layout)

	# 2. HP ROW (Bar + Text)
	var hp_row = HBoxContainer.new()
	layout.add_child(hp_row)
	
	overhead_bar = ProgressBar.new()
	overhead_bar.custom_minimum_size = Vector2(50, 10)
	overhead_bar.show_percentage = false
	overhead_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.5)
	overhead_bar.add_theme_stylebox_override("background", bg)
	var fill = StyleBoxFlat.new()
	fill.bg_color = Color(0.2, 0.8, 0.2) 
	overhead_bar.add_theme_stylebox_override("fill", fill)
	
	hp_row.add_child(overhead_bar)
	
	overhead_label = Label.new()
	overhead_label.text = "10/10"
	overhead_label.add_theme_font_size_override("font_size", 14)
	overhead_label.add_theme_constant_override("outline_size", 4)
	overhead_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hp_row.add_child(overhead_label)

	# 3. QI ROW (Icons)
	qi_container = HBoxContainer.new()
	qi_container.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_child(qi_container)
	
	_update_visuals()

func _update_visuals():
	# Update HP Bar & Text
	if overhead_bar and overhead_label:
		overhead_bar.max_value = max_hp
		overhead_bar.value = current_hp
		overhead_label.text = "%d/%d" % [current_hp, max_hp]
		
		# Dynamic Color
		var pct = float(current_hp) / float(max_hp) if max_hp > 0 else 0
		var style = overhead_bar.get_theme_stylebox("fill").duplicate()
		if pct < 0.3: style.bg_color = Color(0.9, 0.1, 0.1) # Red
		elif pct < 0.6: style.bg_color = Color(0.9, 0.9, 0.1) # Yellow
		else: style.bg_color = Color(0.2, 0.8, 0.2) # Green
		overhead_bar.add_theme_stylebox_override("fill", style)

	# Update Qi Icons
	if qi_container:
		for child in qi_container.get_children():
			child.queue_free()
		
		for i in range(current_qi):
			var icon = TextureRect.new()
			if qi_texture:
				icon.texture = qi_texture
			else:
				var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
				img.fill(Color(0.2, 0.6, 1.0))
				icon.texture = ImageTexture.create_from_image(img)
				
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(24, 24) # Ensure icons are big enough
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			qi_container.add_child(icon)

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

# --- VIRTUAL METHODS ---

func _perform_basic_attack(target: Unit) -> void:
	log_event.emit(name + " attacks " + target.name)
	target.take_damage(attack_power)

func _perform_advanced_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	return false 

func _perform_ultimate_skill(target: Unit, grid: Dictionary, cols: int) -> bool:
	return false 

# --- COST LOGIC ---

func _can_afford_skill(type: String, cost: int) -> bool:
	return current_qi >= cost

func _pay_skill_cost(type: String, cost: int) -> void:
	current_qi -= cost
	_update_visuals() 

# --- STANDARD BEHAVIOR ---
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
