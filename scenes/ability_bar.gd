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

@onready var q_cooldown_label: Label = $MarginContainer/HBoxContainer/QButton/CooldownLabel
@onready var w_cooldown_label: Label = $MarginContainer/HBoxContainer/WButton/CooldownLabel
@onready var e_cooldown_label: Label = $MarginContainer/HBoxContainer/EButton/CooldownLabel
@onready var r_cooldown_label: Label = $MarginContainer/HBoxContainer/RButton/CooldownLabel


@onready var q_tooltip: Control = $MarginContainer/HBoxContainer/QButton/Q_Tooltip
@onready var w_tooltip: Control = $MarginContainer/HBoxContainer/WButton/W_Tooltip
@onready var e_tooltip: Control = $MarginContainer/HBoxContainer/EButton/E_Tooltip
@onready var r_tooltip: Control = $MarginContainer/HBoxContainer/RButton/R_Tooltip



func _ready() -> void:
	set_up_icons()
	set_up_tooltips()


var _is_cancelling := false

func _on_q_button_toggled(button_pressed: bool) -> void:
	if _is_cancelling:
		return
	if button_pressed:
		cancel_other_buttons(q_button)
		ability_slot_toggled.emit("W", false)
		ability_slot_toggled.emit("E", false)
		ability_slot_toggled.emit("R", false)
	ability_slot_toggled.emit("Q", button_pressed)


func _on_w_button_toggled(button_pressed: bool) -> void:
	if _is_cancelling:
		return
	if button_pressed:
		cancel_other_buttons(w_button)
		ability_slot_toggled.emit("Q", false)
		ability_slot_toggled.emit("E", false)
		ability_slot_toggled.emit("R", false)
	ability_slot_toggled.emit("W", button_pressed)


func _on_e_button_toggled(button_pressed: bool) -> void:
	if _is_cancelling:
		return
	if button_pressed:
		cancel_other_buttons(e_button)
		ability_slot_toggled.emit("Q", false)
		ability_slot_toggled.emit("W", false)
		ability_slot_toggled.emit("R", false)
	ability_slot_toggled.emit("E", button_pressed)


func _on_r_button_toggled(button_pressed: bool) -> void:
	if _is_cancelling:
		return
	if button_pressed:
		cancel_other_buttons(r_button)
		ability_slot_toggled.emit("Q", false)
		ability_slot_toggled.emit("W", false)
		ability_slot_toggled.emit("E", false)
	ability_slot_toggled.emit("R", button_pressed)


func cancel_other_buttons(except_button = null) -> void:
	_is_cancelling = true
	for button in [q_button, w_button, e_button, r_button]:
		if button != except_button and button.button_pressed:
			button.button_pressed = false
	_is_cancelling = false

func cancel_all_buttons() -> void:
	_is_cancelling = true
	for button in [q_button, w_button, e_button, r_button]:
		button.button_pressed = false
	_is_cancelling = false

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


func set_up_tooltips():
	if ability_component.ability_q:
		q_tooltip.set_ability(ability_component.ability_q)

	if ability_component.ability_w:
		w_tooltip.set_ability(ability_component.ability_w)

	if ability_component.ability_e:
		e_tooltip.set_ability(ability_component.ability_e)

	if ability_component.ability_r:
		r_tooltip.set_ability(ability_component.ability_r)


func cover_icon(icon, label):
	icon.self_modulate = Color(1.0, 1.0, 1.0, 0.0)

func show_icon(icon):
	icon.self_modulate = Color(1.0, 1.0, 1.0, 1.0)

func update_cooldowns() -> void:
	if not ability_component:
		return

	_update_slot_cooldown(
		ability_component.ability_q,
		q_button_icon,
		q_cooldown_label
	)

	_update_slot_cooldown(
		ability_component.ability_w,
		w_button_icon,
		w_cooldown_label
	)

	_update_slot_cooldown(
		ability_component.ability_e,
		e_button_icon,
		e_cooldown_label
	)

	_update_slot_cooldown(
		ability_component.ability_r,
		r_button_icon,
		r_cooldown_label
	)

func _update_slot_cooldown(ability, icon: Sprite2D, label: Label) -> void:
	if not ability:
		return

	var turns_left = ability_component.cooldowns.get(ability.id, 0)

	if turns_left > 0:
		# 🔒 На кулдауне
		cover_icon(icon, label)
		label.visible = true
		label.text = str(turns_left)
	else:
		# ✅ Готова
		show_icon(icon)
		label.visible = false


func _on_q_button_mouse_entered() -> void:
	show_tooltip(q_tooltip)

func _on_w_button_mouse_entered() -> void:
	show_tooltip(w_tooltip)

func _on_e_button_mouse_entered() -> void:
	show_tooltip(e_tooltip)

func _on_r_button_mouse_entered() -> void:
	show_tooltip(r_tooltip)

func show_tooltip(tooltip):
	tooltip.visible = true

func hide_tooltip(tooltip):
	tooltip.visible = false

func _on_q_button_mouse_exited() -> void:
	hide_tooltip(q_tooltip)

func _on_w_button_mouse_exited() -> void:
	hide_tooltip(w_tooltip)

func _on_e_button_mouse_exited() -> void:
	hide_tooltip(e_tooltip)

func _on_r_button_mouse_exited() -> void:
	hide_tooltip(r_tooltip)
