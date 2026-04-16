## Drives the game loop at a fixed tick rate.
## Calls all subsystems each tick and respects pause/speed settings.
class_name TickEngine
extends Node

## Emitted every game tick so systems can update.
signal tick

## Base ticks per second (before speed multiplier).
const BASE_TICK_RATE: float = 4.0

var _accumulator: float = 0.0


func _process(delta: float) -> void:
	if GameState.paused or GameState.game_ended:
		return

	_accumulator += delta * GameState.speed
	var tick_duration: float = 1.0 / BASE_TICK_RATE

	while _accumulator >= tick_duration:
		_accumulator -= tick_duration
		tick.emit()
