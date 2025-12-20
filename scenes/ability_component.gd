extends Node
class_name AbilityComponent

signal ability_activated(ability: AbilityData)
signal ability_deactivated()

@export var ability_q: AbilityData
@export var ability_w: AbilityData
@export var ability_e: AbilityData
@export var ability_r: AbilityData

var active_ability: AbilityData = null


func activate(ability: AbilityData) -> void:
	active_ability = ability
	ability_activated.emit(ability)


func clear() -> void:
	if active_ability:
		active_ability = null
		ability_deactivated.emit()


func get_ability_by_slot(slot: String) -> AbilityData:
	match slot:
		"Q": return ability_q
		"W": return ability_w
		"E": return ability_e
		"R": return ability_r
		_: return null
