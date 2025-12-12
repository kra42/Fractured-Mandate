class_name BattleUI
extends CanvasLayer

signal action_mode_changed(mode: String) 
signal end_turn_pressed
signal start_battle_pressed
signal deployment_hero_selected(hero_id: String) # NEW Signal for clicking bench

# --- UI ELEMENTS ---
var lbl_name: Label
var bar_hp: ProgressBar
var bar_qi: ProgressBar
var lbl_hp_text: Label
var lbl_qi_text: Label

var btn_passive: Button
var btn_basic: Button
var btn_adv: Button
var btn_ult: Button
var btn_details: Button 
var btn_end: Button
var btn_toggle_states: Button

var log_box: TextEdit
var panel_log: PanelContainer 
var hbox_turn_queue: HBoxContainer

# Popup for Details
var popup_details: Window
var lbl_details_content: RichTextLabel

# --- DEPLOYMENT UI ELEMENTS ---
var deployment_panel: PanelContainer
var hbox_bench: HBoxContainer
var btn_start_battle: Button
var battle_ui_container: Control 

# Track currently selected hero for visual feedback
var selected_bench_hero_id: String = ""

func _ready():
	_setup_ui()

func _setup_ui():
	var root = Control.new()
	root.name = "UIRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	# --- BATTLE UI CONTAINER ---
	battle_ui_container = Control.new()
	battle_ui_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_ui_container.mouse_filter = Control.MOUSE_FILTER_PASS
	battle_ui_container.visible = false 
	root.add_child(battle_ui_container)

	# 1. ENHANCED STATS PANEL 
	var panel_stats = PanelContainer.new()
	panel_stats.position = Vector2(20, 20)
	panel_stats.custom_minimum_size = Vector2(200, 0)
	battle_ui_container.add_child(panel_stats)
	
	var vbox = VBoxContainer.new()
	panel_stats.add_child(vbox)
	
	lbl_name = Label.new()
	lbl_name.text = "Select a Unit"
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 18)
	vbox.add_child(lbl_name)
	
	# HP BAR
	var hp_container = VBoxContainer.new()
	vbox.add_child(hp_container)
	var lbl_hp_header = Label.new()
	lbl_hp_header.text = "Health"
	hp_container.add_child(lbl_hp_header)
	
	bar_hp = ProgressBar.new()
	bar_hp.custom_minimum_size = Vector2(0, 20)
	bar_hp.show_percentage = false
	var style_hp = StyleBoxFlat.new()
	style_hp.bg_color = Color(0.8, 0.2, 0.2)
	bar_hp.add_theme_stylebox_override("fill", style_hp)
	
	lbl_hp_text = Label.new()
	lbl_hp_text.text = "0 / 0"
	lbl_hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_hp_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_hp.add_child(lbl_hp_text)
	hp_container.add_child(bar_hp)

	# QI BAR
	var qi_container = VBoxContainer.new()
	vbox.add_child(qi_container)
	var lbl_qi_header = Label.new()
	lbl_qi_header.text = "Qi (Energy)"
	qi_container.add_child(lbl_qi_header)
	
	bar_qi = ProgressBar.new()
	bar_qi.custom_minimum_size = Vector2(0, 20)
	bar_qi.show_percentage = false
	var style_qi = StyleBoxFlat.new()
	style_qi.bg_color = Color(0.2, 0.4, 0.8)
	bar_qi.add_theme_stylebox_override("fill", style_qi)
	
	lbl_qi_text = Label.new()
	lbl_qi_text.text = "0 / 0"
	lbl_qi_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_qi_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar_qi.add_child(lbl_qi_text)
	qi_container.add_child(bar_qi)
	
	# DETAILS BUTTON
	btn_details = Button.new()
	btn_details.text = "View Details"
	btn_details.pressed.connect(_on_details_pressed)
	btn_details.disabled = true
	vbox.add_child(btn_details)

	# 2. Top Right Buttons
	btn_end = Button.new()
	btn_end.text = "End Turn"
	btn_end.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_end.position = Vector2(-120, 20)
	btn_end.pressed.connect(func(): end_turn_pressed.emit())
	battle_ui_container.add_child(btn_end)

	btn_toggle_states = Button.new()
	btn_toggle_states.text = "Show States"
	btn_toggle_states.toggle_mode = true
	btn_toggle_states.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	btn_toggle_states.position = Vector2(-240, 20) 
	btn_toggle_states.pressed.connect(_on_toggle_states_pressed)
	battle_ui_container.add_child(btn_toggle_states)

	# 3. Action Bar (Bottom Center)
	var hbox_actions = HBoxContainer.new()
	hbox_actions.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hbox_actions.position = Vector2(0, -80)
	hbox_actions.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox_actions.add_theme_constant_override("separation", 10)
	battle_ui_container.add_child(hbox_actions)
	
	btn_passive = Button.new()
	btn_passive.text = "Passive"
	btn_passive.custom_minimum_size = Vector2(100, 50)
	hbox_actions.add_child(btn_passive)
	
	btn_basic = _create_action_btn("Basic Atk", "BASIC", hbox_actions)
	btn_adv = _create_action_btn("Skill (2 Qi)", "ADVANCED", hbox_actions)
	btn_ult = _create_action_btn("Ult (5 Qi)", "ULTIMATE", hbox_actions)

	# 5. Timeline
	var timeline_bg = ColorRect.new()
	timeline_bg.color = Color(0, 0, 0, 0.5)
	timeline_bg.custom_minimum_size = Vector2(400, 4)
	timeline_bg.set_anchors_preset(Control.PRESET_CENTER_TOP)
	timeline_bg.position.y = 45 
	battle_ui_container.add_child(timeline_bg)

	hbox_turn_queue = HBoxContainer.new()
	hbox_turn_queue.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hbox_turn_queue.position.y = 20
	hbox_turn_queue.add_theme_constant_override("separation", 10)
	battle_ui_container.add_child(hbox_turn_queue)

	# --- DEPLOYMENT UI ---
	deployment_panel = PanelContainer.new()
	deployment_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	deployment_panel.custom_minimum_size = Vector2(0, 160)
	deployment_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(deployment_panel)
	
	var vbox_deploy = VBoxContainer.new()
	deployment_panel.add_child(vbox_deploy)
	
	var lbl_deploy = Label.new()
	lbl_deploy.text = "Deployment Phase: Click hero then click grid to place"
	lbl_deploy.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_deploy.add_child(lbl_deploy)
	
	hbox_bench = HBoxContainer.new()
	hbox_bench.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_bench.add_theme_constant_override("separation", 20)
	hbox_bench.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_deploy.add_child(hbox_bench)
	
	btn_start_battle = Button.new()
	btn_start_battle.text = "Start Battle"
	btn_start_battle.custom_minimum_size = Vector2(150, 40)
	btn_start_battle.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_start_battle.disabled = true 
	btn_start_battle.pressed.connect(func(): start_battle_pressed.emit())
	vbox_deploy.add_child(btn_start_battle)

	# 4. Combat Log
	panel_log = PanelContainer.new()
	panel_log.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	panel_log.grow_horizontal = Control.GROW_DIRECTION_END
	panel_log.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel_log.anchor_left = 0.0
	panel_log.anchor_top = 1.0
	panel_log.anchor_right = 0.0
	panel_log.anchor_bottom = 1.0
	panel_log.offset_left = 0
	panel_log.offset_top = -180 
	panel_log.offset_right = 360 
	panel_log.offset_bottom = 0
	panel_log.visible = false 
	root.add_child(panel_log)
	
	log_box = TextEdit.new()
	log_box.editable = false 
	log_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	log_box.text = "Welcome to Fractured Mandate.\n"
	panel_log.add_child(log_box)

	# 6. DETAILS POPUP
	popup_details = Window.new()
	popup_details.title = "Unit Details"
	popup_details.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	popup_details.size = Vector2(400, 300)
	popup_details.visible = false
	popup_details.close_requested.connect(func(): popup_details.hide())
	add_child(popup_details)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	popup_details.add_child(margin)
	
	lbl_details_content = RichTextLabel.new()
	lbl_details_content.bbcode_enabled = true
	margin.add_child(lbl_details_content)

