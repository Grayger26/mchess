extends Node
class_name LevelSystem

@onready var xp_bar: TextureProgressBar = $"../CanvasLayer/Stats/ProgressBars/XpBar"
@onready var xp_label: Label = $"../CanvasLayer/Stats/XpLabel"

var current_xp : float = 0.0
var max_xp_on_level : float = 5.0

var current_level : int = 1

var base_xp : float = 1


func _ready() -> void:
	update_xp_ui()

func increase_current_xp():
	current_xp += base_xp

	if current_xp >= max_xp_on_level:
		level_up()
	
	update_xp_ui()


func update_xp_ui():
	xp_bar.max_value = max_xp_on_level
	xp_bar.value = current_xp
	xp_label.text = str(current_level)

func level_up():
	var xp_left = current_xp - max_xp_on_level
	current_level += 1
	current_xp = 0
	current_xp += xp_left
	max_xp_on_level += max_xp_on_level/5
	update_xp_ui()
	# open the "level up" ui
	# player picks the stat to update
	# close the ui
