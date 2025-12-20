extends CharacterBody2D
class_name Player

# ---------- SIGNALS ----------
signal turn_finished
signal ap_changed(current_ap: int, max_ap: int)

# ---------- STATS ----------
@export var speed := 50.0
@export var move_range := 2
@export var max_ap := 10
var ap := 10

# ---------- REFERENCES ----------
@onready var grid = get_parent()
@onready var cell_size: Vector2 = Vector2(grid.cell_size)
@onready var abilities: AbilityComponent = $AbilityComponent
@onready var ability_bar := get_tree().get_first_node_in_group("ability_bar")

# ---------- STATE ----------
enum PlayerState { MOVE, TARGETING, CASTING }
var state := PlayerState.MOVE

var current_cell: Vector2i
var path: Array[Vector2i] = []
var path_index := 0

var last_hovered_cell := Vector2i(-999, -999)

# ---------- READY ----------
func _ready() -> void:
	add_to_group("player")

	current_cell = world_to_cell(global_position)
	global_position = cell_to_world(current_cell)

	emit_ap()

	if ability_bar:
		ability_bar.ability_slot_toggled.connect(_on_ability_slot_toggled)

# ---------- TURN ----------
func start_turn() -> void:
	ap = max_ap
	emit_ap()
	state = PlayerState.MOVE
	update_highlight()

func end_turn() -> void:
	state = PlayerState.MOVE
	path.clear()
	path_index = 0
	velocity = Vector2.ZERO
	grid.clear_preview_path()
	grid.hide_highlight()
	
	if ability_bar:
		ability_bar.cancel_all_buttons()
	
	turn_finished.emit()

# ---------- INPUT ----------
func _input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if not path.is_empty():
		return

	var clicked_cell := world_to_cell(event.position)

	match state:
		PlayerState.MOVE:
			if clicked_cell in get_legal_moves(current_cell):
				grid.clear_preview_path()
				grid.hide_highlight()
				request_path(clicked_cell)

		PlayerState.TARGETING:
			if clicked_cell in get_ability_targets():
				cast_ability(clicked_cell)

# ---------- PROCESS ----------
func _process(_delta: float) -> void:
	update_move_preview()

# ---------- PHYSICS ----------
func _physics_process(_delta: float) -> void:
	if path.is_empty():
		velocity = Vector2.ZERO
		return

	if path_index >= path.size():
		finish_movement()
		return

	var next_cell := path[path_index]
	var next_pos := cell_to_world(next_cell)

	velocity = global_position.direction_to(next_pos) * speed
	move_and_slide()

	if global_position.distance_to(next_pos) < 1.0:
		if ap <= 0:
			finish_movement()
			return

		ap -= 1
		emit_ap()

		global_position = next_pos
		current_cell = next_cell
		path_index += 1

		if ap == 0:
			finish_movement()
			end_turn()

func finish_movement() -> void:
	path.clear()
	path_index = 0
	velocity = Vector2.ZERO
	grid.clear_preview_path()
	update_highlight()

# ---------- AP ----------
func emit_ap() -> void:
	ap_changed.emit(ap, max_ap)

# ---------- PATH ----------
func request_path(target_cell: Vector2i) -> void:
	var units := []
	units.append_array(get_tree().get_nodes_in_group("enemy"))
	units.append(self)

	# блокируем всех, кроме себя
	grid.rebuild_unit_blocks(units, self)

	var new_path = grid.get_grid_path(current_cell, target_cell)

	if new_path.is_empty():
		return

	var cost = new_path.size() - 1
	if cost > ap:
		return

	path = new_path.slice(1)
	path_index = 0



# ---------- PREVIEW ----------
func update_move_preview() -> void:
	if state != PlayerState.MOVE:
		grid.clear_preview_path()
		return
	
	if not path.is_empty():
		grid.clear_preview_path()
		return

	var mouse_cell := world_to_cell(get_global_mouse_position())
	if mouse_cell == last_hovered_cell:
		return
	last_hovered_cell = mouse_cell

	if mouse_cell not in get_legal_moves(current_cell):
		grid.clear_preview_path()
		return

	var preview = grid.get_grid_path(current_cell, mouse_cell)
	if preview.is_empty():
		return

	var cost = preview.size() - 1
	if cost > ap:
		grid.clear_preview_path()
		return

	grid.set_preview_path(preview)

# ---------- ABILITIES ----------

func activate_ability(ability: AbilityData) -> void:
	if state == PlayerState.TARGETING:
		abilities.activate(ability)
		show_ability_range()
		return

	if state != PlayerState.MOVE:
		return

	abilities.activate(ability)
	state = PlayerState.TARGETING
	grid.clear_preview_path()
	grid.hide_highlight()
	show_ability_range()


func cancel_ability() -> void:
	abilities.clear()
	state = PlayerState.MOVE
	update_highlight()
	
	if ability_bar:
		ability_bar.cancel_all_buttons()


func cast_ability(target_cell: Vector2i) -> void:
	state = PlayerState.CASTING

	print("CAST:", abilities.active_ability.name, "on", target_cell)

	# TODO: damage / heal / cooldown / ap cost

	abilities.clear()
	
	if ability_bar:
		ability_bar.cancel_all_buttons()
	
	state = PlayerState.MOVE
	update_highlight()


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

# ---------- LEGAL MOVES ----------
func get_legal_moves(from: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var visited := {}
	var queue := []

	queue.append({ "cell": from, "dist": 0 })
	visited[from] = true

	var dirs = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]

	while not queue.is_empty():
		var item = queue.pop_front()
		var cell: Vector2i = item.cell
		var dist: int = item.dist

		if dist > move_range or dist > ap:
			continue

		if cell != from:
			result.append(cell)

		for d in dirs:
			var next = cell + d
			if visited.has(next):
				continue
			if grid.astar_grid.is_point_solid(next):
				continue

			visited[next] = true
			queue.append({ "cell": next, "dist": dist + 1 })

	return result

func update_highlight() -> void:
	if state == PlayerState.MOVE:
		grid.set_highlighted_cells(get_legal_moves(current_cell))

# ---------- HELPERS ----------
func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / cell_size.x), floor(pos.y / cell_size.y))

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size

# ---------- UI ----------
func _on_ability_slot_toggled(slot: String, enabled: bool) -> void:
	if enabled:
		var ability := abilities.get_ability_by_slot(slot)
		if ability:
			activate_ability(ability)
	else:
		if state == PlayerState.TARGETING:
			cancel_ability()
