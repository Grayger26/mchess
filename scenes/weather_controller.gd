extends Parallax2D


@onready var rain: GPUParticles2D = $rain
@onready var snow: GPUParticles2D = $Snow
@onready var clouds_rect: ColorRect = $CloudsRect
@onready var rain_shade: ColorRect = $"../CanvasLayer/RainShade"
@onready var tilemaps: Tilemaps = $"../Tilemaps"


func _ready() -> void:
	set_weather()

func set_weather():
	var raining = [true, false]
	set_rain(raining.pick_random())
	

func set_rain(raining : bool):
	if raining:
		if tilemaps.season == 0:
			snow.emitting = true
			rain.emitting = false
			rain_shade.color = Color("2d2d2d00")
		else:
			snow.emitting = false
			rain.emitting = true
			if rain_shade.color != Color("2d2d2d49"): 
				fade_rain_shade(true)
	elif !raining:
		snow.emitting = false
		rain.emitting = false
		if rain_shade.color != Color("2d2d2d00"):
			fade_rain_shade(false)


func _on_weather_timer_timeout() -> void:
	set_weather()

func fade_rain_shade(fade_in: bool):
	var tween = create_tween()
	var target_color = Color("2d2d2d49") if fade_in else Color("2d2d2d00")
	var start_color  = Color("2d2d2d00") if fade_in else Color("2d2d2d49")
	
	tween.tween_property(rain_shade, "color", target_color, 5.0)\
		.from(start_color)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
