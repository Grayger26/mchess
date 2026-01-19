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

var attack_cooldown := 0

var ap := 0
var hp := 10

const MAX_SHIELDS := 2
var shields := 0

@onready var shields_container: HBoxContainer = $UI/shields

var stun_turns := 0
var is_turn_active := false

@onready var grid = get_parent().get_parent()
@onready var cell_size := Vector2(grid.cell_size)

@onready var hp_num_label: Label = $UI/HpNumLabel

@onready var ui: Control = $UI
@onready var ui_timer: Timer = $UI/AutoHideTimer

@onready var chains_sprite: AnimatedSprite2D = $ChainsSprite

var mouse_over := false

var current_cell: Vector2i
var path: Array[Vector2i] = []
var path_index := 0
var target_player

# ---------- READY ----------
func _ready() -> void:
	ui.visible = false
	chains_sprite.visible = false
	add_to_group("enemy")

	current_cell = world_to_cell(global_position)
	global_position = cell_to_world(current_cell)

	hp = max_hp
	hp_num_label.text = str(hp)
	emit_hp()

# ---------- TURN ----------
func start_turn() -> void:
	if is_turn_active:
		return

	is_turn_active = true

	# STUN
	if stun_turns > 0:
		stun_turns -= 1
		print(name, "STUNNED, turns left:", stun_turns)

		if stun_turns == 0:
			_hide_stun()

		call_deferred("end_turn")
		return

	# Normal turn
	ap = max_ap

	if attack_cooldown > 0:
		attack_cooldown -= 1

	target_player = get_tree().get_first_node_in_group("player")
	if not target_player:
		end_turn()
		return

	# Priority 1: SHIELD (if available and targets exist)
	if attack_data and attack_data.type == EnemyAttack.AttackType.SHIELD:
		var shield_targets = get_shield_targets()
		if not shield_targets.is_empty():
			perform_shield(shield_targets)
			# After shield, try to move or end turn
			_try_move_after_action()
			return

	# Priority 2: HEAL (if available and targets exist)
	if attack_data and attack_data.type == EnemyAttack.AttackType.HEAL:
		var heal_targets = get_heal_targets()
		if not heal_targets.is_empty():
			perform_heal(heal_targets)
			# After heal, try to move or end turn
			_try_move_after_action()
			return

	# Priority 3: ATTACK player (if in range and off cooldown)
	if can_attack():
		print(name, " CAN ATTACK - attacking player!")
		perform_attack()
		# After attack, try to move or end turn
		_try_move_after_action()
		return
	else:
		print(name, " CANNOT ATTACK - reason check:")
		if not attack_data:
			print("  - No attack_data")
		elif attack_data.type == EnemyAttack.AttackType.HEAL or attack_data.type == EnemyAttack.AttackType.SHIELD:
			print("  - Attack type is HEAL/SHIELD")
		elif attack_cooldown > 0:
			print("  - On cooldown:", attack_cooldown)
		elif ap < attack_data.ap_cost:
			print("  - Not enough AP:", ap, "/", attack_data.ap_cost)
		else:
			var dist := current_cell.distance_to(target_player.current_cell)
			if dist > attack_data.range:
				print("  - Out of range:", dist, ">", attack_data.range)
			elif not has_line_of_sight(current_cell, target_player.current_cell):
				print("  - No line of sight")
			else:
				print("  - Unknown reason")

	# Priority 4: MOVE (if can't attack yet)
	calc_path()

	if path.is_empty():
		# Can't move anywhere, just end turn
		end_turn()
		return

func _try_move_after_action() -> void:
	# After performing an action, check if we can still move
	if ap <= 0:
		end_turn()
		return

	# Try to move while keeping player/allies in range
	var moved := _try_tactical_move()
	
	if not moved:
		# If no tactical move, just end turn
		end_turn()

func _try_tactical_move() -> bool:
	# Calculate path towards player
	calc_path()
	
	if path.is_empty():
		return false
	
	# Move as much as we can with remaining AP
	var max_steps = min(ap, move_range, path.size())
	if max_steps > 0:
		path = path.slice(0, max_steps)
		path_index = 0
		return true
	
	return false

func end_turn() -> void:
	if not is_turn_active:
		return

	is_turn_active = false
	path.clear()
	path_index = 0
	velocity = Vector2.ZERO
	turn_finished.emit(self)

