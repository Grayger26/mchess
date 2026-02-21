extends Control


@onready var h_box_container: HBoxContainer = $HBoxContainer

@export var active_effect : PackedScene




func construct_active_effect(icon_path: String, turns: int, effect_type: int):
	var effect_instance = active_effect.instantiate()
	h_box_container.add_child(effect_instance)

	effect_instance.get_node("HBoxContainer/EffectIcon").texture = load(icon_path)
	effect_instance.get_node("HBoxContainer/Label").text = str(max(turns, 1))

	return effect_instance
