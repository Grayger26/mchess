extends Node2D
class_name EnemyGroup

@onready var camera: Camera2D = $"../player/Camera2D"
@onready var grid: Grid = get_parent()

var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")  # Adjust path to your enemy scene

var active_enemies: Array[Enemy] = []
#var max_enemies: int = 5

# Enemy data resources
@onready var BLUE_DVORNIK_DATA = load("res://enemy_data/blue_dvornik_data.tres")
@onready var BLUE_GOPNIK_DATA = load("res://enemy_data/blue_gopnik_data.tres") 
@onready var BLUE_MENT_DATA = load("res://enemy_data/blue_ment_data.tres") 
@onready var BLUE_POP_DATA = load("res://enemy_data/blue_pop_data.tres") 
@onready var BROWN_DOG = load("res://enemy_data/brown_dog.tres") 
@onready var GREEN_BOMJ_DATA = load("res://enemy_data/green_bomj_data.tres") 
@onready var GREY_MENT_DATA = load("res://enemy_data/grey_ment_data.tres") 
@onready var WHITE_SANITAR_DATA = load("res://enemy_data/white_sanitar_data.tres") 

@onready var enemy_data_list = [
	BLUE_DVORNIK_DATA, 
	BLUE_GOPNIK_DATA, 
	BLUE_MENT_DATA, 
	BLUE_POP_DATA,
	BROWN_DOG, 
	GREEN_BOMJ_DATA, 
	GREY_MENT_DATA, 
	WHITE_SANITAR_DATA
]

func _ready():
	# Clean up active_enemies list by checking if enemies are valid
	clean_enemy_list()

func spawn_enemy() -> Enemy:
	# Check if we've reached max enemies
	clean_enemy_list()
	
	#if active_enemies.size() >= max_enemies:
		#print("Max enemies reached, cannot spawn more")
		#return null
	#
	# Get spawn position outside viewport
	var spawn_pos = get_spawn_position_outside_viewport()
	
	# Convert world position to grid cell
	var spawn_cell = grid.world_to_cell(spawn_pos)
	
	# Make sure spawn position is valid (not blocked)
	var max_attempts = 10
	var attempts = 0
	
	while grid.astar_grid.is_point_solid(spawn_cell) and attempts < max_attempts:
		spawn_pos = get_spawn_position_outside_viewport()
		spawn_cell = grid.world_to_cell(spawn_pos)
		attempts += 1
	
	if attempts >= max_attempts:
		print("Could not find valid spawn position")
		return null
	
	# Instantiate enemy
	var enemy = enemy_scene.instantiate() as Enemy
	
	# Set position BEFORE adding to scene tree
	enemy.global_position = grid.cell_to_world(spawn_cell)
	
	# Add to scene
	add_child(enemy)
	
	# Construct enemy with random data
	construct_enemy(enemy)
	
	# Track enemy
	active_enemies.append(enemy)
	
	# Connect to died signal to remove from active list
	enemy.died.connect(_on_enemy_died.bind(enemy))
	
	print("Spawned enemy at cell:", spawn_cell, "world pos:", enemy.global_position)
	
	return enemy

func construct_enemy(enemy: Enemy) -> void:
	var random_data: EnemyData = enemy_data_list.pick_random()

	if not random_data:
		push_error("No enemy data available!")
		return

	enemy.enemy_data = random_data
	enemy.setup_from_data(random_data)
	
	var tm := get_tree().get_first_node_in_group("turn_manager")
	if tm:
		tm.register_enemy(enemy)



func get_spawn_position_outside_viewport() -> Vector2:
	if not camera:
		push_error("Camera not found!")
		return Vector2.ZERO
	
	# Get viewport bounds
	var viewport_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.global_position
	
	# Distance outside viewport (in pixels)
	var spawn_distance = 5.0  
	
	var spawn_pos: Vector2
	
	# Randomly pick a side (top, bottom, left, right)
	var side = randi() % 4
	
	match side:
		0:  # Top
			spawn_pos = Vector2(
				randf_range(camera_pos.x - viewport_size.x / 2, camera_pos.x + viewport_size.x / 2), 
				camera_pos.y - viewport_size.y / 2 - spawn_distance
			)
		1:  # Bottom
			spawn_pos = Vector2(
				randf_range(camera_pos.x - viewport_size.x / 2, camera_pos.x + viewport_size.x / 2),
				camera_pos.y + viewport_size.y / 2 + spawn_distance
			)
		2:  # Left
			spawn_pos = Vector2(
				camera_pos.x - viewport_size.x / 2 - spawn_distance,
				randf_range(camera_pos.y - viewport_size.y / 2, camera_pos.y + viewport_size.y / 2)
			)
		3:  # Right
			spawn_pos = Vector2(
				camera_pos.x + viewport_size.x / 2 + spawn_distance,
				randf_range(camera_pos.y - viewport_size.y / 2, camera_pos.y + viewport_size.y / 2)
			)
	
	return spawn_pos

func clean_enemy_list() -> void:
	# Remove dead/invalid enemies from tracking
	active_enemies = active_enemies.filter(
	func(e): return e and is_instance_valid(e) and not e.is_dead
)


func _on_enemy_died(enemy: Enemy) -> void:
	active_enemies.erase(enemy)
	print("Enemy died, active enemies:", active_enemies.size())

func get_active_enemy_count() -> int:
	clean_enemy_list()
	return active_enemies.size()
