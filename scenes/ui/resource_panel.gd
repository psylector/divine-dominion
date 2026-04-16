## Top bar showing player's global resources: tech level, research progress, total men.
extends PanelContainer

@onready var tech_label: Label = %TechLabel
@onready var men_label: Label = %MenLabel
@onready var weapons_label: Label = %WeaponsLabel
@onready var research_label: Label = %ResearchLabel
@onready var research_bar: ProgressBar = %ResearchBar
@onready var research_info: Label = %ResearchInfo


func _ready() -> void:
	GameState.tech_level_advanced.connect(_on_state_changed_generic)
	GameState.men_count_changed.connect(_on_pos_changed)
	GameState.men_allocation_changed.connect(_on_pos_changed)
	GameState.elements_changed.connect(_on_pos_changed)
	GameState.weapon_designed.connect(_on_state_changed_generic)
	refresh()


func refresh() -> void:
	var player: PlayerModel = GameState.get_player(0)
	if player == null:
		return

	var epoch: EpochData = GameState.get_player_epoch(0)
	tech_label.text = "Tech: %s (Lv %d)" % [epoch.name, player.tech_level + 1]

	# Count total men and designers across all owned sectors
	var total_men: int = 0
	var total_designers: int = 0
	for sector: SectorModel in GameState.world.get_player_sectors(0):
		total_men += sector.get_total_men()
		total_designers += sector.men[SectorModel.Task.DESIGN]

	# Count AI population for comparison
	var ai_total: int = 0
	for sector: SectorModel in GameState.world.get_player_sectors(1):
		ai_total += sector.get_total_men()
	men_label.text = "♂ %d (AI: %d)" % [total_men, ai_total]

	# Research progress
	var next_epoch: EpochData = GameState.get_next_epoch(0)
	if next_epoch:
		research_label.text = "Research: %.0f / %d" % [player.design_points, next_epoch.design_points_required]
		research_bar.max_value = next_epoch.design_points_required
		research_bar.value = player.design_points
		research_bar.visible = true
		if total_designers > 0:
			research_info.text = "(%d researchers)" % total_designers
		else:
			research_info.text = "(no researchers!)"
	else:
		research_label.text = "Research: MAX"
		research_bar.visible = false
		research_info.text = ""

	# Show designed weapons with icons
	var weapon_names: PackedStringArray = []
	for path: String in player.designed_weapons:
		var w: WeaponData = load(path) as WeaponData
		if w:
			weapon_names.append("%s %s" % [w.icon, w.name])
	weapons_label.text = "Weapons: %s" % ", ".join(weapon_names) if weapon_names.size() > 0 else "Weapons: none"


func _on_state_changed_generic(_a: Variant = null, _b: Variant = null) -> void:
	refresh()


func _on_pos_changed(_pos: Vector2i) -> void:
	refresh()


func _process(_delta: float) -> void:
	# Smooth update of research progress bar
	var player: PlayerModel = GameState.get_player(0)
	if player == null:
		return
	var next_epoch: EpochData = GameState.get_next_epoch(0)
	if next_epoch:
		research_bar.value = player.design_points
		research_label.text = "Research: %.0f / %d" % [player.design_points, next_epoch.design_points_required]
