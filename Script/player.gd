extends CharacterBody2D

@export var healthbar: ProgressBar
var max_hp: int = 10000
var hp: int = 10000

@onready var game: Node = $".."
@onready var axis: Node2D = $Axis
var mult: float = 1.0
var flat_dmg: int = 0
var regen_cd: int
var lifesteal: float
var regen: int
var items: Array[ItemResource] = []
func _ready() -> void:
	var item: ItemResource = preload("res://Resource/Items/glascan.tres")
	get_item(item)
	hp = max_hp
	if not healthbar:
		healthbar = get_tree().root.find_child("Healthbar", true, false)

	if healthbar:
		healthbar.init_health(max_hp)
		print("Healthbar initialized")
	else:
		print("Warning: Healthbar not found")
#func load_resource(path: String) -> Array[ItemResource]:
#	var resources: Array[ItemResource]= []
#	var files:= DirAccess.get_files_at(path)
#	for file_name in files:
#		if file_name.ends_with(".tres"):
#			var res= load(file_name)
#			if res:
#				resources.append(res)
#	return resources
func get_item(item: ItemResource)-> void:
	items.append(item)
	mult *= item.mult
	flat_dmg = item.flat_dmg
	lifesteal = item.lifesteal
	regen = item.regen
	regen_cd = item.regen_CD
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

func attack(damage: int) -> void:
	var enemy: Node2D = closest_enemy()
	if enemy:
		axis.look_at(enemy.global_position)
		axis.rotation += PI / 2
		enemy.take_dmg(damage)
	print("shoot")

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
