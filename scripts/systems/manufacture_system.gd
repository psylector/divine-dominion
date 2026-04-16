## Handles weapon manufacturing in sectors.
## Workers consume elements to produce weapons over time.
class_name ManufactureSystem
extends Node

var _tick_engine: TickEngine


func setup(tick_engine: TickEngine) -> void:
	_tick_engine = tick_engine
	_tick_engine.tick.connect(_on_tick)


func _on_tick() -> void:
	for sector: SectorModel in GameState.world.sectors.values():
		if sector.owner_id < 0 or not sector.has_tower:
			continue
		var workers: int = sector.men[SectorModel.Task.MANUFACTURE]
		if workers <= 0:
			continue

		var player: PlayerModel = GameState.get_player(sector.owner_id)
		if player == null:
			continue

		# Find the best weapon the player can manufacture
		var weapon: WeaponData = _get_best_weapon(player)
		if weapon == null:
			continue

		# Check if sector has enough elements
		if sector.elements_stockpile < weapon.element_cost:
			continue

		# Accumulate manufacture progress (more workers = faster)
		sector.manufacture_progress += workers
		if sector.manufacture_progress >= weapon.manufacture_ticks:
			sector.manufacture_progress -= weapon.manufacture_ticks
			sector.elements_stockpile -= weapon.element_cost
			# Add weapon to sector inventory
			if weapon not in sector.weapons:
				sector.weapons[weapon] = 0
			sector.weapons[weapon] += 1
			GameState.elements_changed.emit(sector.grid_pos)


## Returns the best (highest damage) weapon the player has designed.
func _get_best_weapon(player: PlayerModel) -> WeaponData:
	var best: WeaponData = null
	for path: String in player.designed_weapons:
		var weapon: WeaponData = load(path) as WeaponData
		if weapon and (best == null or weapon.damage > best.damage):
			best = weapon
	return best
