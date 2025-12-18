extends Node2D

@export var cell_size : Vector2i = Vector2i(16, 16)
@export var rect_size : Vector2i = Vector2i(15, 15)

@onready var obstacles: TileMapLayer = $Tilemaps/obstacles

var astar_grid := AStarGrid2D.new()
var grid_size : Vector2i
var highlighted_cells : Array[Vector2i] = []
var highlight_color : Color = Color(0.2, 0.8, 1.0, 0.35)  # Default blue


func _ready() -> void:
	initialize_grid()
	update_obstacles()


func initialize_grid() -> void:
	grid_size = Vector2i(get_viewport_rect().size) / cell_size
	astar_grid.size = grid_size
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()


func update_obstacles() -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell := Vector2i(x, y)
			var blocked := obstacles.get_cell_source_id(cell) != -1
			astar_grid.set_point_solid(cell, blocked)


# ---------- PATH ----------

func get_grid_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	if astar_grid.is_point_solid(to):
		return []
	return astar_grid.get_id_path(from, to)


# ---------- RANGE ----------

func get_cells_in_range(from: Vector2i, range: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	
	for x in range(-range, range + 1):
		for y in range(-range, range + 1):
			var distance = abs(x) + abs(y)
			if distance <= range and distance > 0:
				var cell = from + Vector2i(x, y)
				# Check if cell is within grid bounds
				if cell.x >= 0 and cell.x < grid_size.x and cell.y >= 0 and cell.y < grid_size.y:
					# Only add cells that are not blocked
					if not astar_grid.is_point_solid(cell):
						result.append(cell)
	
	return result


func get_self_cell(from: Vector2i) -> Array[Vector2i]:
	return [from]


# ---------- HIGHLIGHT ----------

func set_highlighted_cells(cells : Array[Vector2i], color: Color = Color(0.2, 0.8, 1.0, 0.35)) -> void:
	highlighted_cells = cells
	highlight_color = color
	queue_redraw()


func _draw() -> void:
	draw_highlight()


func draw_highlight() -> void:
	for cell in highlighted_cells:
		var pos = Vector2(cell) * Vector2(cell_size)
		draw_rect(
			Rect2(pos, Vector2(rect_size)),
			highlight_color,
			true
		)


func hide_highlight() -> void:
	highlighted_cells.clear()
	highlight_color = Color(0.2, 0.8, 1.0, 0.35)  # Reset to default
	queue_redraw()
