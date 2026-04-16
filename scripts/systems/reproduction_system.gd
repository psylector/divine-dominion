## Handles population growth in sectors with idle men.
## More idle men = faster reproduction. Fully deterministic (no randomness).
class_name ReproductionSystem
extends Node

## Growth per idle man per tick (fractional, accumulated deterministically).
const REPRODUCTION_RATE: float = 0.002

## Accumulated fractional growth per sector (Vector2i -> float).
var _accumulator: Dictionary = {}

var _tick_engine: TickEngine


func setup(tick_engine: TickEngine) -> void:
	_tick_engine = tick_engine
	_tick_engine.tick.connect(_on_tick)


func _on_tick() -> void:
	for sector: SectorModel in GameState.world.sectors.values():
		if sector.owner_id < 0 or not sector.has_tower:
			continue
		var idle_men: int = sector.men[SectorModel.Task.IDLE]
		if idle_men <= 0:
			continue

		var acc: float = _accumulator.get(sector.grid_pos, 0.0) + idle_men * REPRODUCTION_RATE
		var new_men: int = int(acc)
		_accumulator[sector.grid_pos] = acc - new_men

		if new_men > 0:
			sector.men[SectorModel.Task.IDLE] += new_men
			GameState.men_count_changed.emit(sector.grid_pos)
