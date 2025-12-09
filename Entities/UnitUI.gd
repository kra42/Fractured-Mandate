class_name UnitUI
extends Node2D

# --- CONFIG ---
const UI_WIDTH = 80
const UI_HEIGHT_OFFSET = 100 # Height above the unit pivot
const FADE_SPEED = 15.0
const FADE_OUT_SPEED = 5.0

# --- COMPONENTS ---
var _bar: ProgressBar
var _lbl_hp: Label
var _qi_container: HBoxContainer
var _qi_texture: Texture2D

# --- STATE ---
var _target_unit: Node2D # The unit we are following
var _base_z_index: int = 100

func _ready():
	_qi_texture = load("res://Image_Icons/qi.png")
	
	# Important: Detach from parent's transform so we don't scale/rotate with the unit sprite
	set_as_top_level(true)
	
	_build_visuals()

func setup(target: Node2D):
	_target_unit = target
	_update_position()

func update_status(hp: int, max_hp: int, qi: int, max_qi: int):
	# 1. Update HP
	if _bar and _lbl_hp:
		_bar.max_value = max_hp
		_bar.value = hp
		_lbl_hp.text = "%d/%d" % [hp, max_hp]
		
		# Color logic
		var pct = float(hp) / float(max_hp) if max_hp > 0 else 0
		var style = _bar.get_theme_stylebox("fill").duplicate()
		if pct < 0.3: style.bg_color = Color(0.9, 0.2, 0.2) # Red
		elif pct < 0.6: style.bg_color = Color(0.9, 0.8, 0.1) # Yellow
		else: style.bg_color = Color(0.2, 0.8, 0.2) # Green
		_bar.add_theme_stylebox_override("fill", style)

	# 2. Update Qi (Re-draw icons)
	if _qi_container:
		for child in _qi_container.get_children():
			child.queue_free()
			
		for i in range(qi):
			var icon = TextureRect.new()
			if _qi_texture:
				icon.texture = _qi_texture
			else:
				var img = Image.create(8, 8, false, Image.FORMAT_RGBA8)
				img.fill(Color(1, 0.65, 0))
				icon.texture = ImageTexture.create_from_image(img)
			
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.custom_minimum_size = Vector2(16, 16)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.modulate = Color(1.0, 0.65, 0.0) # Orange Tint
			_qi_container.add_child(icon)

func _process(delta):
	if not is_instance_valid(_target_unit):
		queue_free()
		return

	# 1. Follow Position
	_update_position()

	# 2. Handle Z-Sorting based on Grid Y (Depth)
	# We access the 'grid_pos' property dynamically
	if "grid_pos" in _target_unit:
		_base_z_index = 100 + (_target_unit.grid_pos.y * 10)
	
	# 3. Handle Hover / Focus Fading
	var mouse_pos = get_global_mouse_position()
	var dist = _target_unit.global_position.distance_to(mouse_pos)
	var is_hovering = dist < 60.0 # Approx tile radius
	
	if is_hovering:
		modulate.a = lerp(modulate.a, 1.0, FADE_SPEED * delta)
		z_index = _base_z_index + 100 # Pop to front
	else:
		modulate.a = lerp(modulate.a, 0.6, FADE_OUT_SPEED * delta)
		z_index = _base_z_index

func _update_position():
	# Keep centered above unit
	var center_offset = Vector2(-UI_WIDTH / 2.0, -UI_HEIGHT_OFFSET)
	global_position = _target_unit.global_position + center_offset

func _build_visuals():
	# Background Panel
	var panel = PanelContainer.new()
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.3)
	bg_style.set_corner_radius_all(4)
	bg_style.expand_margin_left = 4; bg_style.expand_margin_right = 4
	bg_style.expand_margin_top = 4; bg_style.expand_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", bg_style)
	add_child(panel)

	var layout = VBoxContainer.new()
	layout.custom_minimum_size = Vector2(UI_WIDTH, 0)
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 2)
	panel.add_child(layout)

	# HP Bar
	_bar = ProgressBar.new()
	_bar.custom_minimum_size = Vector2(UI_WIDTH, 14)
	_bar.show_percentage = false
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	style_bg.border_width_bottom = 2; style_bg.border_width_top = 2
	style_bg.border_width_left = 2; style_bg.border_width_right = 2
	style_bg.border_color = Color(0,0,0)
	_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0.2, 0.8, 0.2)
	style_fill.border_width_bottom = 2; style_fill.border_width_top = 2
	style_fill.border_width_left = 2; style_fill.border_width_right = 2
	style_fill.border_color = Color.TRANSPARENT
	_bar.add_theme_stylebox_override("fill", style_fill)
	
	layout.add_child(_bar)

	# HP Label
	_lbl_hp = Label.new()
	_lbl_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_hp.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_hp.add_theme_font_size_override("font_size", 10)
	_lbl_hp.add_theme_constant_override("outline_size", 4)
	_lbl_hp.add_theme_color_override("font_outline_color", Color.BLACK)
	_bar.add_child(_lbl_hp)
	_lbl_hp.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Qi Container
	_qi_container = HBoxContainer.new()
	_qi_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_qi_container.add_theme_constant_override("separation", 1)
	layout.add_child(_qi_container)
