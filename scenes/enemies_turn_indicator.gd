extends Control
class_name EnemiesTurnIndicator

@onready var panel: NinePatchRect = $Panel
@onready var enemy_turn_label: Label = $Panel/EnemyTurnLabel


func _ready() -> void:
	text_flickering()

func fade_panel(fade_in: bool):
	var tween = create_tween()
	var target_modulate = Color("ffffff00") if fade_in else Color("ffffffff")
	var start_modulate  = Color("ffffffff") if fade_in else Color("ffffff00")
	
	tween.tween_property(panel, "modulate", target_modulate, 1.5)\
		.from(start_modulate)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func text_flickering():
	var tween = create_tween()
	var red = Color("dd453d")
	var white = Color("ffffffff")
	
	tween.set_loops()  # Loop forever
	tween.tween_property(enemy_turn_label, "theme_override_colors/font_color", red, 0.8)\
		.from(white)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(enemy_turn_label, "theme_override_colors/font_color", white, 0.8)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	
