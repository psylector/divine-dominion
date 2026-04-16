## Model for a single sector on the island.
## Holds ownership, tower state, element reserves, and men allocation.
class_name SectorModel
extends RefCounted

## Task types for men allocation.
enum Task { IDLE, MINING, DESIGN, MANUFACTURE, ARMY }

## Grid position of this sector.
var grid_pos: Vector2i

## Player ID of the sector owner (-1 = neutral).
var owner_id: int = -1

## Whether a tower exists in this sector.
var has_tower: bool = false

## Remaining element reserves in the ground (available for mining).
var element_reserves: int = 500

## Stockpile of mined elements ready for manufacturing.
var elements_stockpile: int = 0

## Men allocated to each task in this sector.
var men: Dictionary = {
	Task.IDLE: 0,
	Task.MINING: 0,
	Task.DESIGN: 0,
	Task.MANUFACTURE: 0,
	Task.ARMY: 0,
}

## Weapon inventory in this sector (WeaponData -> count).
var weapons: Dictionary = {}

## Progress toward manufacturing current weapon (ticks accumulated).
var manufacture_progress: int = 0


func _init(pos: Vector2i = Vector2i.ZERO) -> void:
	grid_pos = pos


## Returns total number of men in this sector.
func get_total_men() -> int:
	return (
		men[Task.IDLE]
		+ men[Task.MINING]
		+ men[Task.DESIGN]
		+ men[Task.MANUFACTURE]
		+ men[Task.ARMY]
	)


## Sets men for a specific task, returns actual count set (clamped to available).
func set_task_men(task: Task, count: int) -> void:
	men[task] = maxi(0, count)


## Resets all men to idle.
func reset_allocation() -> void:
	var total: int = get_total_men()
	# Rebuild dictionary with only valid enum keys to prevent phantom entries
	men = {
		Task.IDLE: total,
		Task.MINING: 0,
		Task.DESIGN: 0,
		Task.MANUFACTURE: 0,
		Task.ARMY: 0,
	}


## Serializes sector state to a Dictionary.
func to_dict() -> Dictionary:
	var weapons_dict: Dictionary = {}
	for weapon: WeaponData in weapons.keys():
		weapons_dict[weapon.resource_path] = weapons[weapon]
	return {
		"grid_pos": [grid_pos.x, grid_pos.y],
		"owner_id": owner_id,
		"has_tower": has_tower,
		"element_reserves": element_reserves,
		"men":
		{
			"idle": men[Task.IDLE],
			"mining": men[Task.MINING],
			"design": men[Task.DESIGN],
			"manufacture": men[Task.MANUFACTURE],
			"army": men[Task.ARMY],
		},
		"weapons": weapons_dict,
		"manufacture_progress": manufacture_progress,
	}
