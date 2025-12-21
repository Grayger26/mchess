extends Node2D
class_name Grid

@export var cell_size : Vector2i = Vector2i(16, 16)
@export var rect_size : Vector2i = Vector2i(15, 15)

var static_obstacles := {}


@onready var obstacles: TileMapLayer = $Tilemaps/obstacles

var astar_grid := AStarGrid2D.new()
var grid_size : Vector2i

# ---------- HIGHLIGHT ----------
var highlighted_cells : Array[Vector2i] = []
var highlight_color : Color = Color(0.2, 0.8, 1.0, 0.35)

# ---------- PREVIEW PATH ----------
var preview_path : Array[Vector2i] = []
var preview_color : Color = Color(0.2, 0.8, 1.0, 0.667)
var preview_width : float = 1.2


# ---------- READY ----------

func _ready() -> void:
	initialize_grid()
	update_obstacles()


# ---------- GRID INIT ----------

func initialize_grid() -> void:
	grid_size = Vector2i(get_viewport_rect().size) / cell_size

	astar_grid.size = grid_size
	astar_grid.cell_size = cell_size
	astar_grid.offset = cell_size / 2
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()


func update_obstacles() -> void:
	if not obstacles:
		return

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
			var dist: int = abs(x) + abs(y)
			if dist == 0 or dist > range:
				continue

			var cell := from + Vector2i(x, y)

			if not is_cell_inside_grid(cell):
				continue
			if astar_grid.is_point_solid(cell):
				continue
			if not has_line_of_sight(from, cell):
				continue

			result.append(cell)

	return result


func get_self_cell(from: Vector2i) -> Array[Vector2i]:
	return [from]


# ---------- LINE OF SIGHT ----------

func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y

	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)

	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1

	var err = dx - dy

	while true:
		var cell := Vector2i(x0, y0)

		if cell != from and astar_grid.is_point_solid(cell):
			return false

		if x0 == x1 and y0 == y1:
			break

		var e2 = err * 2

		if e2 > -dy:
			err -= dy
			x0 += sx

		if e2 < dx:
			err += dx
			y0 += sy

	return true


# ---------- PREVIEW PATH ----------

func set_preview_path(path: Array[Vector2i]) -> void:
	preview_path = path
	queue_redraw()

func clear_preview_path() -> void:
	preview_path.clear()
	queue_redraw()


# ---------- HIGHLIGHT ----------

func set_highlighted_cells(
	cells : Array[Vector2i],
	color : Color = Color(0.2, 0.8, 1.0, 0.35)
) -> void:
	highlighted_cells = cells
	highlight_color = color
	queue_redraw()


# алиас — чтобы ничего нигде не падало
func hide_highlight() -> void:
	highlighted_cells.clear()
	queue_redraw()

func clear_highlight() -> void:
	hide_highlight()

func get_highlighted_cells() -> Array[Vector2i]:
	return highlighted_cells


# ---------- HELPERS ----------

func is_cell_inside_grid(cell: Vector2i) -> bool:
	return (
		cell.x >= 0 and cell.x < grid_size.x
		and cell.y >= 0 and cell.y < grid_size.y
	)


# ---------- DRAW ----------

func _draw() -> void:
	draw_highlight()
	draw_preview_path()

func draw_highlight() -> void:
	for cell in highlighted_cells:
		var pos := Vector2(cell) * Vector2(cell_size)
		draw_rect(
			Rect2(pos, Vector2(rect_size)),
			highlight_color,
			true
		)

func draw_preview_path() -> void:
	if preview_path.size() < 2:
		return

	var points := PackedVector2Array()

	for cell in preview_path:
		var p := Vector2(cell) * Vector2(cell_size) + Vector2(cell_size) * 0.5
		points.append(p)

	draw_polyline(points, preview_color, preview_width, true)


# ---------- DYNAMIC BLOCKS (UNITS) ----------

func set_unit_blocked(cell: Vector2i, blocked: bool) -> void:
	if not is_cell_inside_grid(cell):
		return
	astar_grid.set_point_solid(cell, blocked)


func rebuild_unit_blocks(units: Array, ignore_unit) -> void:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var cell := Vector2i(x, y)

			# стены остаются solid
			if is_static_obstacle(cell):
				astar_grid.set_point_solid(cell, true)
			else:
				astar_grid.set_point_solid(cell, false)

	# блокируем клетки юнитов
	for u in units:
		if u == ignore_unit:
			continue
		astar_grid.set_point_solid(u.current_cell, true)



func is_static_obstacle(cell: Vector2i) -> bool:
	return obstacles.get_cell_source_id(cell) != -1


func build_static_obstacles(blocked_cells: Array[Vector2i]) -> void:
	static_obstacles.clear()
	for cell in blocked_cells:
		static_obstacles[cell] = true
		astar_grid.set_point_solid(cell, true)

func get_cells_in_range_for_ability(
	from: Vector2i,
	range: int
) -> Array[Vector2i]:

	var result: Array[Vector2i] = []

	for x in range(-range, range + 1):
		for y in range(-range, range + 1):
			var dist = abs(x) + abs(y)
			if dist == 0 or dist > range:
				continue

			var cell := from + Vector2i(x, y)

			if not is_cell_inside_grid(cell):
				continue

			# ✅ ПРОВЕРЯЕМ ЛИНИЮ ВИДИМОСТИ (СТЕНЫ)
			if not has_line_of_sight_static(from, cell):
				continue

			result.append(cell)

	return result

func has_line_of_sight_static(from: Vector2i, to: Vector2i) -> bool:
	var x0 := from.x
	var y0 := from.y
	var x1 := to.x
	var y1 := to.y

	var dx = abs(x1 - x0)
	var dy = abs(y1 - y0)

	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1

	var err = dx - dy

	while true:
		var cell := Vector2i(x0, y0)

		if cell != from and is_static_obstacle(cell):
			return false

		if x0 == x1 and y0 == y1:
			break

		var e2 = err * 2
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return true
