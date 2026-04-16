## Bottom panel with sliders and +/- buttons for allocating men to tasks.
## Moving a non-idle task up takes from Idle; moving it down returns to Idle.
extends PanelContainer

var _selected_sector: Vector2i = Vector2i(-1, -1)
var _updating: bool = false

@onready var idle_slider: HSlider = %IdleSlider
@onready var mining_slider: HSlider = %MiningSlider
@onready var design_slider: HSlider = %DesignSlider
@onready var manufacture_slider: HSlider = %ManufactureSlider
@onready var army_slider: HSlider = %ArmySlider

@onready var idle_label: Label = %IdleLabel
@onready var mining_label: Label = %MiningLabel
@onready var design_label: Label = %DesignLabel
@onready var manufacture_label: Label = %ManufactureLabel
@onready var army_label: Label = %ArmyLabel

@onready var sector_title: Label = %SectorTitle
@onready var no_selection_label: Label = %NoSelectionLabel
@onready var sliders_container: VBoxContainer = %SlidersContainer

## Maps SectorModel.Task enum -> slider node.
var _task_sliders: Dictionary = {}
## Maps SectorModel.Task enum -> Array of buttons for that task.
var _task_buttons: Dictionary = {}

## Button name prefixes per task, matched to enum values.
const TASK_NAMES: Array[String] = ["Idle", "Mining", "Design", "Manufacture", "Army"]
const TASK_ENUMS: Array[SectorModel.Task] = [
	SectorModel.Task.IDLE,
	SectorModel.Task.MINING,
	SectorModel.Task.DESIGN,
	SectorModel.Task.MANUFACTURE,
	SectorModel.Task.ARMY,
]


func _ready() -> void:
	_task_sliders = {
		SectorModel.Task.IDLE: idle_slider,
		SectorModel.Task.MINING: mining_slider,
		SectorModel.Task.DESIGN: design_slider,
		SectorModel.Task.MANUFACTURE: manufacture_slider,
		SectorModel.Task.ARMY: army_slider,
	}

	# Connect sliders (drag_ended only)
	for task: SectorModel.Task in _task_sliders.keys():
		var slider: HSlider = _task_sliders[task]
		slider.step = 1.0
		slider.drag_ended.connect(_on_drag_ended.bind(task))

	# Connect +/- buttons for each task
	for i: int in range(TASK_NAMES.size()):
		var prefix: String = TASK_NAMES[i]
		var task: SectorModel.Task = TASK_ENUMS[i]
		_task_buttons[task] = []
		_connect_button("%" + prefix + "MM", task, -10)
		_connect_button("%" + prefix + "M", task, -1)
		_connect_button("%" + prefix + "P", task, 1)
		_connect_button("%" + prefix + "PP", task, 10)

	GameState.men_count_changed.connect(_on_men_changed)
	GameState.tech_level_advanced.connect(_on_tech_changed)
	_show_no_selection()


func _connect_button(node_path: String, task: SectorModel.Task, delta: int) -> void:
	var btn: Button = get_node(node_path) as Button
	if btn:
		btn.pressed.connect(_on_button_pressed.bind(task, delta))
		_task_buttons[task].append(btn)


func select_sector(pos: Vector2i) -> void:
	var sector: SectorModel = GameState.world.get_sector(pos)
	if sector == null or sector.owner_id != 0:
		_show_no_selection()
		return
	_selected_sector = pos
	sliders_container.visible = true
	no_selection_label.visible = false
	_refresh_from_model()


func deselect() -> void:
	_selected_sector = Vector2i(-1, -1)
	_show_no_selection()


func _show_no_selection() -> void:
	sliders_container.visible = false
	no_selection_label.visible = true


## Applies a delta to a task, taking from or returning to Idle.
func _apply_delta(task: SectorModel.Task, delta: int) -> void:
	var sector: SectorModel = GameState.world.get_sector(_selected_sector)
	if sector == null or sector.owner_id != 0:
		return

	if task == SectorModel.Task.IDLE:
		return

	# Block adding to design if research is maxed
	if task == SectorModel.Task.DESIGN and delta > 0 and _is_research_maxed():
		return

	var current: int = sector.men[task]
	var idle: int = sector.men[SectorModel.Task.IDLE]

	if delta > 0:
		var actual: int = mini(delta, idle)
		if actual <= 0:
			return
		sector.men[SectorModel.Task.IDLE] -= actual
		sector.men[task] += actual
	else:
		var actual: int = mini(-delta, current)
		if actual <= 0:
			return
		sector.men[task] -= actual
		sector.men[SectorModel.Task.IDLE] += actual

	_refresh_from_model()
	GameState.men_allocation_changed.emit(_selected_sector)


func _on_button_pressed(task: SectorModel.Task, delta: int) -> void:
	_apply_delta(task, delta)


func _on_drag_ended(_value_changed: bool, task: SectorModel.Task) -> void:
	if _updating:
		return
	var sector: SectorModel = GameState.world.get_sector(_selected_sector)
	if sector == null or sector.owner_id != 0:
		return

	var slider: HSlider = _task_sliders[task]
	var desired: int = int(slider.value)
	var current: int = sector.men[task]
	var diff: int = desired - current

	if diff == 0:
		return

	_apply_delta(task, diff)


## Reads model and updates all sliders + labels.
func _refresh_from_model() -> void:
	var sector: SectorModel = GameState.world.get_sector(_selected_sector)
	if sector == null:
		return

	_updating = true
	var total: int = sector.get_total_men()
	sector_title.text = "Sector %d,%d — ♂ %d" % [_selected_sector.x, _selected_sector.y, total]

	for task: SectorModel.Task in _task_sliders.keys():
		var slider: HSlider = _task_sliders[task]
		slider.max_value = total
		slider.value = sector.men[task]

	_update_labels()
	_update_design_enabled()
	_updating = false


func _update_labels() -> void:
	idle_label.text = "Idle: %d" % int(idle_slider.value)
	mining_label.text = "Mining: %d" % int(mining_slider.value)
	design_label.text = "Design: %d" % int(design_slider.value)
	manufacture_label.text = "Manufacture: %d" % int(manufacture_slider.value)
	army_label.text = "Army: %d" % int(army_slider.value)


func _is_research_maxed() -> bool:
	var player: PlayerModel = GameState.get_player(0)
	if player == null:
		return false
	return GameState.get_next_epoch(player.id) == null


func _update_design_enabled() -> void:
	var maxed: bool = _is_research_maxed()
	design_slider.editable = not maxed
	for btn: Button in _task_buttons.get(SectorModel.Task.DESIGN, []):
		btn.disabled = maxed
	if maxed:
		design_label.text = "Research: MAX"


func _on_tech_changed(_player_id: int, _new_level: int) -> void:
	_update_design_enabled()
	if _selected_sector != Vector2i(-1, -1):
		_refresh_from_model()


func _on_men_changed(pos: Vector2i) -> void:
	if pos == _selected_sector:
		var sector: SectorModel = GameState.world.get_sector(_selected_sector)
		if sector:
			_updating = true
			var total: int = sector.get_total_men()
			sector_title.text = "Sector %d,%d — ♂ %d" % [pos.x, pos.y, total]
			for task: SectorModel.Task in _task_sliders.keys():
				var slider: HSlider = _task_sliders[task]
				slider.max_value = total
				slider.value = sector.men[task]
			_update_labels()
			_updating = false
