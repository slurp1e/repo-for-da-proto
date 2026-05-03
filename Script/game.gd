extends Node2D

@onready var player: CharacterBody2D = %Player
@onready var world: Node2D = $world

var enemy_2D: PackedScene = preload("res://Scenes/slime.tscn")
var Skele_boss: EnemyResource = preload("res://Resource/EnemyResource/Skele_boss.tres")
var slimes: Array[EnemyResource] = [preload("res://Resource/EnemyResource/slime.tres"), preload("res://Resource/EnemyResource/red_slime.tres")]

var rounds: int = 1
var wave: int   = 1
var waving: bool = false

# ─────────────────────────────────────────
#  ITEM POOL — loaded from res://Resource/Items/
# ─────────────────────────────────────────
var item_pool: Array[ItemResource] = []
var _pending_items: Array[ItemResource] = []
var _selected_item: ItemResource = null

# ─────────────────────────────────────────
#  READY
# ─────────────────────────────────────────
func _ready() -> void:
	randomize()
	_load_item_pool()
	spawn_enemies()
	# Connect player signals
	player.level_up.connect(on_player_level_up)
	player.xp_changed.connect(_on_xp_changed)
	# Wire level up menu buttons
	$CanvasLayer/LevelUpMenu/CenterContent/ConfirmBtn.pressed.connect(_on_confirm_btn_pressed)
	$CanvasLayer/LevelUpMenu/CenterContent/RefreshBtn.pressed.connect(_on_refresh_btn_pressed)

# ─────────────────────────────────────────
#  LOAD ITEMS FROM FOLDER
# ─────────────────────────────────────────
func _load_item_pool() -> void:
	var dir := DirAccess.open("res://Resource/Items")
	if dir == null:
		print("Warning: Could not open res://Resource/Items")
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var item: ItemResource = load("res://Resource/Items/" + file_name)
			if item:
				item_pool.append(item)
				print("Item pool loaded: ", item.name)
		file_name = dir.get_next()
	dir.list_dir_end()
	print("Total items in pool: ", item_pool.size())

# ─────────────────────────────────────────
#  PROCESS
# ─────────────────────────────────────────
func _process(_delta: float) -> void:
	wave_up()
	round_up()

# ─────────────────────────────────────────
#  WAVE & ROUND MANAGEMENT
# ─────────────────────────────────────────
func wave_up() -> void:
	if waving:
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		waving = true
		wave += 1
		print("wave:", wave, " - round: ", rounds)
		if wave >= 3:
			spawn_boss()
		else:
			spawn_enemies()
		waving = false

func round_up() -> void:
	if wave >= 3:
		rounds += 1
		wave = 1
		print("wave:", wave, " - round: ", rounds)

func spawn_rate() -> int:
	return roundi(rounds * wave)

func spawn_enemies() -> void:
	var rect: Rect2 = camera_size()
	var margin: int = 100
	for i: int in range(spawn_rate()):
		var e: Node2D = enemy_2D.instantiate()
		e.player = $Player
		e.resource = slimes.pick_random()
		world.add_child(e)
		e.global_position = Vector2(
			randf_range(rect.position.x - margin, rect.end.x + margin),
			randf_range(rect.position.y - margin, rect.end.y + margin)
		)
		await wait(1.0)

func spawn_boss() -> void:
	var rect: Rect2 = camera_size()
	var margin: int = 100
	var boss: Node2D = enemy_2D.instantiate()
	boss.player = player
	boss.resource = Skele_boss
	world.add_child(boss)
	boss.global_position = Vector2(
		randf_range(rect.position.x - margin, rect.end.x + margin),
		randf_range(rect.position.y - margin, rect.end.y + margin)
	)

# ─────────────────────────────────────────
#  XP BAR UI — driven by player signal
# ─────────────────────────────────────────
func _on_xp_changed(current: float, needed: float) -> void:
	var xpbar: ProgressBar = get_node_or_null("CanvasLayer/XPBar")
	var level_label: Label = get_node_or_null("CanvasLayer/LevelLabel")
	if xpbar:
		xpbar.max_value = needed
		xpbar.value = current
	if level_label:
		level_label.text = "LV " + str(player.level)

