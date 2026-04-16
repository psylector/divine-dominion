## Action buttons panel — Attack, Build Tower, Move Men.
## Shows army info, weapon count, valid targets, and combat reports.
extends PanelContainer

signal attack_requested(from_pos: Vector2i, to_pos: Vector2i)
signal build_tower_requested(pos: Vector2i)
signal move_requested(from_pos: Vector2i, to_pos: Vector2i)

enum Mode { IDLE, AWAITING_ATTACK, AWAITING_BUILD, AWAITING_MOVE }

var _selected_sector: Vector2i = Vector2i(-1, -1)
var _mode: Mode = Mode.IDLE

@onready var attack_button: Button = %AttackButton
@onready var build_tower_button: Button = %BuildTowerButton
@onready var move_button: Button = %MoveButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	attack_button.pressed.connect(_on_attack_pressed)
	build_tower_button.pressed.connect(_on_build_tower_pressed)
	move_button.pressed.connect(_on_move_pressed)
	GameState.men_allocation_changed.connect(_on_state_changed)
	GameState.men_count_changed.connect(_on_state_changed)
	GameState.elements_changed.connect(_on_state_changed)
	_update_display()


func _on_state_changed(pos: Vector2i) -> void:
	if pos == _selected_sector and _mode == Mode.IDLE:
		_update_display()


func select_sector(pos: Vector2i) -> void:
	_selected_sector = pos
	_mode = Mode.IDLE
	_update_display()


func deselect() -> void:
	_selected_sector = Vector2i(-1, -1)
	_mode = Mode.IDLE
	_update_display()


func show_combat_report(report: Dictionary) -> void:
	var result: String = "VICTORY!" if report["attacker_won"] else "DEFEAT!"
	var text: String = "=== %s ===\n" % result
	text += "Attacker: %d men (str %.0f)\n" % [report["atk_men_before"], report["atk_strength"]]
	text += (
		"Defender: %d army + %d militia (str %.0f)\n"
		% [report["def_men_before"], report["def_militia"], report["def_strength"]]
	)
	text += "---\n"
	text += "Atk losses: %d | Survivors: %d\n" % [report["atk_losses"], report["atk_survivors"]]
	text += "Def losses: %d | Survivors: %d" % [report["def_losses"], report["def_survivors"]]
	status_label.text = text


func handle_sector_action(pos: Vector2i) -> void:
	match _mode:
		Mode.AWAITING_ATTACK:
			_try_attack(pos)
		Mode.AWAITING_BUILD:
			_try_build(pos)
		Mode.AWAITING_MOVE:
			_try_move(pos)
		Mode.IDLE:
			var sector: SectorModel = GameState.world.get_sector(pos)
			if sector and sector.owner_id == -1:
				build_tower_requested.emit(pos)


func _try_attack(target_pos: Vector2i) -> void:
	_mode = Mode.IDLE
	var neighbors: Array[Vector2i] = GameState.world.get_neighbors(_selected_sector)
	if target_pos not in neighbors:
		status_label.text = "Not adjacent! Only up/down/left/right."
		return
	var target: SectorModel = GameState.world.get_sector(target_pos)
	if target == null:
		return
	if target.owner_id == 0:
		status_label.text = "That's your own sector!"
		return
	if target.owner_id == -1:
		status_label.text = "Use Build Tower for neutral sectors."
		return
	attack_requested.emit(_selected_sector, target_pos)


func _try_build(target_pos: Vector2i) -> void:
	_mode = Mode.IDLE
	var neighbors: Array[Vector2i] = GameState.world.get_neighbors(_selected_sector)
	if target_pos not in neighbors:
		status_label.text = "Not adjacent!"
		return
	var target: SectorModel = GameState.world.get_sector(target_pos)
	if target == null or target.owner_id != -1:
		status_label.text = "Only works on neutral sectors."
		return
	build_tower_requested.emit(target_pos)


func _try_move(target_pos: Vector2i) -> void:
	_mode = Mode.IDLE
	var neighbors: Array[Vector2i] = GameState.world.get_neighbors(_selected_sector)
	if target_pos not in neighbors:
		status_label.text = "Not adjacent!"
		return
	var target: SectorModel = GameState.world.get_sector(target_pos)
	if target == null or target.owner_id != 0:
		status_label.text = "Can only move to your own sectors."
		return
	move_requested.emit(_selected_sector, target_pos)
	_update_display()


func _on_attack_pressed() -> void:
	_mode = Mode.AWAITING_ATTACK
	var targets: PackedStringArray = _get_neighbor_targets(
		func(s: SectorModel) -> bool: return s.owner_id > 0 and s.owner_id != 0
	)
	if targets.is_empty():
		status_label.text = "No enemy neighbors!"
		_mode = Mode.IDLE
	else:
		status_label.text = "Right-click enemy: %s" % " or ".join(targets)


func _on_build_tower_pressed() -> void:
	_mode = Mode.AWAITING_BUILD
	var targets: PackedStringArray = _get_neighbor_targets(
		func(s: SectorModel) -> bool: return s.owner_id == -1
	)
	if targets.is_empty():
		status_label.text = "No neutral neighbors!"
		_mode = Mode.IDLE
	else:
		status_label.text = "Right-click neutral: %s" % " or ".join(targets)


func _on_move_pressed() -> void:
	_mode = Mode.AWAITING_MOVE
	var targets: PackedStringArray = _get_neighbor_targets(
		func(s: SectorModel) -> bool: return s.owner_id == 0
	)
	if targets.is_empty():
		status_label.text = "No friendly neighbors!"
		_mode = Mode.IDLE
	else:
		status_label.text = "Right-click your sector: %s" % " or ".join(targets)


func _get_neighbor_targets(filter: Callable) -> PackedStringArray:
	var result: PackedStringArray = []
	var neighbors: Array[Vector2i] = GameState.world.get_neighbors(_selected_sector)
	for n: Vector2i in neighbors:
		var s: SectorModel = GameState.world.get_sector(n)
		if s and filter.call(s):
			result.append("%d,%d" % [n.x, n.y])
	return result


func _update_display() -> void:
	if _selected_sector == Vector2i(-1, -1):
		attack_button.disabled = true
		build_tower_button.disabled = true
		move_button.disabled = true
		status_label.text = "Select your sector"
		return

	var sector: SectorModel = GameState.world.get_sector(_selected_sector)
	if sector == null or sector.owner_id != 0:
		attack_button.disabled = true
		build_tower_button.disabled = true
		move_button.disabled = true
		status_label.text = "Not your sector"
		return

	var army: int = sector.men[SectorModel.Task.ARMY]
	attack_button.disabled = army <= 0
	build_tower_button.disabled = army <= 0
	move_button.disabled = army <= 0

	var info: String = "Army: %d men\n" % army
	var total_weapons: int = 0
	for weapon: WeaponData in sector.weapons.keys():
		var count: int = sector.weapons[weapon]
		if count > 0:
			info += "%s x%d (dmg %.1f)\n" % [weapon.get_display_name(), count, weapon.damage]
			total_weapons += count

	if army > 0:
		var armed: int = mini(total_weapons, army)
		var unarmed: int = army - armed
		if armed > 0:
			info += "Armed: %d | Unarmed: %d" % [armed, unarmed]
		else:
			info += "All unarmed (base dmg 1.0)"
	else:
		info += "Assign men to Army first"

	status_label.text = info
