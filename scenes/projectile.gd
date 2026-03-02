extends Node2D
class_name Projectile

@export var speed := 50.0

var target_position: Vector2
var target_entity = null # опционально (Enemy / Player)

var ability
var caster
var arrived := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func setup(p_owner, p_target, p_ability) -> void:
	caster = p_owner
	ability = p_ability

	if p_target is Node2D:
		target_entity = p_target
		# 🎯 если у цели есть target_marker — используем его
		if p_target.has_node("TargetMarker"):
			var marker: Marker2D = p_target.get_node("TargetMarker")
			target_position = marker.global_position
		elif "target_marker" in p_target:
			target_position = p_target.target_marker.global_position
		else:
			target_position = p_target.global_position
	elif p_target is Vector2:
		target_entity = null
		target_position = p_target

	sprite.play("fly")



func _process(delta: float) -> void:
	if arrived or not target_position:
		return

	global_position = global_position.move_toward(
		target_position,
		speed * delta
	)

	if global_position.distance_to(target_position) < 8.0:
		_on_hit()



func _on_hit():
	arrived = true
	sprite.play("hit")

	if _has_prop(ability, "aoe_radius") and ability.aoe_radius > 0:
		_apply_aoe_on_cell()
	else:
		_apply_single_target()

	await sprite.animation_finished
	queue_free()


# ---------- SINGLE TARGET ----------

func _apply_single_target():
	if not target_entity:
		return
	if target_entity.is_dead or target_entity.is_dying:
		return

	# 🔥 STUN — только через caster
	if _has_prop(ability, "type"):
		if ability.type == AbilityData.AbilityType.STUN \
		or ability.type == EnemyAttack.AttackType.STUN:
			if caster and caster.has_method("apply_ability_effect"):
				caster.apply_ability_effect(ability, target_entity)
			return

	if _has_prop(ability, "damage") and ability.damage > 0:
		target_entity.take_damage(ability.damage)

	if _has_prop(ability, "effect_type") and ability.effect_type != 0:
		if target_entity.has_method("apply_status_effect"):
			target_entity.apply_status_effect(
				ability.effect_type,
				ability.effect_damage,
				ability.effect_time
			)



# ---------- AOE ----------

func _apply_aoe_on_cell():
	var grid := get_tree().get_first_node_in_group("grid")
	if not grid:
		return

	if not _has_prop(ability, "aoe_radius"):
		return

	var impact_cell: Vector2i

	if target_entity and "current_cell" in target_entity:
		impact_cell = Vector2i(target_entity.current_cell)
	else:
		impact_cell = _world_to_cell_using_grid(global_position, grid)

	var aoe_cells = grid.get_cells_in_range_for_ability(
		impact_cell,
		ability.aoe_radius
	)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.is_dead or enemy.is_dying:
			continue

		var enemy_cell := Vector2i(enemy.current_cell)

		# 🔥 ВАЖНО: центральная цель всегда получает эффект
		if enemy == target_entity:
			_apply_aoe_effect(enemy)
			continue

		# остальные — по радиусу
		if enemy_cell in aoe_cells:
			_apply_aoe_effect(enemy)

func _get_units_in_aoe(center: Vector2i, radius: int) -> Array:
	var result := []

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.is_dead or enemy.is_dying:
			continue

		var dist := center.distance_to(enemy.current_cell)
		if dist <= radius:
			result.append(enemy)

	return result

func _apply_aoe_effect(enemy):
	if _has_prop(ability, "damage") and ability.damage > 0:
		enemy.take_damage(ability.damage)

	if _has_prop(ability, "effect_type") \
	and ability.effect_type != AbilityData.EffectType.NONE:
		if enemy.has_method("apply_status_effect_from_ability"):
			enemy.apply_status_effect_from_ability(ability)


# ---------- HELPERS ----------

func _world_to_cell_using_grid(pos: Vector2, grid) -> Vector2i:
	var cell_size: Vector2 = Vector2(grid.cell_size)
	return Vector2i(
		floor(pos.x / cell_size.x),
		floor(pos.y / cell_size.y)
	)


func _has_prop(obj: Object, prop: String) -> bool:
	for p in obj.get_property_list():
		if p.name == prop:
			return true
	return false
