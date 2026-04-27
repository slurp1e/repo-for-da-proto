extends Node2D
var player: CharacterBody2D

@onready var bar: ProgressBar = $ProgressBar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

@onready var ray_cast_left: RayCast2D = $RayCastLeft
@onready var ray_cast_right: RayCast2D = $RayCastRight


var speed:int = 50
var hp: int= 40
var attack: int = 5
var velocity: Vector2 = Vector2.ZERO
var knockback: Vector2 = Vector2.ZERO
func hpprog()-> void:
	bar.max_value=hp
	bar.value = hp

func take_dmg(amount: int) -> void:
	hp-= amount
	bar.value = hp
	if hp <=0:
		queue_free()
		print("someone died")
func enemy_knockback(from_position: Vector2, force: float) -> void:
	knockback = (global_position - from_position).normalized() * force
func _physics_process(delta: float) -> void:
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * speed
	velocity += knockback
	position += velocity * delta
	knockback = knockback.lerp(Vector2.ZERO, 5 * delta)
	if player.global_position.x > global_position.x:
		animated_sprite_2d.flip_h = true
	else:
		animated_sprite_2d.flip_h = false

	if ray_cast_left.is_colliding():
		player.hurt(attack)
		enemy_knockback(player.global_position, 200.0) #200 placeholder
		speed *= 0.85
		print("oof1")
	if ray_cast_right.is_colliding():
		player.hurt(attack)
		enemy_knockback(player.global_position, 200.0)
		speed *= 0.85
		print("oof2")
func _ready() -> void:
	add_to_group("enemies")
	hpprog()
