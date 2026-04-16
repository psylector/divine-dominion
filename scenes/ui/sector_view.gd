## Visual representation of a single sector on the island grid.
## Displays owner color, men count, and tech level. Handles click selection.
extends ColorRect

signal sector_selected(pos: Vector2i)
signal sector_action(pos: Vector2i)

const NEUTRAL_COLOR: Color = Color(0.4, 0.4, 0.4)
const SELECTED_BORDER_COLOR: Color = Color.YELLOW

var sector_pos: Vector2i
var is_selected: bool = false

@onready var label: Label = $Label
@onready var border: ReferenceRect = $Border


func setup(pos: Vector2i) -> void:
	sector_pos = pos
	GameState.men_count_changed.connect(_on_state_changed)
	GameState.men_allocation_changed.connect(_on_state_changed)
	GameState.sector_captured.connect(_on_sector_captured)
	GameState.elements_changed.connect(_on_state_changed)
	GameState.tech_level_advanced.connect(_on_tech_changed)
	refresh()


func refresh() -> void:
	var sector: SectorModel = GameState.world.get_sector(sector_pos)
	if sector == null:
		return

	# Set color based on owner
	if sector.owner_id >= 0:
		var player: PlayerModel = GameState.get_player(sector.owner_id)
		color = player.color if player else NEUTRAL_COLOR
	else:
		color = NEUTRAL_COLOR

	# Update label
	var text: String = "Sector %d,%d\n" % [sector_pos.x, sector_pos.y]
	if sector.owner_id >= 0:
		var epoch: EpochData = GameState.get_player_epoch(sector.owner_id)
		text += "♂ %d" % sector.get_total_men()
		var army: int = sector.men[SectorModel.Task.ARMY]
		if army > 0:
			text += " (⚔ %d)" % army
		text += "\n"
		text += "▲ %s\n" % epoch.name
		text += "⛏ %d | 📦 %d\n" % [sector.element_reserves, sector.elements_stockpile]
		# Show weapon inventory
		var weapon_count: int = 0
		var weapon_text: String = ""
		for weapon: WeaponData in sector.weapons.keys():
			var count: int = sector.weapons[weapon]
			if count > 0:
				weapon_count += count
				weapon_text += "%s%s:%d " % [weapon.icon, weapon.name, count]
		if weapon_count > 0:
			text += weapon_text.strip_edges()
		else:
			text += "No weapons"
	else:
		text += "(Neutral)\n⛏ %d" % sector.element_reserves
	label.text = text

	# Border highlight
	if border:
		border.editor_only = false
		border.border_color = SELECTED_BORDER_COLOR if is_selected else Color(0, 0, 0, 0.3)
		border.border_width = 3.0 if is_selected else 1.0


func set_selected(selected: bool) -> void:
	is_selected = selected
	if border:
		border.border_color = SELECTED_BORDER_COLOR if is_selected else Color(0, 0, 0, 0.3)
		border.border_width = 3.0 if is_selected else 1.0


func _on_state_changed(pos: Vector2i) -> void:
	if pos == sector_pos:
		refresh()


func _on_sector_captured(pos: Vector2i, _new_owner: int) -> void:
	if pos == sector_pos:
		refresh()


func _on_tech_changed(_player_id: int, _new_level: int) -> void:
	refresh()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			sector_selected.emit(sector_pos)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			sector_action.emit(sector_pos)
