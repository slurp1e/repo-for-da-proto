extends CharacterBody2D

@export var healthbar: ProgressBar
@onready var axis: Node2D = $Axis
@onready var game: Node = $".."
@onready var regen_timer: Timer =$Timer
var max_hp: int = 100
var hp: int = max_hp
var items: Array[ItemResource] = []
var mult: float = 1.0
var flat_dmg: int = 0
var regen_CD:Dictionary= {}
var lifesteal: float

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
				get_item(item) # uses your existing system
				print("Loaded:", item.name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
func _ready() -> void:
	regen_timer.timeout.connect(_on_regen_timeout)
	load_items("res://Resource/Items")
	
	hp = max_hp
	if not healthbar:
		healthbar = get_tree().root.find_child("Healthbar", true, false)

	if healthbar:
		healthbar.init_health(max_hp)
		print("Healthbar initialized")
	else:
		print("Warning: Healthbar not found")
func get_item(item: ItemResource) -> void:
	items.append(item)
	print("You got: ", item.name)
	mult *= item.mult
	flat_dmg += item.flatDmg
	regen_CD[item] = 0.0
	lifesteal = item.lifesteal

func modify_dmg(base_damage: int ) -> int:
	return int(base_damage * mult) + flat_dmg
	
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
func heal(amount: float) -> void:
	if amount <= 0:
		return
	hp+= int(amount)
	hp =clamp(hp,0,max_hp)
	if healthbar:
		healthbar.health = hp

func _on_regen_timeout()-> void:
	for item in items:
		if item.regen >0:
			regen_CD[item] += 1.0
			if regen_CD[item]>= item.regen_CD:
				heal(item.regen)
				print(hp)
				regen_CD[item] = 0.0

func attack(damage: int) -> int:
	var final_damage = modify_dmg(damage)
	var enemy: Node2D = closest_enemy()
	if enemy:
		axis.look_at(enemy.global_position)
		axis.rotation += PI / 2
		enemy.take_dmg(final_damage)
	print("shoot")
	return final_damage
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
	over()

func over() -> void:
	print("u suck")
	game.quit()
