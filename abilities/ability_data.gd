extends Resource
class_name AbilityData

@export var id: String
@export var name: String

@export var range: int = 1
@export var ap_cost: int = 1
@export var cooldown: int = 0
@export var damage: int = 0
@export var level: int = 1

enum AbilityType {
	DAMAGE,
	HEAL,
	UTILITY
}

enum AbilityPattern {
	SINGLE,
	CIRCLE,
	LINE,
	CONE,
	SELF
}

@export var type: AbilityType = AbilityType.DAMAGE
@export var pattern: AbilityPattern = AbilityPattern.SINGLE

@export var can_target_empty := false
@export var can_target_enemy := true
@export var can_target_player := false
