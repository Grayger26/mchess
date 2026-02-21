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
@export var enemy_data: EnemyData

@export_range(0.0, 1.0) var wait_chance := 0.5

var attack_cooldown := 0
var max_mana := 0
var mana := 0

var is_dying := false
var is_dead := false

var ap := 0
var hp := 10

const MAX_SHIELDS := 2
var shields := 0

var stun_turns := 0
var is_turn_active := false
var action_in_progress := false
var support_used_this_turn := false


@onready var shields_container: HBoxContainer = $UI/shields
@onready var grid = get_parent().get_parent()
@onready var cell_size := Vector2(grid.cell_size)
@onready var hp_num_label: Label = $UI/HpNumLabel
@onready var mana_num_label: Label = $UI/ManaNumLabel
@onready var ui: Control = $UI
@onready var ui_timer: Timer = $UI/AutoHideTimer
@onready var chains_sprite: AnimatedSprite2D = $ChainsSprite
@onready var visuals_root: Node2D = $Visuals
@onready var visuals: EnemyVisuals
@onready var hp_texture_progress_bar: TextureProgressBar = $UI/ProgressBars/HpTextureProgressBar
@onready var mana_texture_progress_bar: TextureProgressBar = $UI/ProgressBars/ManaTextureProgressBar
@onready var target_marker: Marker2D = $TargetMarker
@onready var turn_manager = get_tree().get_first_node_in_group("turn_manager")

var mouse_over := false

var current_cell: Vector2i
var path: Array[Vector2i] = []
var path_index := 0
var target_player

# ---------- STATUS EFFECTS ----------
var fire_turns := 0
var fire_damage := 0

@onready var fire_sprite: AnimatedSprite2D = $FireSprite


# ---------- READY ----------
func _ready() -> void:
	turn_finished.connect(turn_manager._on_enemy_turn_finished)
	ui.visible = false
	chains_sprite.visible = false
	add_to_group("enemy")
	
	fire_sprite.visible = false
	
	if enemy_data:
		setup_from_data(enemy_data)

	current_cell = world_to_cell(global_position)
	global_position = cell_to_world(current_cell)

	hp = max_hp
	hp_texture_progress_bar.max_value = max_hp
	hp_texture_progress_bar.value = hp
	hp_num_label.text = str(hp) + " / " + str(max_hp)
	emit_hp()
	play_visual("play_idle")



# ---------- TURN ----------
func start_turn() -> void:
	if not attack_data:
		push_warning(name, " has no attack_data, skipping turn")
		end_turn()
		return

	await get_tree().create_timer(1.0).timeout
	if is_turn_active:
		return

	is_turn_active = true
	support_used_this_turn = false
	
	# ---------- STATUS EFFECTS ----------
	_apply_start_turn_effects()
	
	if is_dead or is_dying:
		end_turn()
		return


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
		mana = max_mana - attack_cooldown
	else:
		mana = max_mana

	_update_mana_ui()


	target_player = get_tree().get_first_node_in_group("player")
	if not target_player:
		end_turn()
		return

	# Priority 1: SHIELD (if available and targets exist)
	if attack_data and attack_data.type == EnemyAttack.AttackType.SHIELD and not support_used_this_turn and attack_cooldown <= 0:
		var shield_targets = get_shield_targets()
		if not shield_targets.is_empty():
			perform_shield(shield_targets)
			support_used_this_turn = true
			# After shield, try to move or end turn
			_try_move_after_action()
			return

	# Priority 2: HEAL (if available and targets exist)
	if attack_data and attack_data.type == EnemyAttack.AttackType.HEAL and not support_used_this_turn and attack_cooldown <= 0:
		var heal_targets = get_heal_targets()
		if not heal_targets.is_empty():
			perform_heal(heal_targets)
			support_used_this_turn = true
			# After heal, try to move or end turn
			_try_move_after_action()
			return
	# Priority 3: MANA (cooldown reduction)
	if attack_data and attack_data.type == EnemyAttack.AttackType.MANA and not support_used_this_turn and attack_cooldown <= 0:
		var mana_targets = get_mana_targets()
		if not mana_targets.is_empty():
			perform_mana(mana_targets)
			support_used_this_turn = true
			_try_move_after_action()
			return


	# Priority 4: ATTACK player (if in range and off cooldown)
	if can_attack():
		print(name, " CAN ATTACK - attacking player!")
		await perform_attack()
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

	# Priority 5: MOVE (if can't attack yet)
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
	#call_deferred("_emit_turn_finished")
	play_visual("play_idle")
	print("END TURN:", name)

	
	update_enemies_ui()
	
