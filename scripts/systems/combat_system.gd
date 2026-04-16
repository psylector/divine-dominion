## Resolves combat between sectors.
## Strength = men * best weapon damage multiplier.
## Both sides take casualties proportional to the strength difference.
class_name CombatSystem
extends Node

## Emitted with detailed combat results for UI display.
signal combat_report(report: Dictionary)


## Calculates the combat strength of a sector.
func get_sector_strength(sector: SectorModel) -> float:
	var army_men: int = sector.men[SectorModel.Task.ARMY]
	if army_men <= 0:
		return 0.0

	var best_damage: float = 1.0  # Unarmed base
	var armed_count: int = 0
	for weapon: WeaponData in sector.weapons.keys():
		var count: int = sector.weapons[weapon]
		if count > 0 and weapon.damage > best_damage:
			best_damage = weapon.damage
			armed_count = mini(count, army_men)

	var unarmed: int = army_men - armed_count
	return armed_count * best_damage + unarmed * 1.0


## Resolves an attack from one sector to an adjacent sector.
## Returns true if the attacker wins.
func resolve_attack(attacker_pos: Vector2i, defender_pos: Vector2i) -> bool:
	var attacker: SectorModel = GameState.world.get_sector(attacker_pos)
	var defender: SectorModel = GameState.world.get_sector(defender_pos)
	if attacker == null or defender == null:
		return false

	var neighbors: Array[Vector2i] = GameState.world.get_neighbors(attacker_pos)
	if defender_pos not in neighbors:
		return false

	if attacker.men[SectorModel.Task.ARMY] <= 0:
		return false

	var atk_men: int = attacker.men[SectorModel.Task.ARMY]
	var def_men: int = defender.men[SectorModel.Task.ARMY]
	# Defenders also count all non-army men as militia (weaker)
	var def_militia: int = defender.get_total_men() - def_men

	var attack_strength: float = get_sector_strength(attacker)
	var defend_strength: float = get_sector_strength(defender) + def_militia * 0.5

	# Defenders get tower bonus
	if defender.has_tower:
		defend_strength *= 1.2

	# Randomness ±15%
	var atk_roll: float = randf_range(0.85, 1.15)
	var def_roll: float = randf_range(0.85, 1.15)
	var final_atk: float = attack_strength * atk_roll
	var final_def: float = defend_strength * def_roll

	var attacker_won: bool = final_atk > final_def

	# Calculate casualties — loser takes heavy losses, winner takes some
	var strength_ratio: float
	var atk_losses: int
	var def_losses: int

	if attacker_won:
		strength_ratio = final_def / maxf(final_atk, 0.1)
		atk_losses = int(atk_men * strength_ratio * 0.4)
		def_losses = def_men + def_militia  # Defender loses everything
	else:
		strength_ratio = final_atk / maxf(final_def, 0.1)
		atk_losses = atk_men  # Attacker loses everything
		def_losses = int((def_men + def_militia) * strength_ratio * 0.4)

	# Build report before modifying state
	var report: Dictionary = {
		"attacker_pos": attacker_pos,
		"defender_pos": defender_pos,
		"attacker_won": attacker_won,
		"atk_men_before": atk_men,
		"atk_strength": attack_strength,
		"def_men_before": def_men,
		"def_militia": def_militia,
		"def_strength": defend_strength,
		"atk_losses": atk_losses,
		"def_losses": def_losses,
		"atk_survivors": atk_men - atk_losses,
		"def_survivors": (def_men + def_militia) - def_losses,
	}

	if attacker_won:
		var survivors: int = atk_men - atk_losses
		var atk_weapons: Dictionary = attacker.weapons.duplicate()

		# Clear attacker's army
		attacker.men[SectorModel.Task.ARMY] = 0
		attacker.weapons.clear()

		# Capture sector — wipes defender
		GameState.world.capture_sector(defender_pos, attacker.owner_id)
		defender.men[SectorModel.Task.IDLE] = survivors
		defender.weapons = atk_weapons

		GameState.sector_captured.emit(defender_pos, attacker.owner_id)
	else:
		# Attacker loses all army
		attacker.men[SectorModel.Task.ARMY] = 0
		attacker.weapons.clear()

		# Defender takes some losses from army first, then militia
		var remaining_def_losses: int = def_losses
		var army_killed: int = mini(remaining_def_losses, def_men)
		defender.men[SectorModel.Task.ARMY] -= army_killed
		remaining_def_losses -= army_killed
		# Remaining losses come from idle
		if remaining_def_losses > 0:
			var idle_killed: int = mini(remaining_def_losses, defender.men[SectorModel.Task.IDLE])
			defender.men[SectorModel.Task.IDLE] -= idle_killed

	GameState.men_count_changed.emit(attacker_pos)
	GameState.men_count_changed.emit(defender_pos)
	GameState.combat_resolved.emit(attacker_pos, defender_pos, attacker_won)
	combat_report.emit(report)
	GameState.check_game_over()

	return attacker_won


## Moves army men from one owned sector to an adjacent owned sector.
func move_men(from_pos: Vector2i, to_pos: Vector2i, count: int) -> bool:
	var from_sector: SectorModel = GameState.world.get_sector(from_pos)
	var to_sector: SectorModel = GameState.world.get_sector(to_pos)
	if from_sector == null or to_sector == null:
		return false

	# Must be adjacent
	var neighbors: Array[Vector2i] = GameState.world.get_neighbors(from_pos)
	if to_pos not in neighbors:
		return false

	# Must both be owned by the same player
	if from_sector.owner_id != to_sector.owner_id:
		return false

	# Move from army
	var available: int = from_sector.men[SectorModel.Task.ARMY]
	var actual: int = mini(count, available)
	if actual <= 0:
		return false

	from_sector.men[SectorModel.Task.ARMY] -= actual
	to_sector.men[SectorModel.Task.IDLE] += actual

	GameState.men_count_changed.emit(from_pos)
	GameState.men_count_changed.emit(to_pos)
	GameState.men_allocation_changed.emit(from_pos)
	return true
