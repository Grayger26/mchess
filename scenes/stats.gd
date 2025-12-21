extends Control

@onready var hp_num_label: Label = $MarginContainer/HBoxContainer/NumLabels/HpNumLabel
@onready var ap_num_label: Label = $MarginContainer/HBoxContainer/NumLabels/ApNumLabel

@onready var player := get_tree().get_first_node_in_group("player")

func _ready() -> void:
	if not player:
		push_error("Player not found")
		return

	player.ap_changed.connect(_on_player_ap_changed)
	player.hp_changed.connect(_on_player_hp_changed)

	# initial values
	_on_player_ap_changed(player.ap, player.max_ap)
	_on_player_hp_changed(player.hp, player.max_hp)


func _on_player_ap_changed(current_ap: int, _max_ap: int) -> void:
	set_ap(current_ap)


func _on_player_hp_changed(current_hp: int, _max_hp: int) -> void:
	hp_num_label.text = str(current_hp)

func set_ap(value: int) -> void: 
	if not ap_num_label: 
		push_error("ap_num_label is NULL — check node path") 
		return 
	ap_num_label.text = str(value)
