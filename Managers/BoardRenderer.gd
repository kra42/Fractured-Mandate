class_name BoardRenderer
extends Node2D

const COLOR_PAPER = Color("f4f1ea") 
const COLOR_INK = Color(0.15, 0.15, 0.15, 0.8) 
const COLOR_WASH_BLUE = Color(0.2, 0.3, 0.6, 0.15)
const COLOR_WASH_RED = Color(0.7, 0.2, 0.2, 0.15)
const COLOR_WASH_GREEN = Color(0.3, 0.6, 0.3, 0.3)

var cols: int = 12
var rows: int = 4
var zone_cols: int = 3
var zone_rows: int = 4

var tile_size: float = 128.0
var board_offset: Vector2 = Vector2.ZERO
var background_texture: Texture2D

# Highlight State
var selected_unit_pos: Vector2i = Vector2i(-1, -1)
var move_highlights: Array[Vector2i] = []
var attack_highlights: Array[Vector2i] = []

func setup(c: int, r: int, z_c: int, z_r: int):
	cols = c
	rows = r
	zone_cols = z_c
	zone_rows = z_r

func update_layout(t_size: float, offset: Vector2):
	tile_size = t_size
	board_offset = offset
	queue_redraw()

func set_highlights(selected: Vector2i, moves: Array[Vector2i], attacks: Array[Vector2i]):
	selected_unit_pos = selected
	move_highlights = moves
	attack_highlights = attacks
	queue_redraw()

func _draw():
	var viewport_rect = get_viewport_rect()
	
	# 1. Background
	if background_texture:
		draw_texture_rect(background_texture, viewport_rect, false)
	else:
		draw_rect(viewport_rect, COLOR_PAPER)
		_draw_paper_grain(viewport_rect)
	
	# 2. Zones
	# Player Zone
	var p1_rect = Rect2(board_offset.x, board_offset.y, zone_cols * tile_size, zone_rows * tile_size)
	draw_rect(p1_rect, COLOR_WASH_BLUE)
	
	# Enemy Zone
	var p2_start_x = (cols - zone_cols) * tile_size + board_offset.x
	var p2_rect = Rect2(p2_start_x, board_offset.y, zone_cols * tile_size, zone_rows * tile_size)
	draw_rect(p2_rect, COLOR_WASH_RED)

	# 3. Grid Lines
	for x in range(cols + 1):
		var start = Vector2(x * tile_size, 0) + board_offset
		var end = Vector2(x * tile_size, rows * tile_size) + board_offset
		draw_line(start, end, COLOR_INK, 2.0)
		
	for y in range(rows + 1):
		var start = Vector2(0, y * tile_size) + board_offset
		var end = Vector2(cols * tile_size, y * tile_size) + board_offset
		draw_line(start, end, COLOR_INK, 2.0)

	# 4. Highlights
	if selected_unit_pos != Vector2i(-1, -1):
		var rect_pos = (Vector2(selected_unit_pos) * tile_size) + board_offset
		draw_rect(Rect2(rect_pos, Vector2(tile_size, tile_size)), COLOR_WASH_GREEN)
		draw_rect(Rect2(rect_pos, Vector2(tile_size, tile_size)), COLOR_INK, false, 4.0)
		
		for move in move_highlights:
			draw_rect(Rect2((Vector2(move) * tile_size) + board_offset, Vector2(tile_size, tile_size)), COLOR_WASH_BLUE)
			
		for attack in attack_highlights:
			draw_rect(Rect2((Vector2(attack) * tile_size) + board_offset, Vector2(tile_size, tile_size)), COLOR_WASH_RED)

func _draw_paper_grain(rect: Rect2):
	var rng = RandomNumberGenerator.new()
	rng.seed = 1234
	for i in range(500):
		var x = rng.randf_range(rect.position.x, rect.end.x)
		var y = rng.randf_range(rect.position.y, rect.end.y)
		draw_circle(Vector2(x, y), 1.0, Color(0,0,0, rng.randf_range(0.05, 0.1)))
