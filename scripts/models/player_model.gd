## Model for a single player (human or AI).
## Tracks tech progress, designed weapons, and global resources.
class_name PlayerModel
extends RefCounted

## Unique player ID (0 = human, 1 = AI).
var id: int

## Display name.
var player_name: String

## Player color for UI.
var color: Color

## Current tech level index (0-based, indexes into epoch array).
var tech_level: int = 0

## Accumulated design points toward next tech level.
var design_points: float = 0.0

## Set of WeaponData resource paths that have been designed (unlocked for manufacture).
var designed_weapons: Array[String] = []

## Whether this player is controlled by AI.
var is_ai: bool = false


func _init(p_id: int, p_name: String, p_color: Color, p_is_ai: bool = false) -> void:
	id = p_id
	player_name = p_name
	color = p_color
	is_ai = p_is_ai


## Serializes player state to a Dictionary.
func to_dict() -> Dictionary:
	return {
		"id": id,
		"player_name": player_name,
		"tech_level": tech_level,
		"design_points": design_points,
		"designed_weapons": designed_weapons,
		"is_ai": is_ai,
	}
