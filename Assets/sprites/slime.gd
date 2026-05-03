extends Node2D

var player: CharacterBody2D
@export var resource: EnemyResource
@onready var bar: ProgressBar = $ProgressBar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var AtkArea: Area2D = $AtkArea

var can_attack: bool = true
var speed: int
var hp: int
var attack
var velocity: Vector2 = Vector2.ZERO
var knockback: Vector2 = Vector2.ZERO
var resistance: int

func _ready() -> void:
	AtkArea.body_entered.connect(hitting)
	add_to_group("enemies")
	print("ngerrrrr", resource)
	if resource:
		resistance = resource.resistance
		hp = resource.hp
		speed = resource.speed
		attack = resource.atk
		animated_sprite_2d.sprite_frames = resource.frames
		animated_sprite_2d.play("Idle")
	hpprog()

func hitting(body) -> void:
	if body == player and can_attack:
		can_attack = false
		player.hurt(attack)
		enemy_knockback(player.global_position, resistance)
		can_attack = true

func hpprog() -> void:
	bar.max_value = hp
	bar.value = hp

func take_dmg(amount: int) -> void:
	hp -= amount
	bar.value = hp
	if hp <= 0:
		die()

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

func die() -> void:
	print("someone died")
	if player and player.has_method("gain_xp"):
		var xp: float = float(resource.xp_reward) if resource and "xp_reward" in resource else 20.0
		player.gain_xp(xp)
		print("XP given: ", xp)
	else:
		print("ERROR: gain_xp not found on player — is player.gd updated?")
	remove_from_group("enemies")
	queue_free()
