extends Camera2D
class_name MainCamera

var shake_intensity : float = 0.0
var active_shake_time : float = 0.0

var shake_decay : float = 5.0

var shake_time : float = 0.0
var shake_time_speed : float = 20.0

var noise = FastNoiseLite.new()

var zoom_tween: Tween


func _physics_process(delta: float) -> void:
	camera_offset()
	if active_shake_time > 0:
		shake_time += delta * shake_time_speed
		active_shake_time -= delta
		
		offset = Vector2(
			noise.get_noise_2d(shake_time, 0) * shake_intensity,
			noise.get_noise_2d(0, shake_time) * shake_intensity
		)
		
		shake_intensity = max(shake_intensity - shake_decay * delta, 0)
	else:
		offset = lerp(offset, Vector2.ZERO, 10.5 * delta)


func screen_shake(intensity: int, time : float):
	randomize()
	noise.seed = randi()
	noise.frequency = 2.0
	
	shake_intensity = intensity
	active_shake_time = time
	shake_time = 0.0



func zoom_punch(strength := 0.15, speed := 0.1):
	if zoom_tween and zoom_tween.is_valid():
		zoom_tween.kill()
	
	# Создаём новый tween
	zoom_tween = create_tween()
	
	# Быстро приблизим (zoom < 1 означает приближение)
	var target_zoom = Vector2.ONE - Vector2.ONE * strength
	zoom_tween.tween_property(self, "zoom", target_zoom, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Затем плавно вернём к исходному зуму
	zoom_tween.tween_property(self, "zoom", Vector2.ONE, speed * 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)



func camera_offset():
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	
	var offset_factor = 0.12 # Насколько сильно камера тянется за мышкой
	offset = to_mouse * offset_factor
