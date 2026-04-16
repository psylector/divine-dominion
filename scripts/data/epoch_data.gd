## Data resource for a tech epoch (era).
## Defines what becomes available at each technology level.
class_name EpochData
extends Resource

## Display name of the epoch (e.g. "9500 BC").
@export var name: String = ""

## Tech level index (1-based).
@export var level: int = 1

## Design points required to unlock this epoch.
@export var design_points_required: int = 0

## Weapons available once this epoch is reached.
@export var available_weapons: Array[WeaponData] = []
