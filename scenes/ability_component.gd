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


@onready var CUFFS = load("res://abilities/cuffs.tres")
@onready var HEAL = load("res://abilities/heal.tres")
@onready var MOLOTOV =load("res://abilities/molotov.tres")
@onready var PISTOL = load("res://abilities/pistol.tres")
@onready var PUNCH = load("res://abilities/punch.tres")




func _ready() -> void:
	abilities.clear()
	for a in [ability_q, ability_w, ability_e, ability_r]:
		if a:
			abilities.append(a)
	
	assign_ability(PISTOL, ability_q)
	assign_ability(HEAL, ability_w)
	assign_ability(MOLOTOV, ability_e)
	assign_ability(CUFFS, ability_r)


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


func assign_ability(ability: AbilityData, ability_slot: AbilityData) -> void:
	if not ability:
		return

	if ability_slot == ability_q:
		ability_q = ability
	elif ability_slot == ability_w:
		ability_w = ability
	elif ability_slot == ability_e:
		ability_e = ability
	elif ability_slot == ability_r:
		ability_r = ability
	else:
		push_warning("Unknown ability slot")
		return

	if not abilities.has(ability):
		abilities.append(ability)

	cooldowns.erase(ability.id)

	if active_ability and active_ability != ability:
		clear()
