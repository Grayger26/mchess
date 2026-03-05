extends Control
class_name EnemyInfoPanel

@onready var move_range_label: Label = $Panel/HBoxContainer/Labels/MoveRangeLabel
@onready var damage_label: Label = $Panel/HBoxContainer/Labels/DamageLabel
@onready var attack_range_label: Label = $Panel/HBoxContainer/Labels/AttackRangeLabel
@onready var effect_time_label: Label = $Panel/HBoxContainer/Labels/EffectTimeLabel
@onready var heal_label: Label = $Panel/HBoxContainer/Labels/HealLabel
@onready var stun_label: Label = $Panel/HBoxContainer/Labels/StunLabel
@onready var shield_label: Label = $Panel/HBoxContainer/Labels/ShieldLabel
@onready var targets_num_label: Label = $Panel/HBoxContainer/Labels/TargetsNumLabel
@onready var mana_label: Label = $Panel/HBoxContainer/Labels/ManaLabel



func set_info_values(move_range, damage, attack_range, effect_time, heal_amount, shield_amount, stun_turns, target_num, mana_amount):
	move_range_label.text = str(move_range)
	damage_label.text = str(damage)
	attack_range_label.text = str(attack_range)
	effect_time_label.text = str(effect_time)
	heal_label.text = str(heal_amount)
	shield_label.text = str(shield_amount)
	stun_label.text = str(stun_turns)
	targets_num_label.text = str(target_num)
	mana_label.text = str(mana_amount)
