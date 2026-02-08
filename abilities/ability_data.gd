extends Resource
class_name AbilityData

@export var id: String
@export var name: String

@export var range: int = 1
@export var ap_cost: int = 1
@export var cooldown: int = 0
@export var damage: int = 0
@export var level: int = 1
@export var heal_amount : int = 0

enum AbilityType {
	DAMAGE,
	HEAL,
	UTILITY,
	STUN
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
@export var stun_turns: int = 0
@export var animation_name : String
@export var projectile_scene: PackedScene


# EFFECTS
@export var effect_damage: int = 0
@export var effect_time: int = 0

enum EffectType {
	NONE,
	DAMAGE,
	MANA_STEAL
}

enum EffectSprite {
	none,
	Fire
}

@export var effect_type: EffectType = EffectType.NONE
@export var effect_sprite: EffectSprite = EffectSprite.none


enum TargetingType {
	SINGLE,     # как сейчас
	AOE_ON_CELL # молотов
}

@export var targeting_type: TargetingType = TargetingType.SINGLE

# AoE
@export var aoe_radius: int = 0

@export var ability_icon_path : String = ""
