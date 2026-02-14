extends Control

@onready var hours_label: Label = $HoursLabel
@onready var minutes_label: Label = $MinutesLabel



func _on_time_system_updated(date_time : DateTime) -> void:
	#update_label(day_label, date_time.days, false)
	update_label(hours_label, date_time.hours)
	update_label(minutes_label, date_time.minutes)
	pass

func add_leading_zero(label : Label, value : int):
	if value < 10:
		label.text += '0'

func update_label(label : Label, value : int, should_have_zero : bool = true):
	label.text = ""
	
	if should_have_zero:
		add_leading_zero(label, value)
	
	label.text += str(value)
