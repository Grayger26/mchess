extends Control

@onready var rich_text_label: RichTextLabel = $RichTextLabel
var ability_damage : int
var heal_amount : int
var effect_time : int
var ap_cost : int
var cooldown : int

var ability: AbilityData

@onready var ability_component: AbilityComponent = $"../../../../../../player/AbilityComponent"


func _ready() -> void:
	set_text()

func set_text():
	if not ability:
		return

	rich_text_label.text = "[b]" + ability.name + "[/b]\n"

	if ability.damage > 0:
		rich_text_label.text += "[img]res://resources/ui/damage_icon.png[/img] " + str(ability.damage) + " "

	if ability.heal_amount > 0:
		rich_text_label.text += "[img]res://resources/ui/heal_icon.png[/img] " + str(ability.heal_amount) + " "

	if ability.effect_time > 0:
		rich_text_label.text += "[img]res://resources/ui/time_icon.png[/img] " + str(ability.effect_time) + " "

	rich_text_label.text += "\n"
	rich_text_label.text += "[img]res://resources/ui/energy_icon_2.png[/img] " + str(ability.ap_cost)
	rich_text_label.text += "  "
	rich_text_label.text += "[img]res://resources/ui/cooldown_icon.png[/img] " + str(ability.cooldown)


func set_ability(new_ability: AbilityData):
	ability = new_ability
	set_text()