# ---------- ATTACK ----------
func can_attack() -> bool:
	if not attack_data:
		return false
	
	# Don't check for HEAL/SHIELD types here
	if attack_data.type == EnemyAttack.AttackType.HEAL:
		return false
	if attack_data.type == EnemyAttack.AttackType.SHIELD:
		return false

	if attack_cooldown > 0:
		return false

	if ap < attack_data.ap_cost:
		return false

	var dist := current_cell.distance_to(target_player.current_cell)
	if dist > attack_data.range:
		return false

	return has_line_of_sight(current_cell, target_player.current_cell)

func is_in_attack_range() -> bool:
	if not attack_data:
		return false

	var dist := current_cell.distance_to(target_player.current_cell)
	if dist > attack_data.range:
		return false

	return has_line_of_sight(current_cell, target_player.current_cell)

func perform_attack() -> void:
	if attack_data.type == EnemyAttack.AttackType.HEAL:
		push_error("perform_attack() called with HEAL ability!")
		return

	ap -= attack_data.ap_cost
	attack_cooldown = attack_data.cooldown

	match attack_data.type:
		EnemyAttack.AttackType.DAMAGE:
			target_player.take_damage(attack_data.damage)

		EnemyAttack.AttackType.STUN:
			target_player.apply_stun(attack_data.stun_turns)

	print("Enemy uses", attack_data.name, "on player")

# ---------- PATH ----------
func calc_path() -> void:
	var player_cell = target_player.current_cell

	var units := []
	units.append(target_player)
	units.append_array(get_tree().get_nodes_in_group("enemy"))

	grid.rebuild_unit_blocks(units, self)

	# Prioritize cardinal directions (up, down, left, right)
	var cardinal_dirs = [
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i.LEFT,
		Vector2i.RIGHT
	]
	
	var diagonal_dirs = [
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(1, 1)
	]

	var targets: Array[Vector2i] = []

	# First, try cardinal directions (better for melee attacks)
	for d in cardinal_dirs:
		var cell = player_cell + d
		if not grid.is_cell_inside_grid(cell):
			continue
		if grid.astar_grid.is_point_solid(cell):
			continue
		targets.append(cell)

	# If no cardinal spots available, try diagonals
	if targets.is_empty():
		for d in diagonal_dirs:
			var cell = player_cell + d
			if not grid.is_cell_inside_grid(cell):
				continue
			if grid.astar_grid.is_point_solid(cell):
				continue
			targets.append(cell)

	if targets.is_empty():
		# No adjacent cells available
		path.clear()
		return

	var best_path: Array[Vector2i] = []

	for t in targets:
		var p = grid.get_grid_path(current_cell, t)
		if p.is_empty():
			continue
		if best_path.is_empty() or p.size() < best_path.size():
			best_path = p

	if best_path.is_empty():
		path.clear()
		return

	var max_steps = min(ap, move_range)
	path = best_path.slice(1, min(best_path.size(), max_steps + 1))
	path_index = 0

# ---------- PHYSICS ----------
func _physics_process(_delta: float) -> void:
	if not is_turn_active:
		return
	
	if path.is_empty():
		return

	if path_index >= path.size():
		# Finished moving, check if we can attack now
		_check_attack_after_movement()
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

func _check_attack_after_movement() -> void:
	# After moving, see if we can now attack/heal/shield
	
	# Try SHIELD
	if attack_data and attack_data.type == EnemyAttack.AttackType.SHIELD:
		var shield_targets = get_shield_targets()
		if not shield_targets.is_empty():
			perform_shield(shield_targets)
			end_turn()
			return
	
	# Try HEAL
	if attack_data and attack_data.type == EnemyAttack.AttackType.HEAL:
		var heal_targets = get_heal_targets()
		if not heal_targets.is_empty():
			perform_heal(heal_targets)
			end_turn()
			return
	
	# Try ATTACK
	if can_attack():
		perform_attack()
		end_turn()
		return
	
	# Can't do anything else, end turn
	end_turn()

# ---------- HP ----------
func take_damage(amount: int) -> void:
	if shields > 0:
		remove_one_shield()
		return

	hp = max(hp - amount, 0)
	hp_num_label.text = str(hp)
	emit_hp()

	show_ui()
	hide_ui_delayed()

	if hp <= 0:
		die()

func emit_hp() -> void:
	hp_changed.emit(hp, max_hp)

func die() -> void:
	print("ENEMY DIED")

	var grid_node := get_tree().get_first_node_in_group("grid")
	if grid_node:
		grid_node.set_unit_blocked(current_cell, false)

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

