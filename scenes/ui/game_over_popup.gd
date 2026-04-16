## Game over dialog showing victory or defeat.
extends PanelContainer

@onready var result_label: Label = %ResultLabel
@onready var details_label: Label = %DetailsLabel


func _ready() -> void:
	visible = false
	GameState.game_over.connect(_on_game_over)


func _on_game_over(winner_id: int) -> void:
	visible = true
	GameState.paused = true
	if winner_id == 0:
		result_label.text = "VICTORY!"
		result_label.add_theme_color_override("font_color", Color.GOLD)
		details_label.text = "You have conquered all sectors!"
	else:
		result_label.text = "DEFEAT"
		result_label.add_theme_color_override("font_color", Color.CRIMSON)
		details_label.text = "The enemy has overwhelmed you."
