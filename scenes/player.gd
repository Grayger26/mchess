extends CharacterBody2D
class_name Player

# ---------- SIGNALS ----------
signal turn_finished
signal ap_changed(current_ap: int, max_ap: int)
signal hp_changed(current_hp: int, max_hp: int)
signal died

# ---------- STATS ----------
@export var speed := 50.0
@export var move_range := 2
@export var max_ap := 10
@export var max_hp := 20

var ap := 10
var hp := 20

var stun_turns := 0
var is_turn_active := false

var is_dying = false
var is_dead = false

# ---------- REFERENCES ----------
@onready var grid = get_parent()
@onready var cell_size: Vector2 = Vector2(grid.cell_size)
@onready var abilities: AbilityComponent = $AbilityComponent
@onready var ability_bar := get_tree().get_first_node_in_group("ability_bar")
@onready var chains_sprite: AnimatedSprite2D = $ChainsSprite
@onready var visuals: PlayerVisuals = $PlayerVisuals


# ---------- STATE ----------
enum PlayerState { MOVE, TARGETING, CASTING }
var state := PlayerState.MOVE

var current_cell: Vector2i
var path: Array[Vector2i] = []
var path_index := 0
var last_hovered_cell := Vector2i(-999, -999)
var has_moved := false

var pending_ability: AbilityData = null
var pending_target: Enemy = null

# ---------- READY ----------
func _ready() -> void:
	add_to_group("player")
	chains_sprite.visible = false
	visuals.play_idle()
	visuals.cast_fire.connect(_on_visuals_cast_fire)


	current_cell = world_to_cell(global_position)
	global_position = cell_to_world(current_cell)

	ap = max_ap
	hp = max_hp
	emit_ap()
	emit_hp()

	if ability_bar:
		ability_bar.ability_slot_toggled.connect(_on_ability_slot_toggled)

# ---------- TURN ----------
func start_turn() -> void:
	is_turn_active = true
	update_enemies_ui()
	
	# ⛓️ СНЯТИЕ СТАНА
	if stun_turns == 0 and chains_sprite.visible:
		_hide_stun()

	# ❗ Проверка стана
	if stun_turns > 0:
		stun_turns -= 1
		print(name, " is STUNNED, turns left:", stun_turns)
		call_deferred("end_turn")
		return
	
	if stun_turns > 0:
		stun_turns -= 1
		print("PLAYER STUNNED, turns left:", stun_turns)
		call_deferred("_finish_stunned_turn")
		return

	ap = max_ap
	emit_ap()

	abilities.tick_cooldowns()

	has_moved = false
	state = PlayerState.MOVE

	call_deferred("_start_turn_deferred")

func end_turn() -> void:
	if not is_turn_active:
		return

	state = PlayerState.MOVE
	path.clear()
	path_index = 0
	velocity = Vector2.ZERO

	has_moved = false

	grid.clear_preview_path()
	grid.hide_highlight()

	if ability_bar:
		ability_bar.cancel_all_buttons()
		
	is_turn_active = false
	turn_finished.emit()
	grid.clear_hover_move_tile()

# ---------- INPUT ----------
func _input(event: InputEvent) -> void:
	if is_stunned():
		return
	
	if not (event is InputEventMouseButton and event.pressed):
		return
	if not path.is_empty():
		return

	# FIX: Use get_global_mouse_position() instead of event.position
	var clicked_cell := world_to_cell(get_global_mouse_position())

	match state:
		PlayerState.MOVE:
			if has_moved:
				return
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
	update_move_hover()
	update_attack_hover()

# ---------- PHYSICS ----------
func _physics_process(_delta: float) -> void:

	if is_stunned():
		velocity = Vector2.ZERO
		return
	
	if path.is_empty():
		velocity = Vector2.ZERO
		return

	if path_index >= path.size():
		finish_movement()
		return

	var next_cell := path[path_index]
	var next_pos := cell_to_world(next_cell)

	visuals.look_at_x(global_position.x, next_pos.x)
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

	has_moved = true
	grid.hide_highlight()
	visuals.play_idle()


# ---------- AP ----------
func emit_ap() -> void:
	ap_changed.emit(ap, max_ap)

# ---------- HP ----------
func take_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	emit_hp()
	visuals.play_hurt()

	if hp <= 0:
		die()

func emit_hp() -> void:
	hp_changed.emit(hp, max_hp)

func die() -> void:
	is_dying = true
	visuals.play_death()
	died.emit()
	is_dead = true
	#queue_free()

# ---------- PATH ----------
func request_path(target_cell: Vector2i) -> void:
	var units := []
	units.append_array(get_tree().get_nodes_in_group("enemy"))
	units.append(self)

	grid.rebuild_unit_blocks(units, self)

	var new_path = grid.get_grid_path(current_cell, target_cell)
	if new_path.is_empty():
		return

	var cost = new_path.size() - 1
	if cost > ap:
		return

	path = new_path.slice(1)
	visuals.play_walk()
	path_index = 0
	grid.clear_hover_move_tile()

# ---------- PREVIEW ----------
func update_move_preview() -> void:
	if state != PlayerState.MOVE or has_moved or not path.is_empty():
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

	if preview.size() - 1 > ap:
		grid.clear_preview_path()
		return

	grid.set_preview_path(preview)

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
	if state == PlayerState.MOVE and not has_moved:
		grid.set_highlighted_cells(get_legal_moves(current_cell))
	else:
		grid.hide_highlight()

# ---------- HELPERS ----------
func world_to_cell(pos: Vector2) -> Vector2i:
	# Convert world position to grid cell coordinates
	return Vector2i(floor(pos.x / cell_size.x), floor(pos.y / cell_size.y))

