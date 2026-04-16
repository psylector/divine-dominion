## Simple state-machine AI opponent.
## Evaluates state every few seconds and picks actions for player 1.
class_name AISystem
extends Node

enum State { EXPAND, RESEARCH, DEFEND, ATTACK }

const AI_PLAYER_ID: int = 1
const DECISION_INTERVAL_MIN: float = 8.0
const DECISION_INTERVAL_MAX: float = 15.0

## Fraction of men to keep idle for reproduction.
const IDLE_RESERVE_RATIO: float = 0.3
## Minimum army size to attack.
const MIN_ARMY_TO_ATTACK: int = 30
## Minimum army men already allocated before AI can expand into neutral sector.
const MIN_ARMY_TO_EXPAND: int = 20
## Seconds before AI starts making decisions (grace period for player).
const STARTUP_DELAY: float = 20.0

var _timer: float = 0.0
var _next_decision: float = STARTUP_DELAY
var _combat_system: CombatSystem


func _ready() -> void:
	_combat_system = get_parent().get_node("CombatSystem") as CombatSystem


func _process(delta: float) -> void:
	if GameState.paused or GameState.game_ended:
		return

	_timer += delta * GameState.speed
	if _timer < _next_decision:
		return
	_timer = 0.0
	_next_decision = randf_range(DECISION_INTERVAL_MIN, DECISION_INTERVAL_MAX)

	_make_decision()


func _make_decision() -> void:
	var state: State = _evaluate_state()

	match state:
		State.EXPAND:
			_do_expand()
		State.RESEARCH:
			_do_research()
		State.DEFEND:
			_do_defend()
		State.ATTACK:
			_do_attack()


func _evaluate_state() -> State:
	var my_sectors: Array[SectorModel] = GameState.world.get_player_sectors(AI_PLAYER_ID)
	if my_sectors.is_empty():
		return State.DEFEND

	# Check if under threat (enemy has army in adjacent sector)
	for sector: SectorModel in my_sectors:
		var neighbors: Array[Vector2i] = GameState.world.get_neighbors(sector.grid_pos)
		for neighbor_pos: Vector2i in neighbors:
			var neighbor: SectorModel = GameState.world.get_sector(neighbor_pos)
			if neighbor and neighbor.owner_id == 0 and neighbor.men[SectorModel.Task.ARMY] > 10:
				return State.DEFEND

	# Check tech level — research if behind or early game
	var player: PlayerModel = GameState.get_player(AI_PLAYER_ID)
	var human: PlayerModel = GameState.get_player(0)
	if player and human and player.tech_level < human.tech_level:
		return State.RESEARCH
	if player and player.tech_level < 1:
		return State.RESEARCH

	# Check if there are neutral sectors to expand into (only if we have army ready)
	var neutral: Array[SectorModel] = GameState.world.get_neutral_sectors()
	if not neutral.is_empty():
		for n_sector: SectorModel in neutral:
			var neighbors: Array[Vector2i] = GameState.world.get_neighbors(n_sector.grid_pos)
			for neighbor_pos: Vector2i in neighbors:
				var neighbor: SectorModel = GameState.world.get_sector(neighbor_pos)
				if neighbor and neighbor.owner_id == AI_PLAYER_ID:
					if neighbor.men[SectorModel.Task.ARMY] >= MIN_ARMY_TO_EXPAND:
						return State.EXPAND

	# Default: build up army and attack when ready
	var total_army: int = 0
	for sector: SectorModel in my_sectors:
		total_army += sector.men[SectorModel.Task.ARMY]

	if total_army >= MIN_ARMY_TO_ATTACK:
		return State.ATTACK

	# Not enough army yet — keep building up (allocate to army via ATTACK state)
	return State.ATTACK


func _do_expand() -> void:
	## Only move EXISTING army men to neutral sector — no instant allocation.
	var my_sectors: Array[SectorModel] = GameState.world.get_player_sectors(AI_PLAYER_ID)
	for sector: SectorModel in my_sectors:
		if sector.men[SectorModel.Task.ARMY] < MIN_ARMY_TO_EXPAND:
			continue
		var neighbors: Array[Vector2i] = GameState.world.get_neighbors(sector.grid_pos)
		for neighbor_pos: Vector2i in neighbors:
			var neighbor: SectorModel = GameState.world.get_sector(neighbor_pos)
			if neighbor and neighbor.owner_id == -1:
				# Move army to new sector
				var army_men: int = sector.men[SectorModel.Task.ARMY]
				sector.men[SectorModel.Task.ARMY] = 0
				GameState.world.capture_sector(neighbor_pos, AI_PLAYER_ID)
				neighbor = GameState.world.get_sector(neighbor_pos)
				neighbor.men[SectorModel.Task.IDLE] = army_men
				GameState.sector_captured.emit(neighbor_pos, AI_PLAYER_ID)
				GameState.men_count_changed.emit(sector.grid_pos)
				GameState.men_count_changed.emit(neighbor_pos)
				return


