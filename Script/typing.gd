extends CanvasLayer

@export var typed_label: Label
@export var remaining_label: Label
@export var line_edit: LineEdit
@export var hit_sound: AudioStreamPlayer2D
@export var miss_sound: AudioStreamPlayer2D
@export var accuracy_label: Label
@export var wpm_label: Label
@export var score_label: Label

var word_list: Array = []
var word: Array = []
var current_index: int = 0
var debuff: bool = false

# Tracking stats
var perfect_words: int = 0
var total_words: int   = 0
var score: int         = 0
var _start_time: float = 0.0   # set on first word typed, used for WPM

# Colors
const CORRECT  := Color(0x8A5CFFff)
const WRONG    := Color(0x938f99ff)
const UNTYPED  := Color(0xE8E0FFff)
const UPCOMING := Color(0x7A6FA8ff)

# Visual feedback settings
var hit_flash_color  := Color.WHITE
var miss_flash_color := Color(0xe03e3eff)
var flash_duration   := 0.05
var shake_intensity  := 1.0

# ─────────────────────────────────────────
#  INIT
# ─────────────────────────────────────────
func _ready() -> void:
	load_words()
	generate_words()

	if line_edit:
		line_edit.editable = true
		line_edit.modulate.a = 0
		line_edit.text_changed.connect(highlight)
		line_edit.grab_focus()

	if typed_label:
		typed_label.visible = true
		typed_label.modulate = Color.WHITE
	if remaining_label:
		remaining_label.visible = true
		remaining_label.modulate = Color.WHITE

	call_deferred("render_words")
	print("✓ Typing system initialized")

func _process(_delta: float) -> void:
	if wpm_label:
		wpm_label.text = "WPM: " + str(int(get_wpm()))

	if score_label:
		score_label.text = "Score: " + String.num_int64(score)

# ─────────────────────────────────────────
#  WORD LOADING
# ─────────────────────────────────────────
func load_words() -> void:
	var file = FileAccess.open("res://Assets/COMMON WORDS LIB/WORD_LIB.txt", FileAccess.READ)
	if not file:
		print("ERROR: Could not open word library file")
		return
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line != "":
			word_list.append(line)
	file.close()
	print("file size: ", word_list.size())

# ─────────────────────────────────────────
#  WORD GENERATION
# ─────────────────────────────────────────
func generate_words() -> void:
	word.clear()
	for i in range(3):
		word.append(_pick_word())
	current_index = 0

func _pick_word() -> String:
	if word_list.is_empty():
		return "error"
	for i in range(50):
		var w: String = word_list.pick_random()
		if debuff:
			if w.length() >= 5:
				return w
		else:
			if w.length() <= 5:
				return w
	return word_list.pick_random()

func _refill_words() -> void:
	while word.size() - current_index < 4:
		word.append(_pick_word())

# ─────────────────────────────────────────
#  WORD DISPLAY
# ─────────────────────────────────────────
func render_words() -> void:
	if word.is_empty() or current_index >= word.size():
		return
	update_word_display(word[current_index], "")

func update_word_display(target_word: String, typed: String) -> void:
	if not typed_label or not remaining_label:
		print("ERROR: labels still null at display time")
		return

	if typed.length() > 0:
		var expected := target_word.left(typed.length())
		if typed == expected:
			typed_label.add_theme_color_override("font_color", CORRECT)
		else:
			typed_label.add_theme_color_override("font_color", WRONG)
		typed_label.text = typed
	else:
		typed_label.text = ""
		typed_label.add_theme_color_override("font_color", CORRECT)

	var remaining := target_word.right(target_word.length() - min(typed.length(), target_word.length()))
	var display := remaining

	for i in range(1, 3):
		var next_index := current_index + i
		if next_index < word.size():
			display += "  " + word[next_index]

	remaining_label.text = display
	remaining_label.add_theme_color_override("font_color", UNTYPED)

func highlight(_text: String = "") -> void:
	if not line_edit or word.is_empty() or current_index >= word.size():
		return
	update_word_display(word[current_index], line_edit.text)

# ─────────────────────────────────────────
#  INPUT
# ─────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if not line_edit:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			check_word()
			line_edit.text = ""
			line_edit.grab_focus()
			get_viewport().set_input_as_handled()
			render_words()

