extends CharacterBody2D

class_name player
@onready var game: Node = $".."
@export var healthbar: ProgressBar
@onready var axis: Node2D = $Axis
@onready var regen_timer: Timer = $Timer
var items: Array[ItemResource] = []
var max_hp: int = 100
var hp: int = max_hp
var dmg_mult: float = 1.0
var flat_dmg: int = 0
var regen_cooldown:Dictionary= {}
var lifesteal: float
func _ready() -> void:
	regen_timer.timeout.connect(_on_regen_timeout)
	var item: ItemResource = preload("res://Resource/Items/9for3.tres")
	get_item(item)
	hp = max_hp
	if not healthbar:
		healthbar = get_tree().root.find_child("Healthbar", true, false)

	if healthbar:
		healthbar.init_health(max_hp)
		print("Healthbar initialized")
	else:
		print("Warning: Healthbar not found")

#get item function#

func get_item(item: ItemResource) -> void:
	items.append(item)
	print("You got: ", item.name)
	dmg_mult *= item.mult
	flat_dmg += item.FlatDmg
	regen_cooldown[item] = 0.0
	lifesteal = item.lifesteal

#get closest enemy, for attacking, only returns a location

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

# dmg mult for items
func modify_dmg(base_damage: int ) -> int:
	return int(base_damage * dmg_mult) + flat_dmg
	
func attack(damage: int) -> int:
	var final_damage= modify_dmg(damage)
	var enemy: Node2D = closest_enemy()
	print("Base: ", flat_dmg, "mult", dmg_mult, "final: ", final_damage)
	if enemy:
		axis.look_at(enemy.global_position)
		axis.rotation += PI / 2
		enemy.take_dmg(final_damage)
		for item in items:
			if item.lifesteal >0:
				var heal_amount = final_damage * item.lifesteal
				heal(heal_amount)
			
	print("shoot")
	return final_damage

#for healing
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
			regen_cooldown[item] += 1.0
			if regen_cooldown[item]>= item.regen_CD:
				heal(item.regen)
				print(hp)
				regen_cooldown[item] = 0.0

func hurt(amount: int) -> void:
	var modify_damage = int(amount * dmg_mult)
	hp -= modify_damage
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
