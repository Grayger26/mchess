extends CharacterBody2D

@export var speed := 50.0
@export var move_range := 2

@onready var grid = get_parent()
@onready var cell_size : Vector2 = Vector2(grid.cell_size)
@onready var obstacles: TileMapLayer = $"../Tilemaps/obstacles"
var is_active : bool = true


var current_cell : Vector2i
var path : Array[Vector2i] = []
var path_index := 0


func _ready() -> void:
	current_cell = world_to_cell(global_position)
	global_position = cell_to_world(current_cell)
	update_highlight()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed and is_active:

		var clicked_cell = world_to_cell(event.position)

		if clicked_cell in get_legal_moves(current_cell):
			is_active = false
			request_path(clicked_cell)


func _physics_process(delta: float) -> void:
	if path.is_empty():
		velocity = Vector2.ZERO
		return

	if path_index >= path.size():
		path.clear()
		path_index = 0
		velocity = Vector2.ZERO
		return

	var next_cell = path[path_index]
	var next_pos = cell_to_world(next_cell)

	velocity = global_position.direction_to(next_pos) * speed
	move_and_slide()

	if global_position.distance_to(next_pos) < 1.0:
		global_position = next_pos
		current_cell = next_cell
		path_index += 1

		# ✅ ПРИБЫЛИ В КОНЕЧНУЮ КЛЕТКУ — ОБНОВЛЯЕМ ПОДСВЕТКУ
		if path_index >= path.size():
			is_active = true
			update_highlight()



# ---------- PATH ----------

func request_path(target_cell: Vector2i) -> void:
	path = grid.get_grid_path(current_cell, target_cell)
	path_index = 0



# ---------- LEGAL MOVES (BFS) ----------

func get_legal_moves(from: Vector2i) -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	var visited := {}
	var queue := []

	queue.append({ "cell": from, "dist": 0 })
	visited[from] = true

	var directions = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

	while queue.size() > 0:
		var item = queue.pop_front()
		var cell : Vector2i = item.cell
		var dist : int = item.dist

		if dist > move_range:
			continue

		if cell != from:
			result.append(cell)

		for dir in directions:
			var next_cell = cell + dir
			if visited.has(next_cell):
				continue
			if grid.astar_grid.is_point_solid(next_cell):
				continue

			visited[next_cell] = true
			queue.append({ "cell": next_cell, "dist": dist + 1 })

	return result


func update_highlight() -> void:
	grid.set_highlighted_cells(get_legal_moves(current_cell))


# ---------- HELPERS ----------

func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / cell_size.x),
		floor(pos.y / cell_size.y)
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size