# --- DEPLOYMENT FUNCTIONS ---

func setup_deployment_bench(roster_data: Array):
	deployment_panel.visible = true
	battle_ui_container.visible = false 
	panel_log.visible = false 
	selected_bench_hero_id = ""
	
	for child in hbox_bench.get_children():
		child.queue_free()
		
	for hero_id in roster_data:
		var slot = _create_bench_slot(hero_id)
		hbox_bench.add_child(slot)
		
	_update_start_button(0, roster_data.size())

func _create_bench_slot(hero_id: String) -> Control:
	# Use a Button or Control that can handle input
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(100, 120)
	btn.toggle_mode = true # Allows "Selected" state visual
	
	# Connect click
	btn.pressed.connect(func(): _on_bench_slot_pressed(btn, hero_id))
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	# Make sure vbox doesn't block mouse
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.add_child(vbox)
	
	# Sprite Display
	var tex_rect = TextureRect.new()
	tex_rect.custom_minimum_size = Vector2(64, 64)
	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if UnitFactory.HERO_DB.has(hero_id):
		var data = UnitFactory.HERO_DB[hero_id]
		if data.has("texture") and data["texture"]:
			tex_rect.texture = data["texture"]
	
	vbox.add_child(tex_rect)
	
	# Name Label
	var lbl = Label.new()
	lbl.text = _format_hero_name(hero_id)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size = Vector2(90, 0)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(lbl)
	
	return btn

