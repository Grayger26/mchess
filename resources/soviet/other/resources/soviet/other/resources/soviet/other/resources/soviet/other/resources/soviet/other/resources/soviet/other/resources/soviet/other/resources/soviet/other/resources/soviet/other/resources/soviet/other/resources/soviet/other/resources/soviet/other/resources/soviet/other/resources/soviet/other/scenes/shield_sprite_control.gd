extends Control

@onready var shield_sprite: AnimatedSprite2D = $ShieldSprite

func _ready() -> void:
	shield_sprite.play("shield_added")

func play_lost():
	shield_sprite.play("shield_lost")
	shield_sprite.animation_finished.connect(_on_lost_finished)

func _on_lost_finished():
	queue_free()
