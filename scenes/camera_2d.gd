extends Camera2D
class_name MainCamera

var shake_intensity : float = 0.0
var active_shake_time : float = 0.0
var shake_decay : float = 5.0
var shake_time : float = 0.0
var shake_time_speed : float = 20.0
var noise = FastNoiseLite.new()
var zoom_tween: Tween

# Scene bounds
const LIMIT_LEFT : float = 240.0
const LIMIT_TOP : float = 135.0
const LIMIT_RIGHT : float = 1000.0
const LIMIT_BOTTOM : float = 1000.0

func _physics_process(delta: float) -> void:
	var mouse_offset = get_mouse_offset()
	var shake_offset = get_shake_offset(delta)

	var raw_offset = mouse_offset + shake_offset

	# Clamp so camera never shows outside scene bounds
	var cam_pos = global_position + raw_offset
	var clamped_pos = Vector2(
		clamp(cam_pos.x, LIMIT_LEFT, LIMIT_RIGHT),
		clamp(cam_pos.y, LIMIT_TOP, LIMIT_BOTTOM)
	)
	offset = clamped_pos - global_position

func get_mouse_offset() -> Vector2:
	var mouse_pos = get_global_mouse_position()
	var to_mouse = mouse_pos - global_position
	var offset_factor = 0.12
	return to_mouse * offset_factor

func get_shake_offset(delta: float) -> Vector2:
	if active_shake_time > 0:
		shake_time += delta * shake_time_speed
		active_shake_time -= delta

		var s_offset = Vector2(
			noise.get_noise_2d(shake_time, 0) * shake_intensity,
			noise.get_noise_2d(0, shake_time) * shake_intensity
		)

		shake_intensity = max(shake_intensity - shake_decay * delta, 0)
		return s_offset
	else:
		# Smoothly return shake to zero (applied on top of mouse offset)
		return Vector2.ZERO

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
	zoom_tween = create_tween()
	var target_zoom = Vector2.ONE - Vector2.ONE * strength
	zoom_tween.tween_property(self, "zoom", target_zoom, speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_property(self, "zoom", Vector2.ONE, speed * 1.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
