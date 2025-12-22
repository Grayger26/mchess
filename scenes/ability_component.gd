extends Node
class_name AbilityComponent

signal ability_activated(ability: AbilityData)
signal ability_deactivated()

var abilities: Array[AbilityData] = []

@export var ability_q: AbilityData
@export var ability_w: AbilityData
@export var ability_e: AbilityData
@export var ability_r: AbilityData

var active_ability: AbilityData = null

# cooldowns хранятся здесь: ability_id -> turns left
var cooldowns := {}


func _ready() -> void:
	abilities.clear()
	for a in [ability_q, ability_w, ability_e, ability_r]:
		if a:
			abilities.append(a)


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


# ---------- COOLDOWN ----------

func is_ready(ability: AbilityData) -> bool:
	if not cooldowns.has(ability.id):
		return true
	return cooldowns[ability.id] <= 0


func put_on_cooldown(ability: AbilityData) -> void:
	if ability.cooldown > 0:
		cooldowns[ability.id] = ability.cooldown


func tick_cooldowns() -> void:
	for id in cooldowns.keys():
		if cooldowns[id] > 0:
			cooldowns[id] -= 1