func cell_to_world(cell: Vector2i) -> Vector2:
	# Convert grid cell to world position (top-left corner)
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

func activate_ability(ability: AbilityData) -> void:
	if state != PlayerState.MOVE:
		return
	
	# Prevent activating abilities while moving
	if is_moving():
		return
		
	if not abilities.is_ready(ability):
		print("ABILITY ON COOLDOWN:", ability.name, "(", abilities.cooldowns.get(ability.id, 0), "turns left)")
		return

	if ap < ability.ap_cost:
		print("NOT ENOUGH AP")
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
	
	grid.attack_tiles.clear()
	grid.clear_hover_attack_tile()

	if ability_bar:
		ability_bar.cancel_all_buttons()

func get_ability_targets() -> Array[Vector2i]:
	return grid.get_highlighted_cells()

func cast_ability(target_cell: Vector2i) -> void:
	visuals.look_at_x(global_position.x, cell_to_world(target_cell).x)
	var ability := abilities.active_ability
	if not ability:
		return

	print("CAST:", ability.name, "on", target_cell)
	
	visuals.look_at_x(global_position.x, cell_to_world(target_cell).x)

	# ▶️ АНИМАЦИЯ СПОСОБНОСТИ
	visuals.play_cast(ability.animation_name)

	ap -= ability.ap_cost
	ap = max(ap, 0)
	emit_ap()

	abilities.put_on_cooldown(ability)
	grid.attack_tiles.clear()
	grid.clear_hover_attack_tile()

	var enemy := get_enemy_at_cell(target_cell)

	pending_ability = ability
	pending_target = enemy

	abilities.clear()
	grid.hide_highlight()

	if ability_bar:
		ability_bar.cancel_all_buttons()

	state = PlayerState.MOVE
	
	if state == PlayerState.MOVE:
		update_highlight()

	if ap <= 0:
		end_turn()
	else:
		update_highlight()

func show_ability_range() -> void:
	var ability := abilities.active_ability
	if not ability:
		return

	var cells: Array[Vector2i] = []
	var color := Color(1.0, 0.2, 0.2, 0.35)

	if ability.pattern == AbilityData.AbilityPattern.SELF:
		cells = grid.get_self_cell(current_cell)
		color = Color(0.2, 1.0, 0.2, 0.35)
	else:
		cells = grid.get_cells_in_range_for_ability(current_cell, ability.range)

	grid.attack_tiles = cells.duplicate()
	grid.set_highlighted_cells(cells, color)

func get_enemy_at_cell(cell: Vector2i) -> Enemy:
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.current_cell == cell:
			return e
	return null

func _on_end_turn_button_button_up() -> void:
	if self.is_moving():
		return

	self.force_end_turn()

func is_moving() -> bool:
	return not path.is_empty() or visuals.locked


func force_end_turn() -> void:
	velocity = Vector2.ZERO
	path.clear()
	path_index = 0
	ap = 0
	has_moved = true

	finish_movement()
	end_turn()

func _start_turn_deferred() -> void:
	var units := []
	units.append_array(get_tree().get_nodes_in_group("enemy"))
	units.append(self)

	grid.rebuild_unit_blocks(units, self)

	update_highlight()

func update_attack_hover() -> void:
	if state != PlayerState.TARGETING:
		grid.clear_hover_attack_tile()
		return

	var mouse_cell := world_to_cell(get_global_mouse_position())

	if mouse_cell in grid.attack_tiles:
		grid.set_hover_attack_tile(mouse_cell)
	else:
		grid.clear_hover_attack_tile()

func update_move_hover() -> void:
	if state != PlayerState.MOVE or has_moved or not path.is_empty():
		grid.clear_hover_move_tile()
		return

	var mouse_cell := world_to_cell(get_global_mouse_position())

	if mouse_cell in get_legal_moves(current_cell):
		grid.set_hover_move_tile(mouse_cell)
	else:
		grid.clear_hover_move_tile()

func is_stunned() -> bool:
	return stun_turns > 0

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


func _finish_stunned_turn() -> void:
	if not is_turn_active:
		return

	is_turn_active = false

	grid.clear_preview_path()
	grid.hide_highlight()
	grid.clear_hover_move_tile()
	grid.clear_hover_attack_tile()

	if ability_bar:
		ability_bar.cancel_all_buttons()

	turn_finished.emit()

func heal(amount: int) -> void:
	if amount <= 0:
		return

	var old_hp := hp
	hp = min(hp + amount, max_hp)

	if hp != old_hp:
		emit_hp()

func _spawn_projectile(ability: AbilityData, enemy: Enemy) -> void:
	var projectile := ability.projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	projectile.global_position = global_position
	projectile.setup(self, enemy, ability)

func apply_ability_effect(ability: AbilityData, target):
	match ability.type:
		AbilityData.AbilityType.STUN:
			if target:
				target.apply_stun(ability.stun_turns)

		AbilityData.AbilityType.DAMAGE:
			if target:
				target.take_damage(ability.damage)

		AbilityData.AbilityType.HEAL:
			heal(ability.heal_amount)

		AbilityData.AbilityType.UTILITY:
			pass


func _on_visuals_cast_fire():
	if not pending_ability:
		return

	if pending_ability.projectile_scene and pending_target:
		_spawn_projectile(pending_ability, pending_target)
	else:
		apply_ability_effect(pending_ability, pending_target)

	pending_ability = null
	pending_target = null

func update_enemies_ui():
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		enemy._update_mana_ui_predicted()
