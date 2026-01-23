extends Node2D
class_name Projectile

@export var speed := 50.0

var target
var ability
var caster
var arrived := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func setup(p_owner, p_target, p_ability) -> void:
	caster = p_owner
	target = p_target
	ability = p_ability
	sprite.play("fly")

func _process(delta: float) -> void:
	if arrived or not target:
		return

	global_position = global_position.move_toward(
		target.global_position,
		speed * delta
	)

	if global_position.distance_to(target.global_position) < 8.0:
		_on_hit()

func _on_hit():
	arrived = true
	sprite.play("hit")

	if caster.has_method("apply_ability_effect"):
		caster.apply_ability_effect(ability, target)


	await sprite.animation_finished
	queue_free()
