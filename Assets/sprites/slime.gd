extends Node2D
@onready var player: CharacterBody2D = %Player

@onready var bar: ProgressBar = $ProgressBar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight


var speed:int = 100
var hp: int= 40
var attack: int = 5

func hpprog()-> void:
	bar.max_value=hp
	bar.value = hp

func take_dmg(amount: int) -> void:
	hp-= amount
	bar.value = hp
	if hp <=0:
		queue_free()
		print("someone died")
func _physics_process(delta: float) -> void:
	position +=(player.global_position - global_position).normalized() * speed * delta
	if  position.x > 0:
		animated_sprite_2d.flip_h = true
	elif  position.x < 0:
		animated_sprite_2d.flip_h = false
	if ray_cast_left.is_colliding():
		player.hurt(attack)
		position.x  += 20
		speed -= 10
		print("oof1")
	if ray_cast_right.is_colliding():
		player.hurt(attack)
		position.x -= 20
		speed -= 10
		print("oof2")
func _ready() -> void:
	add_to_group("enemies")
	hpprog()
