## Root scene — assembles the UI layout and initializes game systems.
extends Control

var _selected_sector: Vector2i = Vector2i(-1, -1)
var _sector_views: Dictionary = {}  # Vector2i -> SectorView node
var _was_paused_before_report: bool = false

@onready var island_grid: GridContainer = %IslandGrid
@onready var allocation_panel: PanelContainer = %AllocationPanel
@onready var action_panel: PanelContainer = %ActionPanel
@onready var resource_panel: PanelContainer = %ResourcePanel
@onready var speed_controls: HBoxContainer = %SpeedControls
@onready var tick_engine: TickEngine = %TickEngine
@onready var reproduction_system: ReproductionSystem = %ReproductionSystem
@onready var mining_system: MiningSystem = %MiningSystem
@onready var design_system: DesignSystem = %DesignSystem
@onready var manufacture_system: ManufactureSystem = %ManufactureSystem
@onready var combat_system: CombatSystem = %CombatSystem
@onready var ai_system: Node = %AISystem
@onready var combat_report_popup: PanelContainer = %CombatReportPopup
@onready var report_label: Label = %ReportLabel
@onready var report_ok_button: Button = %ReportOkButton


func _ready() -> void:
	reproduction_system.setup(tick_engine)
	mining_system.setup(tick_engine)
	design_system.setup(tick_engine)
	manufacture_system.setup(tick_engine)

	# Create sector views
	var SECTOR_SCENE: PackedScene = preload("res://scenes/ui/sector_view.tscn")
	island_grid.columns = GameState.world.grid_size.x

	for y: int in range(GameState.world.grid_size.y):
		for x: int in range(GameState.world.grid_size.x):
			var pos: Vector2i = Vector2i(x, y)
			var view: ColorRect = SECTOR_SCENE.instantiate()
			island_grid.add_child(view)
			view.setup(pos)
			view.sector_selected.connect(_on_sector_selected)
			view.sector_action.connect(_on_sector_action)
			_sector_views[pos] = view

	# Connect action panel signals
	action_panel.attack_requested.connect(_on_attack_requested)
	action_panel.build_tower_requested.connect(_on_build_tower_requested)
	action_panel.move_requested.connect(_on_move_requested)

	# Connect combat report
	combat_system.combat_report.connect(_on_combat_report)
	report_ok_button.pressed.connect(_on_report_dismissed)
	combat_report_popup.visible = false


func _on_sector_selected(pos: Vector2i) -> void:
	if _selected_sector in _sector_views:
		_sector_views[_selected_sector].set_selected(false)

	_selected_sector = pos
	_sector_views[pos].set_selected(true)
	allocation_panel.select_sector(pos)
	action_panel.select_sector(pos)


func _on_sector_action(pos: Vector2i) -> void:
	action_panel.handle_sector_action(pos)


func _on_attack_requested(from_pos: Vector2i, to_pos: Vector2i) -> void:
	combat_system.resolve_attack(from_pos, to_pos)
	_refresh_all_views()


func _on_move_requested(from_pos: Vector2i, to_pos: Vector2i) -> void:
	var sector: SectorModel = GameState.world.get_sector(from_pos)
	if sector == null:
		return
	var army: int = sector.men[SectorModel.Task.ARMY]
	combat_system.move_men(from_pos, to_pos, army)
	_refresh_all_views()


func _on_build_tower_requested(pos: Vector2i) -> void:
	var target: SectorModel = GameState.world.get_sector(pos)
	if target == null or target.owner_id != -1:
		return

	var neighbors: Array[Vector2i] = GameState.world.get_neighbors(pos)
	for neighbor_pos: Vector2i in neighbors:
		var neighbor: SectorModel = GameState.world.get_sector(neighbor_pos)
		if neighbor and neighbor.owner_id == 0 and neighbor.men[SectorModel.Task.ARMY] > 0:
			var army_men: int = neighbor.men[SectorModel.Task.ARMY]
			neighbor.men[SectorModel.Task.ARMY] = 0
			GameState.world.capture_sector(pos, 0)
			target = GameState.world.get_sector(pos)
			target.men[SectorModel.Task.IDLE] = army_men
			GameState.sector_captured.emit(pos, 0)
			GameState.men_count_changed.emit(neighbor_pos)
			GameState.men_count_changed.emit(pos)
			_refresh_all_views()
			break


func _on_combat_report(report: Dictionary) -> void:
	# Auto-pause and show report popup
	_was_paused_before_report = GameState.paused
	GameState.paused = true

	var result: String = "VICTORY!" if report["attacker_won"] else "DEFEAT!"
	var text: String = "=== COMBAT: %s ===\n\n" % result
	text += "YOUR FORCES:\n"
	text += "  Men: %d  |  Strength: %.0f\n" % [report["atk_men_before"], report["atk_strength"]]
	text += "  Losses: %d  |  Survivors: %d\n\n" % [report["atk_losses"], report["atk_survivors"]]
	text += "ENEMY FORCES:\n"
	text += (
		"  Army: %d  |  Militia: %d  |  Str: %.0f\n"
		% [report["def_men_before"], report["def_militia"], report["def_strength"]]
	)
	text += "  Losses: %d  |  Survivors: %d" % [report["def_losses"], report["def_survivors"]]

	report_label.text = text
	combat_report_popup.visible = true

	# Also update action panel
	action_panel.show_combat_report(report)


func _on_report_dismissed() -> void:
	combat_report_popup.visible = false
	if not _was_paused_before_report:
		GameState.paused = false


func _refresh_all_views() -> void:
	for view_pos: Vector2i in _sector_views.keys():
		_sector_views[view_pos].refresh()
	if _selected_sector in _sector_views:
		allocation_panel.select_sector(_selected_sector)
		action_panel.select_sector(_selected_sector)
