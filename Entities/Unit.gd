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

# Layout Settings
const UI_WIDTH = 80
const UI_HEIGHT_OFFSET = 100 # How high above the pivot the UI floats

func _ready():
	_setup_overhead_ui()

func _process(delta):
	# FORCE VISIBILITY FIX:
	# Keep the UI centered above the unit
	if overhead_container:
		# Center horizontally: -UI_WIDTH / 2
		# Float vertically: -UI_HEIGHT_OFFSET
		var center_offset = Vector2(-UI_WIDTH / 2.0, -UI_HEIGHT_OFFSET)
		overhead_container.global_position = global_position + center_offset
		overhead_container.global_scale = Vector2(1, 1) # Prevent UI from scaling with unit animations

func _setup_overhead_ui():
	# 1. Container Node 
	overhead_container = Node2D.new()
	overhead_container.set_as_top_level(true) 
	overhead_container.z_index = 100 
	add_child(overhead_container)
	
	# 2. Main Layout (Vertical Stack)
	var layout = VBoxContainer.new()
	layout.custom_minimum_size = Vector2(UI_WIDTH, 0)
	layout.add_theme_constant_override("separation", 2)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	overhead_container.add_child(layout)

	# Optional: Add a semi-transparent background behind the whole UI for readability
	var bg_panel = PanelContainer.new()
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.3) # Subtle shadow box
	bg_style.set_corner_radius_all(4)
	bg_style.expand_margin_left = 4
	bg_style.expand_margin_right = 4
	bg_style.expand_margin_top = 4
	bg_style.expand_margin_bottom = 4
	bg_panel.add_theme_stylebox_override("panel", bg_style)
	
	# We reparent the layout to be inside this background panel, 
	# then add the panel to overhead_container
	overhead_container.add_child(bg_panel)
	bg_panel.add_child(layout)

	# 3. HP BAR (Top)
	overhead_bar = ProgressBar.new()
	overhead_bar.custom_minimum_size = Vector2(UI_WIDTH, 14)
	overhead_bar.show_percentage = false
	
	# HP Bar Styling
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_bg.border_width_bottom = 2
	style_bg.border_width_top = 2
	style_bg.border_width_left = 2
	style_bg.border_width_right = 2
	style_bg.border_color = Color(0, 0, 0)
	overhead_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.2, 0.8, 0.2) 
	style_fill.border_width_bottom = 2
	style_fill.border_width_top = 2
	style_fill.border_width_left = 2
	style_fill.border_width_right = 2
	style_fill.border_color = Color(0,0,0,0) # Transparent border for fill
	overhead_bar.add_theme_stylebox_override("fill", style_fill)
	
	layout.add_child(overhead_bar)
	
	# 4. HP Text (Overlay on top of bar)
	overhead_label = Label.new()
	overhead_label.text = "10/10"
	overhead_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overhead_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	overhead_label.add_theme_font_size_override("font_size", 10)
	overhead_label.add_theme_constant_override("outline_size", 4)
	overhead_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Use a Control to center the label exactly on top of the bar
	overhead_bar.add_child(overhead_label)
	overhead_label.set_anchors_preset(Control.PRESET_FULL_RECT)

	# 5. QI ROW (Bottom - Icons)
	qi_container = HBoxContainer.new()
	qi_container.alignment = BoxContainer.ALIGNMENT_CENTER
	qi_container.add_theme_constant_override("separation", 1) # Tight spacing
	layout.add_child(qi_container)
	
	_update_visuals()

func _update_visuals():
	# Update HP Bar & Text
	if overhead_bar and overhead_label:
		overhead_bar.max_value = max_hp
		overhead_bar.value = current_hp
		overhead_label.text = "%d/%d" % [current_hp, max_hp]
		
		# Dynamic Color (Green -> Yellow -> Red)
		var pct = float(current_hp) / float(max_hp) if max_hp > 0 else 0
		var style = overhead_bar.get_theme_stylebox("fill").duplicate()
		if pct < 0.3: style.bg_color = Color(0.9, 0.2, 0.2) # Red
		elif pct < 0.6: style.bg_color = Color(0.9, 0.8, 0.1) # Yellow
		else: style.bg_color = Color(0.2, 0.8, 0.2) # Green
		overhead_bar.add_theme_stylebox_override("fill", style)

	# Update Qi Icons
	if qi_container:
		for child in qi_container.get_children():
			child.queue_free()
		
		for i in range(max_qi):
			var icon = TextureRect.new()
			if qi_texture:
				icon.texture = qi_texture
			else:
				# Fallback square
				var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
				img.fill(Color(0.2, 0.6, 1.0))
				icon.texture = ImageTexture.create_from_image(img)
			
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.custom_minimum_size = Vector2(16, 16)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# Dim empty Qi slots instead of hiding them (Standard RPG practice)
			if i >= current_qi:
				icon.modulate = Color(0.2, 0.2, 0.2, 0.5) # Grayed out
			else:
				icon.modulate = Color(1, 1, 1, 1) # Bright
				
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
