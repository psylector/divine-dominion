## Handles element extraction from sectors.
## Mining men extract elements from sector reserves each tick.
class_name MiningSystem
extends Node

## Elements extracted per miner per tick.
const MINING_RATE: float = 0.1

## Accumulated fractional elements per sector (Vector2i -> float).
var _fractional: Dictionary = {}

var _tick_engine: TickEngine


func setup(tick_engine: TickEngine) -> void:
	_tick_engine = tick_engine
	_tick_engine.tick.connect(_on_tick)


func _on_tick() -> void:
	for sector: SectorModel in GameState.world.sectors.values():
		if sector.owner_id < 0 or not sector.has_tower:
			continue
		var miners: int = sector.men[SectorModel.Task.MINING]
		if miners <= 0 or sector.element_reserves <= 0:
			continue

		var mined: float = miners * MINING_RATE
		var acc: float = _fractional.get(sector.grid_pos, 0.0) + mined
		var whole: int = int(acc)
		_fractional[sector.grid_pos] = acc - whole

		# Clamp to available reserves
		whole = mini(whole, sector.element_reserves)
		if whole > 0:
			sector.element_reserves -= whole
			sector.elements_stockpile += whole
			GameState.elements_changed.emit(sector.grid_pos)
