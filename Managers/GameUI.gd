class_name GameUI
extends CanvasLayer

signal action_mode_changed(mode: String) 
signal end_turn_pressed

var lbl_name: Label
var lbl_hp: Label
var lbl_qi: Label

var btn_basic: Button
var btn_adv: Button
var btn_ult: Button
var btn_end: Button

var log_box: TextEdit 
var hbox_turn_queue: HBoxContainer

func _ready():
	_setup_ui()

func _setup_ui():
	var root = Control.new()
	root.name = "UIRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	# 1. Stats Panel
	var panel_stats = PanelContainer.new()
	panel_stats.position = Vector2(20, 20)
	root.add_child(panel_stats)
	var vbox = VBoxContainer.new()
	panel_stats.add_child(vbox)
	lbl_name = Label.new()
	lbl_name.text = "Select a Unit"
	vbox.add_child(lbl_name)
	lbl_hp = Label.new()
	vbox.add_child(lbl_hp)
	lbl_qi = Label.new()
	vbox.add_child(lbl_qi)

	# 2. End Turn Button
	btn_end = Button.new()
	btn_end.text = "End Turn"
	btn_end.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_end.position = Vector2(-120, 20)
	btn_end.pressed.connect(func(): end_turn_pressed.emit())
	root.add_child(btn_end)

	# 3. Action Bar
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hbox.position = Vector2(0, -80)
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.add_theme_constant_override("separation", 10)
	root.add_child(hbox)
	
	btn_basic = _create_action_btn("Basic Atk", "BASIC", hbox)
	btn_adv = _create_action_btn("Skill", "ADVANCED", hbox)
	btn_ult = _create_action_btn("Ultimate", "ULTIMATE", hbox)

	# 4. Combat Log
	var panel_log = PanelContainer.new()
	panel_log.anchor_top = 1.0
	panel_log.anchor_bottom = 1.0
	panel_log.offset_top = -220
	panel_log.offset_bottom = -20
	panel_log.offset_left = 20
	panel_log.offset_right = 400
	root.add_child(panel_log)
	
	log_box = TextEdit.new()
	log_box.editable = false 
	log_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	log_box.text = "Welcome to Fractured Mandate.\n"
	panel_log.add_child(log_box)

	# 5. INITIATIVE BAR
	# Background Line
	var timeline_bg = ColorRect.new()
	timeline_bg.color = Color(0, 0, 0, 0.5)
	timeline_bg.custom_minimum_size = Vector2(400, 4)
	timeline_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timeline_bg.position.y = 45 # Center of icons approx
	root.add_child(timeline_bg)

	hbox_turn_queue = HBoxContainer.new()
	hbox_turn_queue.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hbox_turn_queue.position.y = 20
	hbox_turn_queue.add_theme_constant_override("separation", 10)
	root.add_child(hbox_turn_queue)

func _create_action_btn(text: String, mode: String, parent: Node) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(100, 50)
	btn.pressed.connect(func(): _on_action_btn_pressed(mode))
	parent.add_child(btn)
	return btn

func _on_action_btn_pressed(mode: String):
	set_active_mode(mode)
	action_mode_changed.emit(mode)

func set_active_mode(mode: String):
	btn_basic.set_pressed_no_signal(mode == "BASIC")
	btn_adv.set_pressed_no_signal(mode == "ADVANCED")
	btn_ult.set_pressed_no_signal(mode == "ULTIMATE")

func update_stats(unit):
	if not unit:
		lbl_name.text = "Select a Unit"
		lbl_hp.text = ""
		lbl_qi.text = ""
		return
	var hero_name = unit.get_meta("hero_id", "Unknown Unit")
	lbl_name.text = hero_name + " [" + unit.unit_class + "]"
	lbl_hp.text = "HP: %d / %d" % [unit.current_hp, unit.max_hp]
	lbl_qi.text = "Qi: %d / %d" % [unit.current_qi, unit.max_qi]

func log_message(msg: String):
	if log_box:
		log_box.text += msg + "\n"
		log_box.scroll_vertical = log_box.get_line_count()

# --- UPDATED TIMELINE VISUALS ---
func update_turn_queue(units_queue: Array, active_unit: Unit):
	# Clear old icons
	for child in hbox_turn_queue.get_children():
		child.queue_free()
	
	for unit in units_queue:
		if not is_instance_valid(unit) or unit.current_hp <= 0: continue
		
		var is_active = (unit == active_unit)
		
		# Container
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.6)
		style.border_width_bottom = 4
		
		# Border Color
		if unit.player_id == "PLAYER":
			style.border_color = Color(0.2, 0.4, 0.8) # Blue
		else:
			style.border_color = Color(0.8, 0.2, 0.2) # Red
		
		# HIGHLIGHT ACTIVE UNIT
		if is_active:
			style.border_color = style.border_color.lightened(0.5) # Glow effect
			style.border_width_top = 4
			style.border_width_left = 4
			style.border_width_right = 4
			panel.scale = Vector2(1.2, 1.2) # Scale up slightly
		else:
			panel.modulate = Color(0.7, 0.7, 0.7, 0.8) # Dim others
			
		panel.add_theme_stylebox_override("panel", style)
		
		# Icon
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(50, 50)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var sprite = unit.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			icon.texture = sprite.texture
			
		panel.add_child(icon)
		
		# Initiative Number
		var lbl_init = Label.new()
		lbl_init.text = str(unit.initiative)
		lbl_init.add_theme_font_size_override("font_size", 12)
		lbl_init.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(lbl_init)
		
		hbox_turn_queue.add_child(panel)
