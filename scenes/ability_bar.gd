extends Control

signal ability_slot_toggled(slot: String, enabled: bool)

@onready var q_button: Button = $MarginContainer/HBoxContainer/QButton
@onready var w_button: Button = $MarginContainer/HBoxContainer/WButton
@onready var e_button: Button = $MarginContainer/HBoxContainer/EButton
@onready var r_button: Button = $MarginContainer/HBoxContainer/RButton


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


func cancel_other_buttons(except_button: Button = null) -> void:
	var buttons = [q_button, w_button, e_button, r_button]
	
	for button in buttons:
		if button != except_button and button.button_pressed:
			button.button_pressed = false


func cancel_all_buttons() -> void:
	var buttons = [q_button, w_button, e_button, r_button]
	
	for button in buttons:
		if button.button_pressed:
			button.button_pressed = false
