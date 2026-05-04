extends CharacterBody2D

# ─────────────────────────────────────────
#  SIGNALS — required by game.gd
# ─────────────────────────────────────────
signal level_up(new_level: int)
signal xp_changed(current: float, needed: float)
signal died ()

# ─────────────────────────────────────────
#  SCENE REFS
# ─────────────────────────────────────────
@export var healthbar: ProgressBar
@onready var axis: Node2D       = $Axis
@onready var game: Node         = $".."
@onready var regen_timer: Timer = $Timer

# ─────────────────────────────────────────
#  HP
# ─────────────────────────────────────────
var max_hp: int = 200
var hp: int     = 200

# ─────────────────────────────────────────
#  ITEM SYSTEM (your friend's code, untouched)
# ─────────────────────────────────────────
var items: Array[ItemResource] = []
var mult: float      = 1.0
var flat_dmg: int    = 0
var regen_CD: Dictionary = {}
var lifesteal: float = 0.0

# ─────────────────────────────────────────
#  XP / LEVEL
# ─────────────────────────────────────────
var level: int        = 1
var current_xp: float = 0.0
var xp_to_next: float = 100.0

# ─────────────────────────────────────────
#  UPGRADE STATS — set by apply_upgrade()
# ─────────────────────────────────────────
var xp_bonus: float         = 0.0
var bonus_attack_flat: int  = 0
var bonus_attack_pct: float = 0.0
var life_steal: float       = 0.0
var life_regen: float       = 0.0

# ─────────────────────────────────────────
#  READY
# ─────────────────────────────────────────
func _ready() -> void:
	regen_timer.timeout.connect(_on_regen_timeout)

	hp = max_hp
	if not healthbar:
		healthbar = get_tree().root.find_child("Healthbar", true, false)
	if healthbar:
		healthbar.init_health(max_hp)
		print("Healthbar initialized")
	else:
		print("Warning: Healthbar not found")

	# Emit initial XP state so XPBar starts at 0
	xp_changed.emit(current_xp, xp_to_next)

# ─────────────────────────────────────────
#  PROCESS — upgrade life regen per frame
# ─────────────────────────────────────────
func _process(delta: float) -> void:
	if life_regen > 0:
		heal(life_regen * delta)

# ─────────────────────────────────────────
#  ITEM SYSTEM (untouched)
# ─────────────────────────────────────────
func load_items(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		print("Failed to open:", path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := path + "/" + file_name
			var item: ItemResource = load(full_path)
			if item:
				get_item(item)
				print("Loaded:", item.name)
		file_name = dir.get_next()
	dir.list_dir_end()

func get_item(item: ItemResource) -> void:
	items.append(item)
	print("You got: ", item.name)
	mult     *= item.mult
	flat_dmg += item.flatDmg
	regen_CD[item] = 0.0
	lifesteal += item.lifesteal

func _on_regen_timeout() -> void:
	for item in items:
		if item.regen > 0:
			regen_CD[item] += 1.0
			if regen_CD[item] >= item.regen_CD:
				heal(item.regen)
				print(hp)
				regen_CD[item] = 0.0

# ─────────────────────────────────────────
#  COMBAT
# ─────────────────────────────────────────
func modify_dmg(base_damage: int) -> int:
	# Item multipliers first
	var base := int(base_damage * mult) + flat_dmg
	# Then upgrade bonuses on top
	var with_flat := base + bonus_attack_flat
	return int(with_flat * (1.0 + bonus_attack_pct))

func closest_enemy() -> Node2D:
	var enemies: Array = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var radius: float = INF
	for i: Node2D in enemies:
		var d: float = global_position.distance_to(i.global_position)
		if d < radius:
			radius = d
			closest = i
	return closest

func attack(damage: int) -> int:
	var final_damage := modify_dmg(damage)
	var enemy: Node2D = closest_enemy()
	if enemy:
		axis.look_at(enemy.global_position)
		axis.rotation += PI / 2
		enemy.take_dmg(final_damage)
		# Life steal from upgrade
		if life_steal > 0:
			heal(final_damage * lifesteal)
	print("shoot")
	return final_damage

func heal(amount: float) -> void:
	if amount <= 0:
		return
	hp = clamp(hp + int(amount), 0, max_hp)
	if healthbar:
		healthbar.health = hp

func hurt(amount: int) -> void:
	hp -= amount
	hp = clamp(hp, 0, max_hp)
	print("you missed lol")
	if healthbar:
		healthbar.health = hp
	if hp <= 0:
		die()

func die() -> void:
	print("you die")
	died.emit()

# ─────────────────────────────────────────
#  XP SYSTEM
# ─────────────────────────────────────────
func gain_xp(amount: float) -> void:
	# Apply xp_bonus multiplier from upgrades e.g. 0.25 = +25%
	var actual := amount * (1.0 + xp_bonus)
	current_xp += actual
	xp_changed.emit(current_xp, xp_to_next)

	# Handle multi-level up in one kill (unlikely but safe)
	while current_xp >= xp_to_next:
		current_xp -= xp_to_next
		level += 1
		xp_to_next = _calc_next_threshold()
		print("LEVEL UP! Now level: ", level)
		level_up.emit(level)
		xp_changed.emit(current_xp, xp_to_next)

func _calc_next_threshold() -> float:
	# Each level needs 90% more XP than the last
	return xp_to_next * 1.9

# ─────────────────────────────────────────
#  APPLY UPGRADE — called by game.gd
#
#  To add a new stat:
#  1. Add a var above e.g. var my_stat: float = 0.0
#  2. Add a match case in both flat and pct blocks below
# ─────────────────────────────────────────
func apply_upgrade(upg: Dictionary) -> void:
	if upg.has("flat"):
		for stat: String in upg["flat"]:
			var value: float = upg["flat"][stat]
			match stat:
				"max_hp":
					max_hp += int(value)
					hp = clamp(hp + int(value), 0, max_hp)
					if healthbar:
						healthbar.init_health(max_hp)
						healthbar.health = hp
				"attack":
					bonus_attack_flat += int(value)
				"xp_bonus":
					xp_bonus += value
				"life_steal":
					life_steal += value
				"life_regen":
					life_regen += value

	if upg.has("pct"):
		for stat: String in upg["pct"]:
			var value: float = upg["pct"][stat]
			match stat:
				"max_hp":
					var bonus := int(max_hp * value)
					max_hp += bonus
					hp = clamp(hp + bonus, 0, max_hp)
					if healthbar:
						healthbar.init_health(max_hp)
						healthbar.health = hp
				"attack":
					bonus_attack_pct += value
				"xp_bonus":
					xp_bonus += value
				"life_steal":
					life_steal += value
				"life_regen":
					life_regen += value

	print("Applied upgrade: ", upg.get("name", "unknown"))

# ─────────────────────────────────────────
#  LEGACY (kept for game.gd quit call)
# ─────────────────────────────────────────
func over() -> void:
	print("u suck")
	game.quit()
