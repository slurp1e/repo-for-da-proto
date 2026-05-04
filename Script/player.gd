extends CharacterBody2D

# ─────────────────────────────────────────
#  SIGNALS — required by game.gd
# ─────────────────────────────────────────
signal level_up(new_level: int)
signal xp_changed(current: float, needed: float)
signal died()

# ─────────────────────────────────────────
#  ATTACK / HURT EFFECTS
# ─────────────────────────────────────────
@export var attack_sfx: AudioStream
@export var hurt_sfx: AudioStream
@export var audio_player: AudioStreamPlayer2D
@export var fireball_scene: PackedScene



signal on_hit_enemy(enemy:Node2D)

# ─────────────────────────────────────────
#  SCENE REFS
# ─────────────────────────────────────────
@export var healthbar: ProgressBar
@onready var axis: Node2D = $Axis
@onready var game: Node = $".."
@onready var regen_timer: Timer = $Timer
var last_attack_damage: int = 0
var last_attack_enemy: Node2D = null
# ─────────────────────────────────────────
#  HP
# ─────────────────────────────────────────
var max_hp: int = 200
var hp: int = 200

# ─────────────────────────────────────────
#  ITEM SYSTEM
# ─────────────────────────────────────────
var items: Array[ItemResource] = []
var mult: float = 1.0
var flat_dmg: int = 0
var regen_CD: Dictionary = {}
var lifesteal: float = 0.0
var retaliation: int
var item_stacks: Dictionary = {}
# ─────────────────────────────────────────
#  XP / LEVEL
# ─────────────────────────────────────────
var level: int = 1
var current_xp: float = 0.0
var xp_to_next: float = 100.0

# ─────────────────────────────────────────
#  UPGRADE STATS
# ─────────────────────────────────────────
var xp_bonus: float = 0.0
var bonus_attack_flat: int = 0
var bonus_attack_pct: float = 0.0
var life_steal: float = 0.0
var life_regen: float = 0.0

# ─────────────────────────────────────────
#  READY
# ─────────────────────────────────────────
func _ready() -> void:
	add_to_group("player")
	on_hit_enemy.connect(_on_hit_enemy)
	regen_timer.timeout.connect(_on_regen_timeout)
	hp = max_hp

	if not healthbar:
		healthbar = get_tree().root.find_child("Healthbar", true, false)

	if healthbar:
		healthbar.init_health(max_hp)

	xp_changed.emit(current_xp, xp_to_next)

# ─────────────────────────────────────────
#  PROCESS
# ─────────────────────────────────────────
func _process(delta: float) -> void:
	if life_regen > 0:
		heal(life_regen * delta)

