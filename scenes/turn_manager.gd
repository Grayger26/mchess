extends Node
class_name TurnManager

enum TurnState { PLAYER, ENEMY }
var state = TurnState.PLAYER

var player
var enemies: Array = []
var enemy_index = 0
var current_enemy: Enemy = null
@export var num_of_enemies_to_spawn = 1

@onready var enemy_group: EnemyGroup = $"../EnemyGroup"

@onready var enemies_turn_indicator: EnemiesTurnIndicator = $"../CanvasLayer/EnemiesTurnIndicator"


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
	
	if enemies_turn_indicator.panel.modulate != Color("ffffff00"):
		enemies_turn_indicator.fade_panel(true)
	
	player.start_turn()

func _on_player_turn_finished() -> void:
	if state != TurnState.PLAYER:
		return
	
	enemies = get_tree().get_nodes_in_group("enemy")

	if enemies.is_empty():
		start_player_turn()
		return
	
	for i in num_of_enemies_to_spawn:
		enemy_group.spawn_enemy()
		
	enemies_turn_indicator.fade_panel(false)
	
	start_enemy_turn()

func _on_player_died() -> void:
	print("GAME OVER")
	state = null

# ---------- ENEMY ----------
func start_enemy_turn() -> void:
	state = TurnState.ENEMY
	enemies = get_tree().get_nodes_in_group("enemy")
	enemy_index = 0
	current_enemy = null

	_continue_enemy_turns()

func _continue_enemy_turns() -> void:
	# Refresh enemy list
	enemies = get_tree().get_nodes_in_group("enemy")
	print("ENEMY INDEX:", enemy_index, "/", enemies.size())

	
	if enemies.is_empty():
		start_player_turn()
		return

	# Skip invalid enemies
	while enemy_index < enemies.size():
		var e = enemies[enemy_index]
		if is_instance_valid(e):
			current_enemy = e
			# Give a small delay to ensure clean state transitions
			await get_tree().process_frame
			if is_instance_valid(e) and state == TurnState.ENEMY:
				e.start_turn()
			return
		enemy_index += 1

	# If we got here, all enemies are invalid
	start_player_turn()

func _on_enemy_turn_finished(enemy: Enemy) -> void:
	if state != TurnState.ENEMY:
		return

	# Only advance if this is the current enemy's turn finishing
	if enemy != current_enemy:
		return


	enemy_index += 1
	current_enemy = null
	_continue_enemy_turns()

func _on_enemy_died() -> void:
	var old_enemies = enemies.duplicate()
	enemies = get_tree().get_nodes_in_group("enemy")

	if enemies.is_empty():
		start_player_turn()
		return

	if state != TurnState.ENEMY:
		return

	# Adjust index if enemy died before current turn
	for i in range(old_enemies.size()):
		if not is_instance_valid(old_enemies[i]):
			if i < enemy_index:
				enemy_index -= 1
			break

func register_enemy(enemy: Enemy) -> void:
	enemies.append(enemy)
	enemy.turn_finished.connect(_on_enemy_turn_finished)
	enemy.died.connect(_on_enemy_died)
