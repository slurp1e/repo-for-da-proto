extends Control

# References to buttons (will be set in editor or auto-found in _ready)
@onready var play_button: Button = $CanvasLayer/CenterContent/PlayButton
@onready var continue_button: Button = $CanvasLayer/CenterContent/ContinueButtonButton
@onready var settings_button: Button = $CanvasLayer/CenterContent/SettingsButton
@onready var exit_button: Button = $CanvasLayer/CenterContent/QuitButton

func _ready() -> void:
	# Connect button signals
	if play_button:
		play_button.pressed.connect(play_game)
	if continue_button:
		continue_button.pressed.connect(continue_game)
	if settings_button:
		settings_button.pressed.connect(open_settings)
	if exit_button:
		exit_button.pressed.connect(exit_game)

func play_game() -> void:
	# Load and play the main game scene
	get_tree().change_scene_to_file("res://Scenes/game.tscn")

func continue_game() -> void:
	# TODO: Implement continue functionality (load save file)
	print("Continue button pressed - TODO: Load save game")

func open_settings() -> void:
	# TODO: Implement settings menu
	print("Settings button pressed - TODO: Open settings menu")

func exit_game() -> void:
	# Exit the game
	get_tree().quit()