func _on_bench_slot_pressed(pressed_btn: Button, hero_id: String):
	# Deselect others
	for child in hbox_bench.get_children():
		if child is Button and child != pressed_btn:
			child.set_pressed_no_signal(false)
	
	# Toggle logic
	if pressed_btn.button_pressed:
		selected_bench_hero_id = hero_id
		deployment_hero_selected.emit(hero_id)
	else:
		selected_bench_hero_id = ""
		deployment_hero_selected.emit("")

func _format_hero_name(id: String) -> String:
	return id.capitalize().replace("_", " ")

func update_deployment_status(current_count: int, max_count: int):
	var percent = "%d / %d" % [current_count, max_count]
	btn_start_battle.text = "Start Battle (" + percent + ")"
	_update_start_button(current_count, max_count)

func _update_start_button(current: int, max_allowed: int):
	btn_start_battle.disabled = (current == 0)

func hide_deployment_ui():
	deployment_panel.visible = false
	battle_ui_container.visible = true 
	panel_log.visible = true 

# --- EXISTING FUNCTIONS ---

func _create_action_btn(text: String, mode: String, parent: Node) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.toggle_mode = true
	btn.custom_minimum_size = Vector2(120, 50)
	btn.pressed.connect(func(): _on_action_btn_pressed(mode))
	parent.add_child(btn)
	return btn

func _on_action_btn_pressed(mode: String):
	set_active_mode(mode)
	action_mode_changed.emit(mode)

func _on_toggle_states_pressed():
	var is_active = btn_toggle_states.button_pressed
	UnitUI.toggle_global_display(is_active)
	btn_toggle_states.text = "Hide States" if is_active else "Show States"

func set_active_mode(mode: String):
	btn_basic.set_pressed_no_signal(mode == "BASIC")
	btn_adv.set_pressed_no_signal(mode == "ADVANCED")
	btn_ult.set_pressed_no_signal(mode == "ULTIMATE")

var _current_inspected_unit: Unit

