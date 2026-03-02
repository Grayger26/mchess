extends DirectionalLight2D

@export var day_color : Color
@export var night_color : Color
@export var morning_color : Color
@export var evening_color : Color
@export var day_start : DateTime
@export var night_start : DateTime
@export var morning_start : DateTime
@export var evening_start : DateTime
@export var transition_time : int = 30 # in minutes
@export var time_system : TimeSystem
@onready var street_lights: Node2D = $"../StreetLights"


var in_transition : bool = false

enum DayState {MORNING, DAY, EVENING, NIGHT}
var current_state : DayState = DayState.DAY

@onready var windows: TileMapLayer = $"../Tilemaps/windows"





func get_minutes_since_midnight(time: DateTime) -> int:
	return time.hours * 60 + time.minutes

func _ready() -> void:
	await get_tree().process_frame 
	
	time_system.updated.connect(update)

	var current_minutes = get_minutes_since_midnight(time_system.date_time)
	var morning_minutes = get_minutes_since_midnight(morning_start)
	var day_minutes = get_minutes_since_midnight(day_start)
	var evening_minutes = get_minutes_since_midnight(evening_start)
	var night_minutes = get_minutes_since_midnight(night_start)

	print("Current Minutes:", current_minutes)
	print("Morning Minutes:", morning_minutes)
	print("Day Minutes:", day_minutes)
	print("Evening Minutes:", evening_minutes)
	print("Night Minutes:", night_minutes)

	if current_minutes >= night_minutes or current_minutes < morning_minutes:
		current_state = DayState.NIGHT
	elif current_minutes >= evening_minutes:
		current_state = DayState.EVENING
	elif current_minutes >= day_minutes:
		current_state = DayState.DAY
	else:
		current_state = DayState.MORNING

	print("New state:", current_state)
	color = color_map[current_state]




@onready var time_map : Dictionary = {
	DayState.MORNING: morning_start,
	DayState.DAY: day_start,
	DayState.EVENING: evening_start,
	DayState.NIGHT: night_start
}

@onready var transition_map : Dictionary = {
	DayState.MORNING: DayState.DAY,
	DayState.DAY: DayState.EVENING,
	DayState.EVENING: DayState.NIGHT,
	DayState.NIGHT: DayState.MORNING
}

@onready var color_map : Dictionary = {
	DayState.MORNING: morning_color,
	DayState.DAY: day_color,
	DayState.EVENING: evening_color,
	DayState.NIGHT: night_color
}

	

func update(game_time : DateTime):
	var next_state = transition_map[current_state]
	var change_time = time_map[next_state]
	var time_diff = change_time.diff_without_days(game_time)
	
	if in_transition:
		update_transition(time_diff, next_state)
	elif time_diff > 0 and time_diff < (transition_time * 60):
		in_transition = true
		update_transition(time_diff, next_state)
	else:
		color = color_map[current_state]
	
	
	if time_system.date_time.hours == 20:
		lights_on()
	elif time_system.date_time.hours == 5:
		lights_off()
	

func update_transition(time_diff : int, next_state : DayState):
	var ratio = 1 - (time_diff as float / (transition_time * 60))
	if ratio > 1:
		current_state = next_state
		in_transition = false
	else:
		color = color_map[current_state].lerp(color_map[next_state], ratio)

func lights_on():
	windows.visible = true
	for light : PointLight2D in street_lights.get_children():
			light.enabled = true

func lights_off():
	windows.visible = false
	for light : PointLight2D in street_lights.get_children():
		light.enabled = false
