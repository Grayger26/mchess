extends CharacterBody2D
class_name Enemy

signal turn_finished

@export var speed := 50.0
@export var max_ap := 6
var ap := 0

@onready var grid = get_parent().get_parent()
@onready var cell_size := Vector2(grid.cell_size)

var current_cell: Vector2i
var path: Array[Vector2i] = []
var path_index := 0
var target_player

func _ready() -> void:
	add_to_group("enemy")
	current_cell = world_to_cell(global_position)
	global_position = cell_to_world(current_cell)

# ---------- TURN ----------
func start_turn() -> void:
	ap = max_ap
	target_player = get_tree().get_first_node_in_group("player")

	if not target_player:
		end_turn()
		return

	calc_path()

func end_turn() -> void:
	path.clear()
	path_index = 0
	velocity = Vector2.ZERO
	turn_finished.emit()

# ---------- PATH ----------
func calc_path() -> void:
	var player_cell = target_player.current_cell

	var units := []
	units.append(target_player)
	units.append_array(get_tree().get_nodes_in_group("enemy"))

	grid.rebuild_unit_blocks(units, self)

	# ищем свободные клетки рядом с игроком
	var targets: Array[Vector2i] = []
	var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	for d in dirs:
		var cell = player_cell + d
		if not grid.is_cell_inside_grid(cell):
			continue
		if grid.astar_grid.is_point_solid(cell):
			continue
		targets.append(cell)

	if targets.is_empty():
		end_turn()
		return

	# выбираем ближайшую
	var best_path: Array[Vector2i] = []

	for t in targets:
		var p = grid.get_grid_path(current_cell, t)
		if p.is_empty():
			continue
		if best_path.is_empty() or p.size() < best_path.size():
			best_path = p

	if best_path.is_empty():
		end_turn()
		return

	path = best_path.slice(1, min(best_path.size(), ap + 1))
	path_index = 0



# ---------- PHYSICS ----------
func _physics_process(_delta: float) -> void:
	if path.is_empty():
		return

	if path_index >= path.size():
		end_turn()
		return

	var next_cell := path[path_index]
	var next_pos := cell_to_world(next_cell)

	velocity = global_position.direction_to(next_pos) * speed
	move_and_slide()

	if global_position.distance_to(next_pos) < 1.0:
		if ap <= 0:
			end_turn()
			return

		ap -= 1
		global_position = next_pos
		current_cell = next_cell
		path_index += 1

# ---------- HELPERS ----------
func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / cell_size.x), floor(pos.y / cell_size.y))

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size
