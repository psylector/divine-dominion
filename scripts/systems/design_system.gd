## Handles technology research.
## Designers generate design points; when enough accumulate, tech level advances.
class_name DesignSystem
extends Node

## Design points generated per designer per tick.
const DESIGN_RATE: float = 0.05

var _tick_engine: TickEngine


func setup(tick_engine: TickEngine) -> void:
	_tick_engine = tick_engine
	_tick_engine.tick.connect(_on_tick)


func _on_tick() -> void:
	for sector: SectorModel in GameState.world.sectors.values():
		if sector.owner_id < 0 or not sector.has_tower:
			continue
		var designers: int = sector.men[SectorModel.Task.DESIGN]
		if designers <= 0:
			continue

		var player: PlayerModel = GameState.get_player(sector.owner_id)
		if player == null:
			continue

		player.design_points += designers * DESIGN_RATE

		# Check if we can advance to next epoch
		var next_epoch: EpochData = GameState.get_next_epoch(player.id)
		if next_epoch and player.design_points >= next_epoch.design_points_required:
			player.tech_level += 1
			for weapon: WeaponData in next_epoch.available_weapons:
				if weapon.resource_path not in player.designed_weapons:
					player.designed_weapons.append(weapon.resource_path)
					GameState.weapon_designed.emit(player.id, weapon.resource_path)
			GameState.tech_level_advanced.emit(player.id, player.tech_level)
			# If max tech reached, auto-reassign all designers to idle
			if GameState.get_next_epoch(player.id) == null:
				_reassign_designers_to_idle(player.id)


## Moves all designers back to idle across all sectors of a player.
func _reassign_designers_to_idle(player_id: int) -> void:
	for sector: SectorModel in GameState.world.get_player_sectors(player_id):
		var designers: int = sector.men[SectorModel.Task.DESIGN]
		if designers > 0:
			sector.men[SectorModel.Task.DESIGN] = 0
			sector.men[SectorModel.Task.IDLE] += designers
			GameState.men_allocation_changed.emit(sector.grid_pos)
			GameState.men_count_changed.emit(sector.grid_pos)