func _do_research() -> void:
	## Allocate men to design + mining in the most populated sector.
	var my_sectors: Array[SectorModel] = GameState.world.get_player_sectors(AI_PLAYER_ID)
	var best_sector: SectorModel = null
	var best_men: int = 0
	for sector: SectorModel in my_sectors:
		var total: int = sector.get_total_men()
		if total > best_men:
			best_men = total
			best_sector = sector

	if best_sector == null:
		return

	var total: int = best_sector.get_total_men()
	var idle_count: int = maxi(int(total * IDLE_RESERVE_RATIO), 10)
	var remaining: int = total - idle_count

	var design_count: int = remaining / 2
	var mining_count: int = remaining - design_count

	best_sector.men[SectorModel.Task.IDLE] = idle_count
	best_sector.men[SectorModel.Task.DESIGN] = design_count
	best_sector.men[SectorModel.Task.MINING] = mining_count
	best_sector.men[SectorModel.Task.MANUFACTURE] = 0
	best_sector.men[SectorModel.Task.ARMY] = 0
	GameState.men_allocation_changed.emit(best_sector.grid_pos)


func _do_defend() -> void:
	## Pull men into army in threatened sectors.
	var my_sectors: Array[SectorModel] = GameState.world.get_player_sectors(AI_PLAYER_ID)
	for sector: SectorModel in my_sectors:
		var total: int = sector.get_total_men()
		var idle_count: int = maxi(int(total * 0.15), 5)
		var army_count: int = total - idle_count

		sector.men[SectorModel.Task.IDLE] = idle_count
		sector.men[SectorModel.Task.MINING] = 0
		sector.men[SectorModel.Task.DESIGN] = 0
		sector.men[SectorModel.Task.MANUFACTURE] = 0
		sector.men[SectorModel.Task.ARMY] = army_count
		GameState.men_allocation_changed.emit(sector.grid_pos)


func _do_attack() -> void:
	var my_sectors: Array[SectorModel] = GameState.world.get_player_sectors(AI_PLAYER_ID)

	# Allocate men: idle reserve + army + some mining/manufacture
	for sector: SectorModel in my_sectors:
		var total: int = sector.get_total_men()
		var idle_count: int = maxi(int(total * IDLE_RESERVE_RATIO), 10)
		var remaining: int = total - idle_count

		var army_count: int = remaining / 3
		var mining_count: int = remaining / 3
		var manufacture_count: int = remaining - army_count - mining_count

		sector.men[SectorModel.Task.IDLE] = idle_count
		sector.men[SectorModel.Task.MINING] = mining_count
		sector.men[SectorModel.Task.DESIGN] = 0
		sector.men[SectorModel.Task.MANUFACTURE] = manufacture_count
		sector.men[SectorModel.Task.ARMY] = army_count
		GameState.men_allocation_changed.emit(sector.grid_pos)

	# Only attack if army is large enough
	for sector: SectorModel in my_sectors:
		if sector.men[SectorModel.Task.ARMY] < MIN_ARMY_TO_ATTACK:
			continue
		var neighbors: Array[Vector2i] = GameState.world.get_neighbors(sector.grid_pos)
		var weakest_pos: Vector2i = Vector2i(-1, -1)
		var weakest_strength: float = INF

		for neighbor_pos: Vector2i in neighbors:
			var neighbor: SectorModel = GameState.world.get_sector(neighbor_pos)
			if neighbor and neighbor.owner_id == 0:
				var strength: float = _combat_system.get_sector_strength(neighbor)
				if strength < weakest_strength:
					weakest_strength = strength
					weakest_pos = neighbor_pos

		if weakest_pos != Vector2i(-1, -1):
			_combat_system.resolve_attack(sector.grid_pos, weakest_pos)
			return
