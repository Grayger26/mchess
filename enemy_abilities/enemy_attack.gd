extends Resource
class_name EnemyAttack

@export var name: String = "Attack"

@export var range: int = 1          # в клетках
@export var ap_cost: int = 1
@export var cooldown: int = 1

enum AttackType {
	DAMAGE,
	STUN,
	HEAL
}

@export var type: AttackType = AttackType.DAMAGE

# DAMAGE
@export var damage: int = 1

# STUN
@export var stun_turns: int = 0
