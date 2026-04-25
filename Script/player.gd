extends Node2D
@onready var game: Node2D = $".."
@onready var label: Label = $"../GameManager/Label"
var atk: int = 10
var hp: int= 50
func health():
	return hp

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
func attack() -> void: 
	var enemy: Node2D = closest_enemy()
	if enemy:
		enemy.take_dmg(atk)
	print("shoot")


func hurt(amount: int) -> void:
	hp -= amount
	print("you missed lol")
	label.text = str(hp) + "\\50"
	if hp<=0:
		die()

func die() -> void:
	print("you die")
	over()

func over() -> void:
	print("u suck")
	game.quit()