# ─────────────────────────────────────────
#  WORD CHECK
# ─────────────────────────────────────────
func check_word() -> void:
	if not line_edit or word.is_empty() or current_index >= word.size():
		return

	# Start WPM timer on first word attempt
	if total_words == 0:
		_start_time = Time.get_ticks_msec() / 1000.0

	var typed := line_edit.text.strip_edges()
	total_words += 1

	if typed == word[current_index]:
		perfect_words += 1
		var damage := calculate_word_damage(word[current_index])
		score += damage
		var final_damage = get_parent().get_node("Player").attack(damage)
		play_success_feedback(final_damage)
	else:
		get_parent().get_node("Player").hurt(5)
		play_miss_feedback()

	current_index += 1
	_refill_words()

	if current_index > 10:
		word = word.slice(current_index)
		current_index = 0

	update_accuracy_label()

# ─────────────────────────────────────────
#  STATS
# ─────────────────────────────────────────
func calculate_word_damage(w: String) -> int:
	return int(ceil(w.length() * 3.5))

func get_accuracy() -> float:
	if total_words == 0:
		return 0.0
	return float(perfect_words) / float(total_words) * 100.0

# WPM = words typed / minutes elapsed
func get_wpm() -> float:
	if _start_time == 0.0 or total_words == 0:
		return 0.0
	var elapsed_minutes := (Time.get_ticks_msec() / 1000.0 - _start_time) / 60.0
	if elapsed_minutes <= 0.0:
		return 0.0
	return perfect_words / elapsed_minutes


func update_accuracy_label() -> void:
	if accuracy_label:
		accuracy_label.text = "Accu: " + str(snapped(get_accuracy(), 0.1)) + "%"

# ─────────────────────────────────────────
#  FEEDBACK
# ─────────────────────────────────────────
func play_success_feedback(damage: int) -> void:
	if hit_sound:
		hit_sound.play()
	else:
		print("HitSound is null!")
	screen_shake()
	color_flash(hit_flash_color)
	show_damage_popup(damage, hit_flash_color)
	print("SUCCESS! Damage dealt: ", damage)

func play_miss_feedback() -> void:
	if miss_sound:
		miss_sound.play()
	screen_shake(0.5)
	color_flash(miss_flash_color)
	show_damage_popup(5, miss_flash_color)
	print("MISS! Player hurt")

# ─────────────────────────────────────────
#  SCREEN SHAKE
# ─────────────────────────────────────────
func screen_shake(intensity_multiplier: float = 1.0) -> void:
	var camera := get_viewport().get_camera_2d()
	if not camera:
		return
	var shake_amount := shake_intensity * intensity_multiplier
	var tween := create_tween()
	for i in range(6):
		tween.tween_property(camera, "offset",
			Vector2(randf_range(-shake_amount, shake_amount),
					randf_range(-shake_amount, shake_amount)), 0.02)
	tween.tween_property(camera, "offset", Vector2.ZERO, 0.05)

# ─────────────────────────────────────────
#  COLOR FLASH
# ─────────────────────────────────────────
func color_flash(color: Color) -> void:
	var flash_overlay := ColorRect.new()
	flash_overlay.color = Color(color.r, color.g, color.b, 0.3)
	flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash_overlay)
	var tween := create_tween()
	tween.tween_property(flash_overlay, "color:a", 0.0, flash_duration)
	await tween.finished
	flash_overlay.queue_free()

# ─────────────────────────────────────────
#  DAMAGE POPUP
# ─────────────────────────────────────────
func show_damage_popup(damage: int, color: Color) -> void:
	var label := Label.new()
	label.text = str(damage)
	label.add_theme_font_size_override("font_size", 32)
	label.modulate = color
	label.z_index = 100
	add_child(label)

	if line_edit:
		label.global_position = line_edit.global_position + Vector2(0, -50)
	else:
		var vp := get_viewport().get_visible_rect().size
		label.global_position = Vector2(vp.x / 2.0, vp.y / 2.0)  # fixed typo: global_positison

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", label.global_position.y - 80, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	await tween.finished
	label.queue_free()