extends Control
class_name EnemyNumberControl


@onready var enemy_group: EnemyGroup = $"../../EnemyGroup"
@onready var enemy_num_label: Label = $BtnPanel/HBoxContainer/EnemyNumLabel


func update():
	var enemy_array = get_tree().get_nodes_in_group("enemy")
	var enemy_num = enemy_array.size()
	enemy_num_label.text = str(enemy_num)
