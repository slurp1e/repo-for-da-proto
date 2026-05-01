extends CharacterBody2D

@export var healthbar: ProgressBar
var max_hp: int = 10000
var hp: int = 10000

@onready var game: Node = $".."
@onready var axis: Node2D = $Axis

func _ready() -> void:
	hp = max_hp
	if not healthbar:
		healthbar = get_tree().root.find_child("Healthbar", true, false)

	if healthbar:
		healthbar.init_health(max_hp)
		print("Healthbar initialized")
	else:
		print("Warning: Healthbar not found")

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
