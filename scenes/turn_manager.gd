extends Node
class_name TurnManager

enum TurnState { PLAYER, ENEMY }
var state = TurnState.PLAYER

var player
var enemies: Array = []
var enemy_index = 0
var current_enemy: Enemy = null


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	enemies = get_tree().get_nodes_in_group("enemy")

	if not player:
		push_error("TurnManager: Player not found")
		return

	player.turn_finished.connect(_on_player_turn_finished)
	player.died.connect(_on_player_died)

	for e in enemies:
		e.turn_finished.connect(_on_enemy_turn_finished)
		e.died.connect(_on_enemy_died)

	start_player_turn()

# ---------- PLAYER ----------
func start_player_turn() -> void:
	if not is_instance_valid(player):
		print("Player is dead, game over")
		return

	state = TurnState.PLAYER
	enemy_index = 0

	var units := []
	units.append_array(get_tree().get_nodes_in_group("enemy"))
	units.append(player)
	player.grid.rebuild_unit_blocks(units, player)

	player.start_turn()


func _on_player_turn_finished() -> void:
	if state != TurnState.PLAYER:
		return
	enemies = get_tree().get_nodes_in_group("enemy")

	# ✅ ЕСЛИ ВРАГОВ НЕТ — СРАЗУ НОВЫЙ ХОД ИГРОКА
	if enemies.is_empty():
		start_player_turn()
		return

	start_enemy_turn()

	

func _on_player_died() -> void:
	print("GAME OVER")
	state = null


# ---------- ENEMY ----------
func start_enemy_turn() -> void:
	state = TurnState.ENEMY
	enemies = get_tree().get_nodes_in_group("enemy")

	if enemies.is_empty():
		start_player_turn()
		return

	if enemy_index >= enemies.size():
		start_player_turn()
		return

	current_enemy = enemies[enemy_index]
	current_enemy.start_turn()


func _on_enemy_turn_finished() -> void:
	if state != TurnState.ENEMY:
		return

	enemy_index += 1

	if enemy_index >= enemies.size():
		start_player_turn()
	else:
		current_enemy = enemies[enemy_index]
		current_enemy.start_turn()


func _on_enemy_died() -> void:
	var old_enemies = enemies.duplicate()
	enemies = get_tree().get_nodes_in_group("enemy")

	if enemies.is_empty():
		start_player_turn()
		return

	if state != TurnState.ENEMY:
		return

	# 🔥 если умер враг ДО текущего — сдвигаем индекс
	for i in range(old_enemies.size()):
		if not is_instance_valid(old_enemies[i]):
			if i < enemy_index:
				enemy_index -= 1
			break