func _emit_turn_finished():
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
	if attack_data.type == EnemyAttack.AttackType.MANA:
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
	action_in_progress = true
	play_visual("look_at_x", [global_position.x, target_player.global_position.x])
	play_visual("play_ability")

	await _wait_visual_action()
	
	if attack_data.type == EnemyAttack.AttackType.HEAL:
		push_error("perform_attack() called with HEAL ability!")
		return

	ap -= attack_data.ap_cost
	attack_cooldown = attack_data.cooldown
	mana = 0
	_update_mana_ui()


		# Если есть projectile — он сам применит эффект
	if not attack_data.projectile_scene:
		apply_ability_effect(attack_data, target_player)


	print("Enemy uses", attack_data.name, "on player")
	action_in_progress = false

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
	
	if action_in_progress:
		velocity = Vector2.ZERO
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
	play_visual("play_walk")
	play_visual("look_at_x", [global_position.x, next_pos.x])


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
	if attack_data and attack_data.type == EnemyAttack.AttackType.SHIELD and not support_used_this_turn and attack_cooldown <= 0:
		var shield_targets = get_shield_targets()
		if not shield_targets.is_empty():
			perform_shield(shield_targets)
			support_used_this_turn = true
			end_turn()
			return
	
	# Try HEAL
	if attack_data and attack_data.type == EnemyAttack.AttackType.HEAL and not support_used_this_turn and attack_cooldown <= 0:
		var heal_targets = get_heal_targets()
		if not heal_targets.is_empty():
			perform_heal(heal_targets)
			support_used_this_turn = true
			end_turn()
			return
	
	# Try MANA
	if attack_data and attack_data.type == EnemyAttack.AttackType.MANA and not support_used_this_turn  and attack_cooldown <= 0:
		var mana_targets = get_mana_targets()
		if not mana_targets.is_empty():
			perform_mana(mana_targets)
			support_used_this_turn = true
			end_turn()
			return

	
	# Try ATTACK
	if can_attack():
		await perform_attack()
		end_turn()
		return
	
	# Can't do anything else, end turn
	play_visual("play_idle")
	end_turn()

# ---------- HP ----------
func take_damage(amount: int) -> void:
	if shields > 0:
		remove_one_shield()
		return
	
	play_visual("play_hurt")

	hp = max(hp - amount, 0)
	hp_num_label.text = str(hp) + " / " + str(max_hp)
	hp_texture_progress_bar.value = hp
	emit_hp()

	show_ui()
	hide_ui_delayed()

	if hp <= 0:
		die()

func emit_hp() -> void:
	hp_changed.emit(hp, max_hp)

func die() -> void:
	if is_dying or is_dead:
		return

	is_dying = true

	# ⛔ ВАЖНО: мгновенно выходим из хода
	if is_turn_active:
		is_turn_active = false
		turn_finished.emit(self)

	# СРАЗУ убираем из логики
	remove_from_group("enemy")
	action_in_progress = true

	play_visual("play_death")
	print("ENEMY DIED")

	if visuals:
		await visuals.anim.animation_finished

	is_dead = true
	died.emit()

	var grid_node := get_tree().get_first_node_in_group("grid")
	var player = get_tree().get_first_node_in_group("player")
	if grid_node:
		grid_node.set_unit_blocked(current_cell, false)
		player.update_highlight()

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
		if e.is_dying or e.is_dead:
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
	action_in_progress = true
	play_visual("play_ability")
	await _wait_visual_action()
	ap -= attack_data.ap_cost
	attack_cooldown = attack_data.cooldown
	mana = 0
	_update_mana_ui()

	for t in targets:
		t.receive_heal(attack_data.heal_amount)

	print(
		"Enemy uses",
		attack_data.name,
		"to heal",
		targets.size(),
		"targets"
	)
	action_in_progress = false