# ─────────────────────────────────────────
#  LEVEL UP MENU
# ─────────────────────────────────────────
func on_player_level_up(_new_level: int) -> void:
	get_tree().paused = true
	_generate_upgrade_cards()
	$CanvasLayer/LevelUpMenu.visible = true

func _get_cards() -> Array[PanelContainer]:
	var cards: Array[PanelContainer] = [
		$CanvasLayer/LevelUpMenu/CenterContent/CardsContainer/Card1,
		$CanvasLayer/LevelUpMenu/CenterContent/CardsContainer/Card2,
		$CanvasLayer/LevelUpMenu/CenterContent/CardsContainer/Card3,
	]
	return cards

func _generate_upgrade_cards() -> void:
	_selected_item = null
	_pending_items.clear()

	# Pick 3 random items from pool (no duplicates)
	var shuffled: Array[ItemResource] = []
	shuffled.assign(item_pool.duplicate())
	shuffled.shuffle()
	# Slice to max 3, however many are available
	var count: int = mini(3, shuffled.size())
	for i: int in range(count):
		_pending_items.append(shuffled[i])

	var cards: Array[PanelContainer] = _get_cards()
	for i: int in range(cards.size()):
		var card: PanelContainer = cards[i]
		card.modulate = Color.WHITE

		var btn: Button = card.get_node("VBoxContainer/SelectBtn")
		if btn.pressed.is_connected(_on_card_selected.bind(i)):
			btn.pressed.disconnect(_on_card_selected.bind(i))

		if i < _pending_items.size():
			var item: ItemResource = _pending_items[i]
			card.get_node("VBoxContainer/UpgradeName").text = item.name
			card.get_node("VBoxContainer/Description").text = _build_item_desc(item)+ "\n" + item.desc
			var icon: TextureRect = card.get_node("VBoxContainer/IconFrame/IconFrame/")
			icon.texture = item.texture
			card.visible = true
			btn.pressed.connect(_on_card_selected.bind(i))
		else:
			# Hide card if not enough items
			card.visible = false

func _build_item_desc(item: ItemResource) -> String:
	var parts: Array[String] = []
	if item.mult != 1.0:
		parts.append("Mult x" + str(snappedf(item.mult, 0.01)))
	if item.flatDmg != 0:
		parts.append("+" + str(item.flatDmg) + " flat DMG")
	if item.lifesteal != 0.0:
		parts.append(str(int(item.lifesteal * 100)) + "% lifesteal")
	if item.regen > 0:
		parts.append("+" + str(item.regen) + " HP regen")
	if parts.is_empty():
		return "A mysterious item."
	return "\n".join(parts)

func _on_card_selected(index: int) -> void:
	if index >= _pending_items.size():
		return
	_selected_item = _pending_items[index]
	var cards: Array[PanelContainer] = _get_cards()
	for i: int in range(cards.size()):
		var card: PanelContainer = cards[i]
		card.modulate = Color.WHITE if i == index else Color(0.5, 0.5, 0.5, 1.0)

func _on_confirm_btn_pressed() -> void:
	if _selected_item == null:
		return
	player.get_item(_selected_item)
	$CanvasLayer/LevelUpMenu.visible = false
	var cards: Array[PanelContainer] = _get_cards()
	for card: PanelContainer in cards:
		card.modulate = Color.WHITE
		card.visible = true
	get_tree().paused = false
	$CanvasLayer/Line_Edit.grab_focus()

func _on_refresh_btn_pressed() -> void:
	_generate_upgrade_cards()

# ─────────────────────────────────────────
#  UTILITIES
# ─────────────────────────────────────────
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func camera_size() -> Rect2:
	var cam: Camera2D = get_viewport().get_camera_2d()
	var camsize: Vector2 = get_viewport_rect().size * cam.zoom / 11
	var top_left: Vector2 = cam.global_position - camsize / 2
	return Rect2(top_left, camsize)

func quit() -> void:
	get_tree().quit()
