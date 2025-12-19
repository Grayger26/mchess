extends CharacterBody2D

@export var speed := 50.0
@export var move_range := 2

@onready var grid = get_parent()
@onready var cell_size : Vector2 = Vector2(grid.cell_size)
@onready var abilities: AbilityComponent = $AbilityComponent
@onready var ability_bar := get_tree().get_first_node_in_group("ability_bar")

enum PlayerState {
	MOVE,
	TARGETING,
	CASTING
}

var state : PlayerState = PlayerState.MOVE

var current_cell : Vector2i
var path : Array[Vector2i] = []
var path_index := 0


func _ready() -> void:
	current_cell = world_to_cell(global_position)
	global_position = cell_to_world(current_cell)
	enter_state(PlayerState.MOVE)

	if ability_bar:
		ability_bar.ability_slot_toggled.connect(_on_ability_slot_toggled)


func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return

	# 🚫 Запрещаем любой ввод, пока персонаж движется
	if not path.is_empty():
		return

	var clicked_cell = world_to_cell(event.position)

	match state:
		PlayerState.MOVE:
			if clicked_cell in get_legal_moves(current_cell):
				grid.hide_highlight()
				request_path(clicked_cell)

		PlayerState.TARGETING:
			if clicked_cell in get_ability_targets():
				cast_ability(clicked_cell)


func _physics_process(delta: float) -> void:
	if state != PlayerState.MOVE:
		return

	if path.is_empty():
		velocity = Vector2.ZERO
		return

	if path_index >= path.size():
		finish_movement()
		return

	var next_cell = path[path_index]
	var next_pos = cell_to_world(next_cell)

	velocity = global_position.direction_to(next_pos) * speed
	move_and_slide()

	if global_position.distance_to(next_pos) < 1.0:
		global_position = next_pos
		current_cell = next_cell
		path_index += 1


func finish_movement() -> void:
	path.clear()
	path_index = 0
	velocity = Vector2.ZERO
	enter_state(PlayerState.MOVE)


func enter_state(new_state: PlayerState) -> void:
	state = new_state

	match state:
		PlayerState.MOVE:
			update_highlight()

		PlayerState.TARGETING:
			grid.hide_highlight()
			show_ability_range()

		PlayerState.CASTING:
			grid.hide_highlight()


func activate_ability(ability: AbilityData) -> void:
	if state == PlayerState.TARGETING:
		abilities.activate(ability)
		show_ability_range()
		return

	if state != PlayerState.MOVE:
		return

	abilities.activate(ability)
	enter_state(PlayerState.TARGETING)


func cancel_ability() -> void:
	abilities.clear()
	enter_state(PlayerState.MOVE)
	if ability_bar:
		ability_bar.cancel_all_buttons()


func cast_ability(target_cell: Vector2i) -> void:
	enter_state(PlayerState.CASTING)

	print("CAST:", abilities.active_ability.name, "on", target_cell)

	abilities.clear()

	if ability_bar:
		ability_bar.cancel_all_buttons()

	enter_state(PlayerState.MOVE)


func show_ability_range() -> void:
	var ability := abilities.active_ability
	if not ability:
		return

	var cells: Array[Vector2i] = []
	var color := Color(1.0, 0.2, 0.2, 0.35)

	match ability.pattern:
		AbilityData.AbilityPattern.SELF:
			cells = grid.get_self_cell(current_cell)
			color = Color(0.2, 1.0, 0.2, 0.35)
		_:
			cells = grid.get_cells_in_range(current_cell, ability.range)

	grid.set_highlighted_cells(cells, color)


func get_ability_targets() -> Array[Vector2i]:
	return grid.highlighted_cells


func is_valid_ability_target(cell: Vector2i) -> bool:
	var ability := abilities.active_ability
	if not ability:
		return false

	if grid.astar_grid.is_point_solid(cell):
		return false

	return true


func request_path(target_cell: Vector2i) -> void:
	path = grid.get_grid_path(current_cell, target_cell)
	path_index = 0


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


func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / cell_size.x),
		floor(pos.y / cell_size.y)
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size


func _on_ability_slot_toggled(slot: String, enabled: bool) -> void:
	if enabled:
		var ability := abilities.get_ability_by_slot(slot)
		if ability:
			activate_ability(ability)
	else:
		if state == PlayerState.TARGETING:
			cancel_ability()