func update_stats(unit):
	_current_inspected_unit = unit
	
	if not unit:
		lbl_name.text = "Select a Unit"
		bar_hp.value = 0
		lbl_hp_text.text = ""
		bar_qi.value = 0
		lbl_qi_text.text = ""
		btn_details.disabled = true
		
		btn_passive.tooltip_text = ""
		btn_basic.tooltip_text = ""
		btn_adv.tooltip_text = ""
		btn_ult.tooltip_text = ""
		return
	
	btn_details.disabled = false
	var hero_name = unit.get_meta("hero_id", "Unknown Unit")
	lbl_name.text = "%s\n[%s]" % [hero_name, unit.unit_class]
	
	bar_hp.max_value = unit.max_hp
	bar_hp.value = unit.current_hp
	lbl_hp_text.text = "%d / %d" % [unit.current_hp, unit.max_hp]
	
	bar_qi.max_value = unit.max_qi
	bar_qi.value = unit.current_qi
	lbl_qi_text.text = "%d / %d" % [unit.current_qi, unit.max_qi]
	
	_update_btn_tooltip(btn_basic, unit, "BASIC")
	_update_btn_tooltip(btn_adv, unit, "ADVANCED")
	_update_btn_tooltip(btn_ult, unit, "ULTIMATE")
	_update_btn_tooltip(btn_passive, unit, "PASSIVE")

func _update_btn_tooltip(btn: Button, unit: Unit, type: String):
	var info = unit.get_skill_info(type)
	btn.tooltip_text = "%s\n\n%s\n\nEffect: %s" % [info.name, info.desc, info.math]

func _on_details_pressed():
	if not _current_inspected_unit: return
	
	var u = _current_inspected_unit
	var text = "[b]Name:[/b] %s\n" % u.name
	text += "[b]Class:[/b] %s\n\n" % u.unit_class
	
	text += "[b]--- Stats ---[/b]\n"
	text += "HP: %d / %d\n" % [u.current_hp, u.max_hp]
	text += "Qi: %d / %d\n" % [u.current_qi, u.max_qi]
	text += "Attack: %d\n" % u.attack_power
	text += "Initiative: %d\n\n" % u.initiative
	
	text += "[b]--- Resistances ---[/b]\n"
	for k in u.resist:
		text += "%s: %d%%\n" % [k.capitalize(), u.resist[k]]
		
	lbl_details_content.text = text
	popup_details.popup_centered()

func log_message(msg: String):
	if log_box:
		log_box.text += msg + "\n"
		log_box.scroll_vertical = log_box.get_line_count()

func update_turn_queue(units_queue: Array, active_unit: Unit):
	for child in hbox_turn_queue.get_children():
		child.queue_free()
	
	for unit in units_queue:
		if not is_instance_valid(unit) or unit.current_hp <= 0: continue
		
		var is_active = (unit == active_unit)
		var panel = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.6)
		style.border_width_bottom = 4
		
		if unit.player_id == "PLAYER":
			style.border_color = Color(0.2, 0.4, 0.8) 
		else:
			style.border_color = Color(0.8, 0.2, 0.2) 
		
		if is_active:
			style.border_color = style.border_color.lightened(0.5)
			style.border_width_top = 4
			style.border_width_left = 4
			style.border_width_right = 4
			panel.scale = Vector2(1.2, 1.2)
		else:
			panel.modulate = Color(0.7, 0.7, 0.7, 0.8)
			
		panel.add_theme_stylebox_override("panel", style)
		
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(50, 50)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var sprite = unit.get_node_or_null("Sprite2D")
		if sprite and sprite.texture:
			icon.texture = sprite.texture
			
		panel.add_child(icon)
		
		var lbl_init = Label.new()
		lbl_init.text = str(unit.initiative)
		lbl_init.add_theme_font_size_override("font_size", 12)
		lbl_init.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		panel.add_child(lbl_init)
		hbox_turn_queue.add_child(panel)
