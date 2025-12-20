extends Control

@onready var hp_num_label: Label = $MarginContainer/HBoxContainer/NumLabels/HpNumLabel
@onready var ap_num_label: Label = $MarginContainer/HBoxContainer/NumLabels/ApNumLabel


@onready var player := get_tree().get_first_node_in_group("player")

func _ready() -> void:
	if player:
		set_ap(player.ap)


func set_ap(value: int) -> void:
	if not ap_num_label:
		push_error("ap_num_label is NULL — check node path")
		return

	ap_num_label.text = str(value)


func _on_player_ap_changed(current_ap: int, max_ap: int) -> void:
	set_ap(current_ap)
