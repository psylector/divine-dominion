## Model for the game world — the island and its sectors.
## Provides queries and mutations on sector state.
class_name WorldModel
extends RefCounted

## Grid dimensions of the island.
var grid_size: Vector2i

## All sectors indexed by grid position.
var sectors: Dictionary = {}  # Vector2i -> SectorModel


func _init(size: Vector2i = Vector2i(2, 2)) -> void:
	grid_size = size
	for x: int in range(size.x):
		for y: int in range(size.y):
			var pos: Vector2i = Vector2i(x, y)
			sectors[pos] = SectorModel.new(pos)


## Returns the sector at the given grid position, or null.
func get_sector(pos: Vector2i) -> SectorModel:
	return sectors.get(pos) as SectorModel


## Returns all sectors owned by the given player.
func get_player_sectors(player_id: int) -> Array[SectorModel]:
	var result: Array[SectorModel] = []
	for sector: SectorModel in sectors.values():
		if sector.owner_id == player_id:
			result.append(sector)
	return result


## Returns neighboring sector positions (4-directional, within bounds).
func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var offsets: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, 0), Vector2i(1, 0),
	]
	for offset: Vector2i in offsets:
		var neighbor: Vector2i = pos + offset
		if sectors.has(neighbor):
			result.append(neighbor)
	return result


## Returns all neutral (unowned) sectors.
func get_neutral_sectors() -> Array[SectorModel]:
	var result: Array[SectorModel] = []
	for sector: SectorModel in sectors.values():
		if sector.owner_id == -1:
			result.append(sector)
	return result


## Transfers sector ownership. Destroys tower if previous owner loses it.
func capture_sector(pos: Vector2i, new_owner_id: int) -> void:
	var sector: SectorModel = get_sector(pos)
	if sector == null:
		return
	sector.owner_id = new_owner_id
	sector.has_tower = true
	sector.reset_allocation()
	sector.weapons.clear()
	sector.manufacture_progress = 0


## Serializes world state to a Dictionary.
func to_dict() -> Dictionary:
	var sectors_dict: Dictionary = {}
	for pos: Vector2i in sectors.keys():
		sectors_dict["%d,%d" % [pos.x, pos.y]] = sectors[pos].to_dict()
	return {
		"grid_size": [grid_size.x, grid_size.y],
		"sectors": sectors_dict,
	}
