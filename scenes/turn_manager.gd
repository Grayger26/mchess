extends Node
class_name TurnManager

enum TurnState { PLAYER, ENEMY }
var state := TurnState.PLAYER

var player
var enemies: Array = []
var enemy_index := 0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	enemies = get_tree().get_nodes_in_group("enemy")

	if not player:
		push_error("TurnManager: Player not found")
		return

	player.turn_finished.connect(_on_player_turn_finished)

	for e in enemies:
		e.turn_finished.connect(_on_enemy_turn_finished)

	start_player_turn()

# ---------- PLAYER ----------
func start_player_turn() -> void:
	state = TurnState.PLAYER
	enemy_index = 0
	player.start_turn()

func _on_player_turn_finished() -> void:
	start_enemy_turn()

# ---------- ENEMY ----------
func start_enemy_turn() -> void:
	state = TurnState.ENEMY

	if enemies.is_empty():
		start_player_turn()
		return

	enemies[enemy_index].start_turn()

func _on_enemy_turn_finished() -> void:
	enemy_index += 1

	if enemy_index >= enemies.size():
		start_player_turn()
	else:
		enemies[enemy_index].start_turn()
