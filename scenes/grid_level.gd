extends Node2D

@export var cell_size : Vector2i = Vector2i(16, 16)
@export var rect_size : Vector2i = Vector2i(15, 15)
@onready var obstacles: TileMapLayer = $Tilemaps/obstacles

var astar_grid := AStarGrid2D.new()
var grid_size : Vector2i
var highlighted_cells : Array[Vector2i] = []


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


# ---------- HIGHLIGHT ----------

func set_highlighted_cells(cells : Array[Vector2i]) -> void:
	highlighted_cells = cells
	queue_redraw()


func _draw() -> void:
	draw_highlight()


func draw_highlight() -> void:
	for cell in highlighted_cells:
		var pos = Vector2(cell) * Vector2(cell_size)
		draw_rect(
			Rect2(pos, Vector2(rect_size)),
			Color(0.2, 0.8, 1.0, 0.35),
			true
		)
