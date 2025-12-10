class_name GridManager
extends Node

const COLS = 12
const ROWS = 4

var grid: Dictionary = {}
var tile_size: float = 128.0 # Default, updated by GameBoard
var board_offset: Vector2 = Vector2.ZERO

func clear():
	grid.clear()

func add_unit(unit: Unit):
	grid[unit.grid_pos] = unit

func remove_unit(unit: Unit):
	if grid.has(unit.grid_pos) and grid[unit.grid_pos] == unit:
		grid.erase(unit.grid_pos)

func move_unit(unit: Unit, target_pos: Vector2i):
	if grid.has(unit.grid_pos) and grid[unit.grid_pos] == unit:
		grid.erase(unit.grid_pos)
	
	unit.grid_pos = target_pos
	grid[target_pos] = unit

func swap_units(unit_a: Unit, unit_b: Unit):
	var pos_a = unit_a.grid_pos
	var pos_b = unit_b.grid_pos
	
	grid[pos_a] = unit_b
	grid[pos_b] = unit_a
	
	unit_a.grid_pos = pos_b
	unit_b.grid_pos = pos_a

func get_unit_at(pos: Vector2i) -> Unit:
	return grid.get(pos, null)

func is_occupied(pos: Vector2i) -> bool:
	return grid.has(pos)

func get_all_units() -> Array:
	var units = []
	for pos in grid:
		units.append(grid[pos])
	return units

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var local = world_pos - board_offset
	return Vector2i(local / tile_size)

func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size) + Vector2(tile_size/2.0, tile_size/2.0) + board_offset
