extends Control

signal ability_slot_toggled(slot: String, enabled: bool)

@onready var q_button:  = $MarginContainer/HBoxContainer/QButton
@onready var w_button:  = $MarginContainer/HBoxContainer/WButton
@onready var e_button:  = $MarginContainer/HBoxContainer/EButton
@onready var r_button:  = $MarginContainer/HBoxContainer/RButton

@onready var q_button_icon: Sprite2D = $MarginContainer/HBoxContainer/QButton/QButtonIcon
@onready var w_button_icon: Sprite2D = $MarginContainer/HBoxContainer/WButton/WButtonIcon
@onready var e_button_icon: Sprite2D = $MarginContainer/HBoxContainer/EButton/EButtonIcon
@onready var r_button_icon: Sprite2D = $MarginContainer/HBoxContainer/RButton/RButtonIcon

@onready var ability_component: AbilityComponent = $"../../player/AbilityComponent"


func _ready() -> void:
	set_up_icons()

func _on_q_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		cancel_other_buttons(q_button)
	ability_slot_toggled.emit("Q", button_pressed)


func _on_w_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		cancel_other_buttons(w_button)
	ability_slot_toggled.emit("W", button_pressed)


func _on_e_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		cancel_other_buttons(e_button)
	ability_slot_toggled.emit("E", button_pressed)


func _on_r_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		cancel_other_buttons(r_button)
	ability_slot_toggled.emit("R", button_pressed)


func cancel_other_buttons(except_button = null) -> void:
	var buttons = [q_button, w_button, e_button, r_button]
	
	for button in buttons:
		if button != except_button and button.button_pressed:
			button.button_pressed = false


func cancel_all_buttons() -> void:
	var buttons = [q_button, w_button, e_button, r_button]
	
	for button in buttons:
		if button.button_pressed:
			button.button_pressed = false


func set_up_icons():
	if ability_component.ability_q != null:
		q_button_icon.texture = load(ability_component.ability_q.ability_icon_path)
	else:
		q_button_icon.texture = null
	if ability_component.ability_w != null:
		w_button_icon.texture = load(ability_component.ability_w.ability_icon_path)
	else:
		w_button_icon.texture = null
	if ability_component.ability_e != null:
		e_button_icon.texture = load(ability_component.ability_e.ability_icon_path)
	else:
		e_button_icon.texture = null
	if ability_component.ability_r != null:
		r_button_icon.texture = load(ability_component.ability_r.ability_icon_path)
	else:
		r_button_icon.texture = null
