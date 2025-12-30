extends CharacterBody2D
class_name Enemy

signal turn_finished
signal hp_changed(current_hp: int, max_hp: int)
signal died

# ---------- STATS ----------
@export var speed := 50.0
@export var max_ap := 6
@export var max_hp := 10
@export var move_range := 4

@export var attack_data: EnemyAttack

@export_range(0.0, 1.0) var wait_chance := 0.5
# 0.0 — всегда идет
# 1.0 — всегда ждет, если уже достает атакой

var attack_cooldown := 0

var ap := 0
var hp := 10

var stun_turns := 0
var is_turn_active := false


@onready var grid = get_parent().get_parent()
@onready var cell_size := Vector2(grid.cell_size)

@onready var hp_num_label: Label = $UI/HpNumLabel


var current_cell: Vector2i
var path: Array[Vector2i] = []
var path_index := 0
var target_player


# ---------- READY ----------
func _ready() -> void:
	add_to_group("enemy")

	current_cell = world_to_cell(global_position)
	global_position = cell_to_world(current_cell)

	hp = max_hp
	hp_num_label.text = str(hp)
	emit_hp()


# ---------- TURN ----------
func start_turn() -> void:
	is_turn_active = true

	if stun_turns > 0:
		stun_turns -= 1
		print("ENEMY STUNNED, turns left:", stun_turns)
		call_deferred("_finish_stunned_turn")
		return

	ap = max_ap

	if attack_cooldown > 0:
		attack_cooldown -= 1

	target_player = get_tree().get_first_node_in_group("player")
	if not target_player:
		end_turn()
		return

	if can_attack():
		perform_attack()
		end_turn()
		return

	if is_in_attack_range():
		if randf() < wait_chance:
			end_turn()
			return

	calc_path()

# 🔥 КРИТИЧЕСКИЙ ФИКС
	if path.is_empty():
		end_turn()




func end_turn() -> void:
	if not is_turn_active:
		return

	is_turn_active = false
	path.clear()
	path_index = 0
	velocity = Vector2.ZERO
	turn_finished.emit()


# ---------- ATTACK ----------
func can_attack() -> bool:
	if not attack_data:
		return false

	if attack_cooldown > 0:
		return false

	if ap < attack_data.ap_cost:
		return false

	var dist := current_cell.distance_to(target_player.current_cell)
	if dist > attack_data.range:
		return false

	# 🔥 ВАЖНОЕ МЕСТО
	return has_line_of_sight(current_cell, target_player.current_cell)


func is_in_attack_range() -> bool:
	if not attack_data:
		return false

	var dist := current_cell.distance_to(target_player.current_cell)
	if dist > attack_data.range:
		return false

	return has_line_of_sight(current_cell, target_player.current_cell)


func perform_attack() -> void:
	ap -= attack_data.ap_cost
	attack_cooldown = attack_data.cooldown

	match attack_data.type:
		EnemyAttack.AttackType.DAMAGE:
			target_player.take_damage(attack_data.damage)

		EnemyAttack.AttackType.STUN:
			target_player.apply_stun(attack_data.stun_turns)

	print(
		"Enemy uses",
		attack_data.name,
		"on player"
	)


# ---------- PATH ----------
func calc_path() -> void:
	var player_cell = target_player.current_cell

	var units := []
	units.append(target_player)
	units.append_array(get_tree().get_nodes_in_group("enemy"))

	grid.rebuild_unit_blocks(units, self)

	var targets: Array[Vector2i] = []
	var dirs = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]

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

	var max_steps = min(ap, move_range)
	path = best_path.slice(1, min(best_path.size(), max_steps + 1))
	path_index = 0


# ---------- PHYSICS ----------
func _physics_process(_delta: float) -> void:
	if is_stunned():
		velocity = Vector2.ZERO
		return

	
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
		ap -= 1
		global_position = next_pos
		current_cell = next_cell
		path_index += 1

		if ap <= 0:
			end_turn()


# ---------- HP ----------
func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	hp_num_label.text = str(hp)
	emit_hp()

	if hp <= 0:
		hp = 0
		die()


func emit_hp() -> void:
	hp_changed.emit(hp, max_hp)


func die() -> void:
	print("ENEMY DIED")

	var grid := get_tree().get_first_node_in_group("grid")
	if grid:
		grid.set_unit_blocked(current_cell, false)

	died.emit()
	queue_free()


# ---------- HELPERS ----------
func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / cell_size.x),
		floor(pos.y / cell_size.y)
	)


func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size


func is_stunned() -> bool:
	return stun_turns > 0

func apply_stun(turns: int) -> void:
	stun_turns = max(stun_turns, turns)
	print(name, "STUNNED FOR", stun_turns, "TURNS")

func _finish_stunned_turn() -> void:
	if not is_turn_active:
		return

	is_turn_active = false
	turn_finished.emit()


func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	var line = grid.get_line_cells(from, to) # см. ниже

	for cell in line:
		if cell == from or cell == to:
			continue
		if grid.astar_grid.is_point_solid(cell):
			return false

	return true