func apply_stun(turns: int) -> void:
	var was_stunned := stun_turns > 0
	stun_turns = max(stun_turns, turns)

	if not was_stunned:
		_show_stun()

	print(name, "STUNNED FOR", stun_turns, "TURNS")

func _show_stun():
	chains_sprite.visible = true
	chains_sprite.play("set_chains")

func _hide_stun():
	chains_sprite.play("remove_chains")
	await chains_sprite.animation_finished
	chains_sprite.visible = false

func has_line_of_sight(from: Vector2i, to: Vector2i) -> bool:
	var line = grid.get_line_cells(from, to)

	for cell in line:
		if cell == from or cell == to:
			continue
		if grid.astar_grid.is_point_solid(cell):
			return false

	return true

func get_heal_targets() -> Array:
	var allies := []
	var enemies = get_tree().get_nodes_in_group("enemy")

	for e in enemies:
		if e == self:
			continue
		if e.hp >= e.max_hp:
			continue

		var dist := current_cell.distance_to(e.current_cell)
		if dist > attack_data.range:
			continue

		if not has_line_of_sight(current_cell, e.current_cell):
			continue

		allies.append(e)

	if allies.is_empty():
		return []

	allies.sort_custom(func(a, b):
		return a.hp < b.hp
	)

	if attack_data.heal_targets <= 1:
		return [allies[0]]

	return allies.slice(0, min(attack_data.heal_targets, allies.size()))

func perform_heal(targets: Array) -> void:
	ap -= attack_data.ap_cost
	attack_cooldown = attack_data.cooldown

	for t in targets:
		t.receive_heal(attack_data.heal_amount)

	print(
		"Enemy uses",
		attack_data.name,
		"to heal",
		targets.size(),
		"targets"
	)

func receive_heal(amount: int) -> void:
	hp = min(hp + amount, max_hp)
	hp_num_label.text = str(hp)
	emit_hp()
	
	show_ui()
	hide_ui_delayed()

func show_ui():
	ui.visible = true
	ui_timer.stop()

func hide_ui_delayed():
	if mouse_over:
		return
	ui_timer.start()

func _on_auto_hide_timer_timeout() -> void:
	if mouse_over:
		return
	ui.visible = false

func _on_mouse_trigger_area_mouse_entered() -> void:
	mouse_over = true
	show_ui()

func _on_mouse_trigger_area_mouse_exited() -> void:
	mouse_over = false
	ui.visible = false

func add_shields(amount: int) -> void:
	if amount <= 0:
		return

	var added := 0

	while shields < MAX_SHIELDS and added < amount:
		_add_single_shield()
		added += 1

	if added > 0:
		show_ui()
		hide_ui_delayed()

func _add_single_shield() -> void:
	if shields >= MAX_SHIELDS:
		return

	var shield_scene := preload("res://scenes/shield_sprite_control.tscn")
	var shield := shield_scene.instantiate()

	shields_container.add_child(shield)
	shields += 1

func remove_one_shield() -> bool:
	if shields <= 0:
		return false

	var last := shields_container.get_child(shields_container.get_child_count() - 1)

	shields -= 1

	if last.has_method("play_lost"):
		last.play_lost()
	else:
		last.queue_free()

	show_ui()
	hide_ui_delayed()

	return true

func get_shield_targets() -> Array:
	var candidates := []
	var enemies = get_tree().get_nodes_in_group("enemy")

	for e in enemies:
		if e.shields >= MAX_SHIELDS:
			continue

		var dist := current_cell.distance_to(e.current_cell)
		if dist > attack_data.range:
			continue

		if not has_line_of_sight(current_cell, e.current_cell):
			continue

		candidates.append(e)

	if candidates.is_empty():
		return []

	candidates.sort_custom(func(a, b):
		return a.hp < b.hp
	)

	var result := []
	var max_targets = min(attack_data.shield_targets, candidates.size())

	for i in range(max_targets):
		var target

		if randf() < 0.9:
			target = candidates[0]
		else:
			target = candidates.pick_random()

		result.append(target)
		candidates.erase(target)

		if candidates.is_empty():
			break

	return result

func perform_shield(targets: Array) -> void:
	ap -= attack_data.ap_cost
	attack_cooldown = attack_data.cooldown

	for t in targets:
		t.add_shields(attack_data.shield_amount)

	print(
		"Enemy uses",
		attack_data.name,
		"to shield",
		targets.size(),
		"targets"
	)
