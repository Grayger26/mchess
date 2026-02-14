extends Node2D
class_name EnemyVisuals

signal cast_fire

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

var is_dead := false
var locked := false # блокирует перебивание (hurt, ability, death)

# ---------- BASE ----------
func _ready():
	print("EnemyVisuals READY:", self)
	anim.animation_finished.connect(_on_animation_finished)

# ---------- PLAY ----------
func play_idle():
	if is_dead or locked:
		return
	_play("idle")

func play_walk():
	if is_dead or locked:
		return
	_play("walk")

func play_hurt():
	if is_dead:
		return
	locked = true
	_play("hurt")

func play_death():
	if is_dead:
		return
	is_dead = true
	locked = true
	_play("death")

func play_heal():
	if is_dead:
		return
	locked = true
	_play("heal")

func play_ability(anim_name := "ability"):
	if is_dead:
		return
	if not anim.has_animation(anim_name):
		push_warning("Missing ability animation: " + anim_name)
		return

	locked = true
	_play(anim_name)

# ---------- INTERNAL ----------
func _play(name: String):
	if anim.current_animation == name:
		return
	if not anim.has_animation(name):
		push_warning("Missing animation: " + name)
		return
	anim.play(name)

func _on_animation_finished(name: String):
	if name == "hurt":
		locked = false
		play_idle()
		return

	if locked and not is_dead:
		locked = false
		play_idle()

# ---------- LOOK ----------
func look_at_x(from_x: float, to_x: float):
	if is_dead:
		return

	if to_x > from_x:
		sprite.flip_h = true
	elif to_x < from_x:
		sprite.flip_h = false

# ---------- CAST ----------
func _on_cast_fire():
	print("ENEMY VISUAL CAST FIRE, connections:", cast_fire.get_connections().size())
	cast_fire.emit()
