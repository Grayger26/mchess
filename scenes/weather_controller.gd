extends Parallax2D


@onready var rain: GPUParticles2D = $rain
@onready var snow: GPUParticles2D = $Snow
@onready var clouds_rect: ColorRect = $CloudsRect
@onready var rain_shade: ColorRect = $"../CanvasLayer/RainShade"
