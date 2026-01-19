extends Resource
class_name EnemyData

@export var id: String
@export var display_name: String

# ---------- STATS ----------
@export var max_hp: int = 10
@export var max_ap: int = 5
@export var move_range: int = 2

# ---------- ABILITIES ----------
@export var abilities: Array[EnemyAttack] = []

# ---------- VISUAL ----------
@export var visual_scene: PackedScene
