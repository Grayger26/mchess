extends Node2D
class_name Tilemaps

enum SEASON { WINTER, SPRING, SUMMER, AUTUMN }

@export var season: SEASON = SEASON.WINTER

@onready var ground: TileMapLayer = $ground
@onready var obstacles: TileMapLayer = $obstacles
@onready var visuals: TileMapLayer = $visuals


const SEASON_SOURCES := {
	SEASON.WINTER: 0,
	SEASON.SPRING: 1,
	SEASON.SUMMER: 2,
	SEASON.AUTUMN: 3,
}

func _ready() -> void:
	_apply_season(season)


func _apply_season(season_type: SEASON) -> void:
	var new_source_id = SEASON_SOURCES[season_type]

	for layer in [ground, obstacles, visuals]:
		_replace_tileset_source(layer, new_source_id)



func _replace_tileset_source(layer: TileMapLayer, new_source_id: int) -> void:
	var used_cells := layer.get_used_cells()

	for cell in used_cells:
		var old_source := layer.get_cell_source_id(cell)
		if old_source == -1:
			continue

		# если уже нужный сезон — пропускаем
		if old_source == new_source_id:
			continue

		var atlas_coords := layer.get_cell_atlas_coords(cell)
		var alternative := layer.get_cell_alternative_tile(cell)

		layer.set_cell(cell, new_source_id, atlas_coords, alternative)
