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
	SHIELD
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