func receive_heal(amount: int) -> void:
	if is_dying or is_dead:
		return
	play_visual("play_heal")
	hp = min(hp + amount, max_hp)
	hp_num_label.text = str(hp) + " / " + str(max_hp)
	hp_texture_progress_bar.value = hp
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
	if is_dying or is_dead:
		return
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
	action_in_progress = true
	play_visual("play_ability")
	await _wait_visual_action()
	ap -= attack_data.ap_cost
	attack_cooldown = attack_data.cooldown
	mana = 0
	_update_mana_ui()

	for t in targets:
		t.add_shields(attack_data.shield_amount)

	print(
		"Enemy uses",
		attack_data.name,
		"to shield",
		targets.size(),
		"targets"
	)
	action_in_progress = false

func setup_from_data(data: EnemyData) -> void:
	if not data:
		push_error("EnemyData is NULL")
		return

	# ---------- STATS ----------
	max_hp = data.max_hp
	max_ap = data.max_ap
	move_range = data.move_range

	hp = max_hp
	ap = 0  # ход начнётся позже
	emit_hp()

	hp_num_label.text = str(hp) + " / " + str(max_hp)
	hp_texture_progress_bar.value = hp

	# ---------- ABILITY ----------
	if not data.abilities.is_empty():
		attack_data = data.abilities[0].duplicate(true)
	else:
		attack_data = null

	# ---------- VISUAL ----------
	_setup_visuals(data.visual_scene)
	
	# ---------- MANA ----------
	if attack_data:
		max_mana = attack_data.cooldown
		mana = max_mana
	else:
		max_mana = 0
		mana = 0

	mana_texture_progress_bar.max_value = max_mana
	mana_texture_progress_bar.value = mana
	mana_num_label.text = str(mana) + " / " + str(max_mana)
	hp_texture_progress_bar.max_value = max_hp
	hp_texture_progress_bar.value = hp

func _setup_visuals(scene: PackedScene) -> void:
	if not scene:
		push_warning("Enemy has no visual scene")
		return

	for c in visuals_root.get_children():
		c.queue_free()

	var visual := scene.instantiate()
	visuals_root.add_child(visual)

	visuals = visual as EnemyVisuals

	if not visuals:
		push_error("Visual scene is not EnemyVisuals")
		return

	print("CONNECT cast_fire for", name)
	visuals.cast_fire.connect(_on_visuals_cast_fire)

	play_visual("play_idle")



func play_visual(method: String, args := []):
	if not visuals:
		return
	if visuals.has_method(method):
		visuals.callv(method, args)

func _wait_visual_action() -> void:
	if visuals and visuals.anim:
		await visuals.anim.animation_finished

func apply_ability_effect(attack: EnemyAttack, target):
	if not target:
		return
	if target.is_dying or target.is_dead:
		return

	match attack.type:
		EnemyAttack.AttackType.DAMAGE:
			target.take_damage(attack.damage)

			# ▶️ НАЛОЖЕНИЕ ЭФФЕКТА
			if attack.effect_type != EnemyAttack.EffectType.NONE:
				target.apply_status_effect(attack)

		EnemyAttack.AttackType.STUN:
			target.apply_stun(attack.stun_turns)

		EnemyAttack.AttackType.HEAL:
			target.receive_heal(attack.heal_amount)

		EnemyAttack.AttackType.SHIELD:
			target.add_shields(attack.shield_amount)


func _spawn_projectile(attack: EnemyAttack, target):
	if not attack.projectile_scene:
		return

	var projectile := attack.projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = global_position
	projectile.setup(self, target, attack)

func _on_visuals_cast_fire():
	if attack_data.type == EnemyAttack.AttackType.HEAL:
		return
	if attack_data.type == EnemyAttack.AttackType.SHIELD:
		return

	print(
		"CAST FIRE:",
		attack_data.name,
		"projectile:",
		attack_data.projectile_scene
	)

	if attack_data.projectile_scene:
		_spawn_projectile(attack_data, target_player)
	else:
		apply_ability_effect(attack_data, target_player)

func _update_mana_ui() -> void:
	if max_mana <= 0:
		mana_texture_progress_bar.visible = false
		mana_num_label.visible = false
		return

	mana_texture_progress_bar.visible = true
	mana_num_label.visible = true

	mana_texture_progress_bar.max_value = max_mana
	mana_texture_progress_bar.value = mana
	mana_num_label.text = str(mana) + " / " + str(max_mana)

	show_ui()
	hide_ui_delayed()