# ─────────────────────────────────────────
#  ITEM SYSTEM
# ─────────────────────────────────────────
func load_items(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var item: ItemResource = load(path + "/" + file_name)
			if item:
				get_item(item)
		file_name = dir.get_next()

	dir.list_dir_end()

func get_item(item: ItemResource) -> void:
	if not item_stacks.has(item.name):
		item_stacks[item.name] = 0
	if item_stacks[item.name] >= item.max_stack:
		print("maxxed out bro", item.name)
		return
	item_stacks[item.name] += 1
	items.append(item)
	mult *= item.mult
	print("You got: ", item.name)
	flat_dmg += item.flatDmg
	regen_CD[item] = 0.0
	lifesteal += item.lifesteal
	retaliation += item.retaliation
	if item.name == "Echo":
		start_echo(item)
func _on_regen_timeout() -> void:
	for item in items:
		if item.regen > 0:
			regen_CD[item] += 1.0
			if regen_CD[item] >= item.regen_CD:
				heal(item.regen)
				regen_CD[item] = 0.0

# ─────────────────────────────────────────
#  COMBAT
# ─────────────────────────────────────────
func modify_dmg(base_damage: int) -> int:
	var base := int(base_damage * mult) + flat_dmg
	var with_flat := base + bonus_attack_flat
	return int(with_flat * (1.0 + bonus_attack_pct))

func closest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var dist := INF

	for e in enemies:
		var d := global_position.distance_to(e.global_position)
		if d < dist:
			dist = d
			closest = e

	return closest
func trigger_echo(multiplier: float = 0.5) -> void:
	if not last_attack_enemy:
		return

	var echo_damage: int = int(last_attack_damage * multiplier)

	if fireball_scene:
		var fireball:  = fireball_scene.instantiate()
		get_tree().current_scene.add_child(fireball)
		fireball.global_position = global_position
		fireball.setup(last_attack_enemy, echo_damage, lifesteal)
func start_echo(item: ItemResource) -> void:
	var t := Timer.new()
	t.wait_time = 1.0
	t.autostart = true
	t.one_shot = false
	add_child(t)

	t.timeout.connect(func():
		trigger_echo(item.value)
	)
	
func attack(damage: int) -> int:
	var final_damage := modify_dmg(damage)
	var enemy := closest_enemy()
	last_attack_damage = final_damage
	last_attack_enemy = enemy

	# SOUND
	if audio_player and attack_sfx:
		audio_player.stream = attack_sfx
		audio_player.pitch_scale = randf_range(0.98, 1.05)
		audio_player.play()

	# FIREBALL
	if fireball_scene and enemy:
		var fireball = fireball_scene.instantiate()
		get_tree().current_scene.add_child(fireball)
		fireball.global_position = global_position
		fireball.setup(enemy, final_damage, lifesteal)

		axis.look_at(enemy.global_position)
		axis.rotation += PI / 2

	elif enemy:
		axis.look_at(enemy.global_position)
		axis.rotation += PI / 2
		enemy.take_dmg(final_damage)

		if life_steal > 0:
			heal(final_damage * life_steal)

	return final_damage

# ─────────────────────────────────────────
#  HEAL / HURT
# ─────────────────────────────────────────
func heal(amount: float) -> void:
	if amount <= 0:
		return

	hp = clamp(hp + int(amount), 0, max_hp)

	if healthbar:
		healthbar.health = hp

func _on_hit_enemy(enemy: Node2D) -> void:
	if retaliation > 0:
		enemy.take_dmg(retaliation)

func hurt(amount: int) -> void:
	hp -= amount
	hp = clamp(hp, 0, max_hp)

	# ── HURT SOUND ──
	if audio_player and hurt_sfx:
		audio_player.stream = hurt_sfx
		audio_player.pitch_scale = randf_range(0.95, 1.05)
		audio_player.play()

	if healthbar:
		healthbar.health = hp

	if hp <= 0:
		die()

# ─────────────────────────────────────────
#  DEATH
# ─────────────────────────────────────────
func die() -> void:
	died.emit()

# ─────────────────────────────────────────
#  XP SYSTEM
# ─────────────────────────────────────────
func gain_xp(amount: float) -> void:
	var actual := amount * (1.0 + xp_bonus)
	current_xp += actual
	xp_changed.emit(current_xp, xp_to_next)

	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1
		xp_to_next = _calc_next_threshold()
		level_up.emit(level)
		xp_changed.emit(current_xp, xp_to_next)

func _calc_next_threshold() -> float:
	return xp_to_next * 1.4

# ─────────────────────────────────────────
#  UPGRADE SYSTEM
# ─────────────────────────────────────────
func apply_upgrade(upg: Dictionary) -> void:
	if upg.has("flat"):
		for stat in upg["flat"]:
			var value = upg["flat"][stat]
			match stat:
				"max_hp":
					max_hp += int(value)
					hp = clamp(hp + int(value), 0, max_hp)
				"attack":
					bonus_attack_flat += int(value)
				"xp_bonus":
					xp_bonus += value
				"life_steal":
					life_steal += value
				"life_regen":
					life_regen += value

	if upg.has("pct"):
		for stat in upg["pct"]:
			var value = upg["pct"][stat]
			match stat:
				"attack":
					bonus_attack_pct += value
				"xp_bonus":
					xp_bonus += value
				"life_steal":
					life_steal += value
				"life_regen":
					life_regen += value

# ─────────────────────────────────────────
#  LEGACY
# ─────────────────────────────────────────
func over() -> void:
	game.quit()
