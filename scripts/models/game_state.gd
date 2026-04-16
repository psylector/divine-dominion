## Global game state singleton (autoload).
## Owns the world model, players, epoch data, and emits gameplay signals.
extends Node

#region Signals
signal sector_captured(sector_pos: Vector2i, new_owner_id: int)
signal tech_level_advanced(player_id: int, new_level: int)
signal weapon_designed(player_id: int, weapon_path: String)
signal combat_resolved(attacker_pos: Vector2i, defender_pos: Vector2i, attacker_won: bool)
signal men_allocation_changed(sector_pos: Vector2i)
signal men_count_changed(sector_pos: Vector2i)
signal elements_changed(sector_pos: Vector2i)
signal game_over(winner_id: int)
#endregion

## The world (island) model.
var world: WorldModel

## Players indexed by ID.
var players: Dictionary = {}  # int -> PlayerModel

## Ordered list of all epochs (tech levels).
var epochs: Array[EpochData] = []

## Whether the game is currently paused.
var paused: bool = false

## Game speed multiplier (1, 2, or 4).
var speed: int = 1

## Whether the game has ended.
var game_ended: bool = false


func _ready() -> void:
	_load_epochs()
	_setup_game()


## Loads epoch resources in order.
func _load_epochs() -> void:
	var epoch_paths: Array[String] = [
		"res://resources/epochs/epoch_9500bc.tres",
		"res://resources/epochs/epoch_9000bc.tres",
		"res://resources/epochs/epoch_8000bc.tres",
	]
	for path: String in epoch_paths:
		var epoch: EpochData = load(path) as EpochData
		if epoch:
			epochs.append(epoch)


## Sets up initial game state: 2 players, 4 sectors.
func _setup_game() -> void:
	world = WorldModel.new(Vector2i(2, 2))

	# Player 0 — human (blue)
	var human: PlayerModel = PlayerModel.new(0, "Player", Color.DODGER_BLUE)
	players[0] = human

	# Player 1 — AI (red)
	var ai: PlayerModel = PlayerModel.new(1, "AI", Color.CRIMSON, true)
	players[1] = ai

	# Player starts top-left, AI starts bottom-right
	var player_sector: SectorModel = world.get_sector(Vector2i(0, 0))
	player_sector.owner_id = 0
	player_sector.has_tower = true
	player_sector.men[SectorModel.Task.IDLE] = 100

	var ai_sector: SectorModel = world.get_sector(Vector2i(1, 1))
	ai_sector.owner_id = 1
	ai_sector.has_tower = true
	ai_sector.men[SectorModel.Task.IDLE] = 100

	# Unlock starting epoch weapons for both players
	if epochs.size() > 0:
		var starting_epoch: EpochData = epochs[0]
		for player: PlayerModel in players.values():
			for weapon: WeaponData in starting_epoch.available_weapons:
				if weapon.resource_path not in player.designed_weapons:
					player.designed_weapons.append(weapon.resource_path)


## Returns the current epoch for a player.
func get_player_epoch(player_id: int) -> EpochData:
	var player: PlayerModel = players.get(player_id) as PlayerModel
	if player == null or player.tech_level >= epochs.size():
		return epochs.back() as EpochData
	return epochs[player.tech_level]


## Returns the next epoch for a player, or null if at max.
func get_next_epoch(player_id: int) -> EpochData:
	var player: PlayerModel = players.get(player_id) as PlayerModel
	if player == null:
		return null
	var next_level: int = player.tech_level + 1
	if next_level >= epochs.size():
		return null
	return epochs[next_level]


## Returns the player model by ID.
func get_player(player_id: int) -> PlayerModel:
	return players.get(player_id) as PlayerModel


## Checks victory/defeat conditions.
func check_game_over() -> void:
	if game_ended:
		return
	for player: PlayerModel in players.values():
		var owned: Array[SectorModel] = world.get_player_sectors(player.id)
		if owned.size() == world.sectors.size():
			game_ended = true
			game_over.emit(player.id)
			return
	# Check if any player has zero sectors AND zero total men
	for player: PlayerModel in players.values():
		var owned: Array[SectorModel] = world.get_player_sectors(player.id)
		if owned.is_empty():
			# Player has no sectors — they lose
			var winner_id: int = 1 - player.id  # Works for 2 players
			game_ended = true
			game_over.emit(winner_id)
			return


## Serializes entire game state.
func to_dict() -> Dictionary:
	var players_dict: Dictionary = {}
	for pid: int in players.keys():
		players_dict[str(pid)] = players[pid].to_dict()
	return {
		"world": world.to_dict(),
		"players": players_dict,
		"paused": paused,
		"speed": speed,
	}
