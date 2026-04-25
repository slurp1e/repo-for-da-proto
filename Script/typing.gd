extends CanvasLayer

var word_list: Array= ["a", "about", "and", "any", "as", "ask", "at", "back", "be", "but", "by", 
"can", "come", "do", "down", "end", "few", "find", "for", "go", 
"group", "have", "he", "help", "home", "house", "how", "I", "if", "in", "into", "it", "large", "last", "late", "lead", "life", "line", "man", "many", "may", "more", "move", "new", "no", "not", "now", "of", "on", "one", "open", "or", "other", "out", "own", "part", "plan", "play", "point", "real", "run", "same", "say", "set", "she", "so", "some", "take", "the", 
"this", "those", "time", "to", "turn", "up", "use", "want", "we", "what", "who", "with", "work", "you"]

var word: Array = []
var current_index: int = 0

# Audio players (will be initialized in _ready if they exist)
var hit_sound: Node  # Can be AudioStreamPlayer or AudioStreamPlayer2D
var miss_sound: Node

# Tracking stats
var perfect_words: int = 0
var total_words: int = 0

# Visual feedback settings
var hit_flash_color: Color = Color.WHITE
var miss_flash_color: Color = Color(0xe03e3e)  # Red color for miss
var flash_duration: float = 0.15
var shake_intensity: float = 0.05
var shake_duration: float = 0.05

func _ready() -> void:
	generate_words()
	render_words()
	$LineEdit.editable = true
	$LineEdit.modulate.a = 0
	$LineEdit.text_changed.connect(highlight)
	$LineEdit.grab_focus()
	$RichTextLabel.bbcode_enabled = true
	
	# Initialize audio players if they exist
	if has_node("HitSound"):
		hit_sound = $HitSound
	if has_node("MissSound"):
		miss_sound = $MissSound
	
	print("✓ Typing system initialized")

#Generate Random Words From List
func generate_words() -> void:
	word.clear()
	for i: int in range(5):
		word.append(word_list.pick_random())
	current_index = 0

#
func render_words() -> void:
	for i: Label in $HBoxContainer.get_children():
		i.free()
	
	for i: int in range(word.size()):
		var label: Label = Label.new()
		label.text = word[i]
		label.add_theme_font_size_override("font_size", 24)
		
		# Color code by difficulty
		var difficulty = get_word_difficulty(word[i])
		if i == current_index:
			match difficulty:
				"easy": label.modulate = Color.YELLOW_GREEN
				"medium": label.modulate = Color.YELLOW
				"hard": label.modulate = Color.RED
		else:
			label.modulate = Color.WHITE
		
		$HBoxContainer.add_child(label)

func get_word_difficulty(w: String) -> String:
	if w.length() <= 3:
		return "easy"
	elif w.length() <= 6:
		return "medium"
	else:
		return "hard"

func calculate_word_damage(w: String) -> int:
	# Damage scales with word length
	return int(ceil(w.length() * 1.5))

func highlight(text: String = " ") -> void:
	var typed: String = $LineEdit.text 
	var target: String = word[current_index]
	var result: String = ""
	 
	for i: int in range(target.length()):
		if i < typed.length():
			if typed[i] == target[i]:
				result += "[color=green]" + word[current_index][i] + "[/color]"
			else:
				result += "[color=red]" + word[current_index][i] + "[/color]"
		else:
			result += target[i]	
			
	$RichTextLabel.text = result
	
	# Update word list highlighting
	for i: int in range($HBoxContainer.get_child_count()):
		var label: Label = $HBoxContainer.get_child(i)
		if i == current_index:
			label.modulate = Color.YELLOW
		else:
			label.modulate = Color.WHITE

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		highlight()
		if event.keycode == KEY_SPACE:
			check_word()
			$LineEdit.text = ""
			$LineEdit.grab_focus()
			get_viewport().set_input_as_handled()
			highlight()

func check_word() -> void:
	var typed: String = $LineEdit.text.strip_edges()
	if current_index >= word.size():
		return
	
	total_words += 1
	
	if typed == word[current_index]:
		perfect_words += 1
		var _damage: int = calculate_word_damage(word[current_index])
		# Player is sibling of UILayer (this node's parent)
		get_parent().get_parent().get_node("Player").attack()
		play_success_feedback()
	else:
		# Player is sibling of UILayer
		get_parent().get_parent().get_node("Player").hurt(5)
		play_miss_feedback()
	
	current_index += 1
	$LineEdit.text = ""
	
	if current_index == word.size():
		current_index = 0 
		generate_words()
		render_words()

func play_success_feedback() -> void:
	# Play success sound
	if hit_sound:
		print("HitSound exists: ", hit_sound)
		print("HitSound stream: ", hit_sound.stream)
		print("HitSound volume: ", hit_sound.volume_db)
		print("HitSound bus: ", hit_sound.bus)
		hit_sound.play()
		print("Playing hit sound...")
	else:
		print("HitSound is null!")
	
	# Screen shake and color flash
	screen_shake()
	color_flash(hit_flash_color)
	
	# Damage number popup
	var damage: int = calculate_word_damage(word[current_index - 1])
	show_damage_popup(damage, hit_flash_color)
	
	print("SUCCESS! Damage dealt")

func play_miss_feedback() -> void:
	# Play miss sound
	if miss_sound:
		miss_sound.play()
	
	# Screen shake and color flash (smaller shake for miss)
	screen_shake(2.0)  # Reduced intensity
	color_flash(miss_flash_color)
	
	# Damage number popup for miss
	show_damage_popup(5, miss_flash_color)
	
	print("MISS! Player hurt")

func get_accuracy() -> float:
	if total_words == 0:
		return 0.0
	return float(perfect_words) / float(total_words) * 100.0

# Screen shake effect
func screen_shake(intensity_multiplier: float = 1.0) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if not camera:
		return
	
	var original_pos: Vector2 = camera.global_position
	var shake_amount: float = shake_intensity * intensity_multiplier
	
	# Shake for the duration
	for i: int in range(int(shake_duration * 60)):  # Assuming 60 FPS
		camera.global_position = original_pos + Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		await get_tree().process_frame
	
	# Reset camera position
	camera.global_position = original_pos

# Color flash effect
func color_flash(color: Color) -> void:
	# Create a ColorRect overlay for the flash effect
	var flash_overlay: ColorRect = ColorRect.new()
	flash_overlay.color = color
	flash_overlay.color.a = 0.3  # Semi-transparent
	flash_overlay.anchors_preset = 15  # Fill screen
	flash_overlay.anchor_right = 1.0
	flash_overlay.anchor_bottom = 1.0
	
	# Add to UILayer (parent of this script)
	get_parent().add_child(flash_overlay)
	
	# Fade out the flash
	var tween: Tween = create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, flash_duration)
	await tween.finished
	
	flash_overlay.queue_free()

# Damage number popup
func show_damage_popup(damage: int, color: Color) -> void:
	var label: Label = Label.new()
	label.text = str(damage)
	label.add_theme_font_size_override("font_size", 32)
	label.modulate = color
	
	# Position at LineEdit location (bottom center area)
	var line_edit_pos: Vector2 = $LineEdit.global_position
	label.global_position = line_edit_pos + Vector2(0, -50)
	
	# Add to UILayer (parent of this script)
	get_parent().add_child(label)
	
	# Animate popup floating upward and fading out
	var tween: Tween = create_tween()
	tween.set_parallel(true)  # Run animations in parallel
	tween.tween_property(label, "global_position:y", label.global_position.y - 50, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	
	await tween.finished
	label.queue_free()