func _update_mana_ui_predicted() -> void:
	if max_mana <= 0:
		mana_texture_progress_bar.visible = false
		mana_num_label.visible = false
		return

	var predicted_cooldown = max(attack_cooldown - 1, 0)
	var predicted_mana = max_mana - predicted_cooldown

	mana_texture_progress_bar.visible = true
	mana_num_label.visible = true

	mana_texture_progress_bar.max_value = max_mana
	mana_texture_progress_bar.value = predicted_mana
	mana_num_label.text = str(predicted_mana) + " / " + str(max_mana)

func get_mana_targets() -> Array:
	var candidates := []
	var enemies = get_tree().get_nodes_in_group("enemy")

	for e in enemies:
		if e == self:
			continue
		if e.is_dying or e.is_dead:
			continue
		if e.attack_cooldown <= 1:
			continue

		var dist := current_cell.distance_to(e.current_cell)
		if dist > attack_data.range:
			continue

		if not has_line_of_sight(current_cell, e.current_cell):
			continue

		candidates.append(e)

	if candidates.is_empty():
		return []

	# приоритет — у кого больше кулдаун
	candidates.sort_custom(func(a, b):
		return a.attack_cooldown > b.attack_cooldown
	)

	if attack_data.mana_targets <= 1:
		return [candidates[0]]

	return candidates.slice(0, min(attack_data.mana_targets, candidates.size()))

func perform_mana(targets: Array) -> void:
	if attack_cooldown > 0:
		return
	action_in_progress = true
	play_visual("play_ability")
	await _wait_visual_action()

	ap -= attack_data.ap_cost
	attack_cooldown = attack_data.cooldown
	mana = 0
	_update_mana_ui()

	for t in targets:
		t.receive_mana(attack_data.mana_amount)

	print(
		"Enemy uses",
		attack_data.name,
		"to reduce cooldown for",
		targets.size(),
		"targets"
	)

	action_in_progress = false

func receive_mana(amount: int) -> void:
	if is_dying or is_dead:
		return
	if attack_cooldown <= 0:
		return

	play_visual("play_ability", ["mana"])

	attack_cooldown = max(attack_cooldown - amount, 0)
	mana = max_mana - attack_cooldown
	_update_mana_ui()

	show_ui()
	hide_ui_delayed()


func update_enemies_ui():
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy._update_mana_ui_predicted()

func apply_status_effect(effect_type: int, damage: int, turns: int) -> void:
	match effect_type:
		EnemyAttack.EffectType.DAMAGE:
			_apply_fire_effect_from_values(damage, turns)


func _apply_fire_effect(attack: EnemyAttack) -> void:
	fire_damage = attack.effect_damage
	fire_turns = max(fire_turns, attack.effect_time)

	fire_sprite.visible = true
	fire_sprite.play("fire")

	print(
		name,
		" is on FIRE for ",
		fire_turns,
		" turns, dmg:",
		fire_damage
	)

func _apply_start_turn_effects() -> void:

	if fire_turns > 0:
		print(name, "takes fire damage:", fire_damage)

		take_damage(fire_damage)
		
		if is_dead or is_dying:
			return
	

		fire_turns -= 1

		if fire_turns <= 0:
			_remove_fire_effect()

func _remove_fire_effect() -> void:
	fire_damage = 0
	fire_turns = 0

	#fire_sprite.play("extinguish")
	#await fire_sprite.animation_finished
	fire_sprite.visible = false

	print(name, "fire effect ended")

func apply_status_effect_from_ability(ability: AbilityData) -> void:
	match ability.effect_type:
		AbilityData.EffectType.DAMAGE:
			fire_damage = ability.effect_damage
			fire_turns = max(fire_turns, ability.effect_time)

			fire_sprite.visible = true
			fire_sprite.play("fire")

func _apply_fire_effect_from_values(dmg: int, time: int) -> void:
	fire_damage = dmg
	fire_turns = max(fire_turns, time)

	fire_sprite.visible = true
	fire_sprite.play("fire")

	print(
		name,
		" is on FIRE for ",
		fire_turns,
		" turns, dmg:",
		fire_damage
	)
