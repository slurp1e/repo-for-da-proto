extends Control

@export var pause_button: Button
@export var pause_panel: Control

func resume():
	get_tree().paused = false

func pause():
	get_tree().paused = true

func testEsc():
	if Input.is_action_just_pressed("Escape (Physical)") and get_tree().paused == false:
		pause()
		if pause_panel:
			pause_panel.visible = true
	elif Input.is_action_just_pressed("Escape (Physical)") and get_tree().paused == true:
		if pause_panel:
			pause_panel.visible = false
		resume()

func _ready() -> void:
	# Connect the pause button if assigned
	if pause_button:
		pause_button.pressed.connect(_on_pause_button_pressed)
	elif has_node("PauseMenuButton"):
		$PauseMenuButton.pressed.connect(_on_pause_button_pressed)
	
	# Connect pause panel buttons if assigned
	if pause_panel:
		var resume_btn = pause_panel.find_child("ResumeButton", true, false)
		var restart_btn = pause_panel.find_child("RestartButton", true, false)
		var options_btn = pause_panel.find_child("OptionsButton", true, false)
		var quit_btn = pause_panel.find_child("QuitButton", true, false)
		
		if resume_btn:
			resume_btn.pressed.connect(_on_resume_pressed)
		if restart_btn:
			restart_btn.pressed.connect(_on_restart_pressed)
		if options_btn:
			options_btn.pressed.connect(_on_options_pressed)
		if quit_btn:
			quit_btn.pressed.connect(_on_quit_pressed)

func _on_pause_button_pressed() -> void:
	pause()
	# Show pause menu panel
	if pause_panel:
		pause_panel.visible = true

func _on_resume_pressed():
	resume()
	# Hide pause menu panel
	if pause_panel:
		pause_panel.visible = false

func _on_restart_pressed():
	resume()
	get_tree().reload_current_scene()
func _on_options_pressed():
	pass

func _on_quit_pressed():
	get_tree().quit()


func _on_exit_game_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_menu_pressed() -> void:
	pass # Replace with function body.



func _process(_delta: float) -> void:
	testEsc()
