## Data resource for a weapon type.
## Defines combat stats and manufacturing requirements.
class_name WeaponData
extends Resource

## Display name of the weapon.
@export var name: String = ""

## UTF icon for display (e.g. 🪨, 🏹, 🔱).
@export var icon: String = "⚔"

## Damage multiplier applied per armed man in combat.
@export var damage: float = 1.0

## Number of elements required to manufacture one unit.
@export var element_cost: int = 1

## Number of ticks needed to manufacture one unit (per worker).
@export var manufacture_ticks: int = 10


## Returns icon + name with star rating for strength.
func get_display_name() -> String:
	var stars: String = ""
	if damage < 1.5:
		stars = "★"
	elif damage < 2.0:
		stars = "★★"
	elif damage < 3.0:
		stars = "★★★"
	else:
		stars = "★★★★"
	return "%s %s %s" % [icon, name, stars]
