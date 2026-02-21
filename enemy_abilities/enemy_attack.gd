extends Resource
class_name EnemyAttack

@export var name: String = "Attack"

@export var range: int = 1
@export var ap_cost: int = 1
@export var cooldown: int = 1

enum AttackType {
	DAMAGE,
	STUN,
	HEAL,
	SHIELD,
	MANA
}

@export var type: AttackType = AttackType.DAMAGE

# DAMAGE
@export var damage: int = 1

# STUN
@export var stun_turns: int = 0

# HEAL
@export var heal_amount: int = 1
@export var heal_targets: int = 1
# 1 — одиночное лечение
# >1 — массовое

# SHIELD
@export var shield_amount: int = 0
@export var shield_targets: int = 0

@export var projectile_scene: PackedScene

@export var mana_amount: int = 0
@export var mana_targets: int = 0


# EFFECTS
@export var effect_damage: int = 0
@export var effect_time: int = 0

enum EffectType {
	NONE,
	DAMAGE,
	MANA_STEAL,
	STUN
}

enum EffectSprite {
	none,
	Fire
}

@export var effect_ui_icon_path : String

@export var effect_type: EffectType = EffectType.NONE
@export var effect_sprite: EffectSprite = EffectSprite.none
