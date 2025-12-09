class_name UnitUI
extends Node2D

# --- GLOBAL SETTINGS ---
# Static variable shared by all UnitUI instances
static var _force_show_all: bool = false 

# --- CONFIG ---
const BAR_WIDTH = 8.0
const BAR_HEIGHT = 50.0 # Slightly shorter
const QI_ICON_SIZE = 14.0
const FADE_SPEED = 10.0

# --- COMPONENTS ---
var _bar: ProgressBar
var _qi_container: HBoxContainer
var _qi_texture: Texture2D

# --- STATE ---
var _target_unit: Node2D
var _base_z_index: int = 100

# VISIBILITY LOGIC
var _show_timer: float = 0.0 # How long to keep showing bar after an event (damage/heal)
var _is_hovered: bool = false

# --- STATIC METHODS ---
static func toggle_global_display(enabled: bool):
	_force_show_all = enabled

func _ready():
	_qi_texture = load("res://Image_Icons/qi.png")
	set_as_top_level(true)
	
	# Start completely invisible
	modulate.a = 0.0 
	
	_build_visuals()

func setup(target: Node2D):
	_target_unit = target
	_update_position()

func update_status(hp: int, max_hp: int, qi: int, max_qi: int):
	# TRIGGER VISIBILITY: When stats change (damage/heal), show UI for 2 seconds
	_show_timer = 2.0
	
	# 1. Update HP Bar
	if _bar:
		_bar.max_value = max_hp
		_bar.value = hp
		
		# Dynamic Color Logic
		var pct = float(hp) / float(max_hp) if max_hp > 0 else 0
		var style = _bar.get_theme_stylebox("fill").duplicate()
		if pct < 0.3: style.bg_color = Color(0.9, 0.2, 0.2) # Red
		elif pct < 0.6: style.bg_color = Color(0.9, 0.7, 0.1) # Yellow
		else: style.bg_color = Color(0.2, 0.8, 0.4) # Green
		_bar.add_theme_stylebox_override("fill", style)

	# 2. Update Qi Icons
	if _qi_container:
		for child in _qi_container.get_children():
			child.queue_free()
			
		for i in range(qi):
			var icon = TextureRect.new()
			if _qi_texture:
				icon.texture = _qi_texture
			else:
				var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
				img.fill(Color(0.2, 0.6, 1.0))
				icon.texture = ImageTexture.create_from_image(img)
			
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.custom_minimum_size = Vector2(QI_ICON_SIZE, QI_ICON_SIZE)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			_qi_container.add_child(icon)

func _process(delta):
	if not is_instance_valid(_target_unit):
		queue_free()
		return

	_update_position()
	_handle_z_index()
	_handle_visibility(delta)

func _handle_visibility(delta: float):
	# Check Hover
	var mouse_pos = get_global_mouse_position()
	var dist = _target_unit.global_position.distance_to(mouse_pos)
	_is_hovered = dist < 60.0 # Tile radius approx
	
	# Decrement timer
	if _show_timer > 0:
		_show_timer -= delta

	# Logic: Visible if Hovering OR Timer is active OR Global Force Show is ON
	var target_alpha = 0.0
	if _is_hovered or _show_timer > 0 or _force_show_all:
		target_alpha = 1.0
	
	# Smooth Fade
	modulate.a = lerp(modulate.a, target_alpha, FADE_SPEED * delta)

func _handle_z_index():
	if "grid_pos" in _target_unit:
		# Draw above unit (y*10)
		# If hovered/active, draw WAY above everything else (+100)
		var active_boost = 100 if modulate.a > 0.1 else 0
		z_index = (_target_unit.grid_pos.y * 10) + 10 + active_boost

func _update_position():
	if _target_unit:
		global_position = _target_unit.global_position

func _build_visuals():
	for c in get_children(): c.queue_free()

	# Vertical Bar (Right Side)
	_bar = ProgressBar.new()
	_bar.fill_mode = 3 # Bottom to Top
	_bar.show_percentage = false
	_bar.custom_minimum_size = Vector2(BAR_WIDTH, BAR_HEIGHT)
	_bar.position = Vector2(28, -BAR_HEIGHT / 2.0)
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.0, 0.0, 0.0, 0.6) # More transparent BG
	_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.2, 0.8, 0.4)
	_bar.add_theme_stylebox_override("fill", style_fill)
	add_child(_bar)

	# Qi Container (Bottom)
	_qi_container = HBoxContainer.new()
	_qi_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_qi_container.add_theme_constant_override("separation", 2)
	_qi_container.custom_minimum_size = Vector2(80, 20)
	_qi_container.position = Vector2(-40, 35)
	add_child(_qi_container)
