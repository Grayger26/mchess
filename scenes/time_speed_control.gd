extends Control
class_name TimeSpeedControl


@onready var speed_one_btn: TextureButton = $BtnPanel/BtnContainer/SpeedOneBtn
@onready var speed_two_btn: TextureButton = $BtnPanel/BtnContainer/SpeedTwoBtn
@onready var speed_three_btn: TextureButton = $BtnPanel/BtnContainer/SpeedThreeBtn




func _on_speed_one_btn_toggled(toggled_on: bool) -> void:
	if toggled_on:
		speed_two_btn.button_pressed = false
		speed_three_btn.button_pressed = false
	game_speed(1)


func _on_speed_two_btn_toggled(toggled_on: bool) -> void:
	if toggled_on:
		speed_one_btn.button_pressed = false
		speed_three_btn.button_pressed = false
	game_speed(3)


func _on_speed_three_btn_toggled(toggled_on: bool) -> void:
	if toggled_on:
		speed_one_btn.button_pressed = false
		speed_two_btn.button_pressed = false
	game_speed(5)

func game_speed(speed : int):
	Engine.time_scale = speed
