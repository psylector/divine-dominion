## Speed and pause controls in the top-right corner.
extends HBoxContainer

@onready var pause_button: Button = %PauseButton
@onready var speed1_button: Button = %Speed1Button
@onready var speed2_button: Button = %Speed2Button
@onready var speed4_button: Button = %Speed4Button


func _ready() -> void:
	pause_button.pressed.connect(_on_pause)
	speed1_button.pressed.connect(_on_speed.bind(1))
	speed2_button.pressed.connect(_on_speed.bind(2))
	speed4_button.pressed.connect(_on_speed.bind(4))
	_update_buttons()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_on_pause()
		get_viewport().set_input_as_handled()


func _on_pause() -> void:
	GameState.paused = not GameState.paused
	_update_buttons()


func _on_speed(spd: int) -> void:
	GameState.speed = spd
	GameState.paused = false
	_update_buttons()


func _update_buttons() -> void:
	pause_button.text = "▶ Play" if GameState.paused else "⏸ Pause"
	speed1_button.button_pressed = GameState.speed == 1 and not GameState.paused
	speed2_button.button_pressed = GameState.speed == 2 and not GameState.paused
	speed4_button.button_pressed = GameState.speed == 4 and not GameState.paused
