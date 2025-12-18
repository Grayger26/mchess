extends Resource
class_name AbilityData

@export var id: String
@export var name: String

@export var range: int = 1

enum AbilityType {
	ATTACK,
	HEAL
}

enum AbilityPattern {
	SINGLE,
	CIRCLE,
	LINE,
	CONE,
	SELF
}

@export var pattern: AbilityPattern = AbilityPattern.SINGLE

@export var can_target_empty: bool = false
@export var can_target_enemy: bool = true
@export var can_target_player: bool = false

@export var damage: int = 0

@export var cooldown: int = 0
@export var ap_cost: int = 1
@export var level: int = 1
