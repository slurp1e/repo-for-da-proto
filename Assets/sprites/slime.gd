extends Node2D

var player: CharacterBody2D

@export var resource: EnemyResource
@export var healthbar: ProgressBar

@onready var bar: ProgressBar = $ProgressBar
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var AtkArea: Area2D = $AtkArea

var can_attack: bool = true
var is_dying: bool = false
var speed: int
var hp: int
var attack: int
var velocity: Vector2 = Vector2.ZERO
var knockback: Vector2 = Vector2.ZERO
var resistance: int

@export var blink_material: ShaderMaterial
@export var dissolve_material: ShaderMaterial
@export var hit_particle: PackedScene
@export var hit_sfx: AudioStreamPlayer2D
@export var death_sfx: AudioStreamPlayer2D
@export var audio_player: AudioStreamPlayer2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_warning("Enemy: player not found — add_to_group('player') missing in Player.gd")

	AtkArea.body_entered.connect(_on_hit_player)
	add_to_group("enemies")

	if resource:
		resistance = resource.resistance
		hp = resource.hp
		speed = resource.speed
		attack = resource.atk
		animated_sprite_2d.sprite_frames = resource.frames
		animated_sprite_2d.play("Idle")
	
	call_deferred("_init_healthbar")


func _init_healthbar() -> void:
	var max_hp := resource.hp if resource else hp
	if bar:
		bar.max_value = max_hp
		bar.value = hp
	if healthbar:
		healthbar.max_value = max_hp
		healthbar.value = hp


func _on_hit_player(body: Node2D) -> void:
	if not player or body != player or not can_attack or is_dying:
		return
	can_attack = false
	player.hurt(attack)
	enemy_knockback(player.global_position, resistance)
	can_attack = true


func _physics_process(delta: float) -> void:
	if not player or is_dying:
		return

	var direction := (player.global_position - global_position).normalized()
	velocity = direction * speed + knockback
	position += velocity * delta
	knockback = knockback.lerp(Vector2.ZERO, 5 * delta)
	animated_sprite_2d.flip_h = player.global_position.x > global_position.x


func enemy_knockback(from_position: Vector2, force: float) -> void:
	knockback = (global_position - from_position).normalized() * force

func take_dmg(amount: int) -> void:
	if is_dying:
		return
	hp -= amount
	if bar:
		bar.value = hp
	if healthbar:
		healthbar.value = hp

	if hit_sfx:
		_play_node_detached(hit_sfx)

	if blink_material:
		var original := animated_sprite_2d.material
		animated_sprite_2d.material = blink_material
		await get_tree().create_timer(0.06).timeout
		if is_dying:
			return
		animated_sprite_2d.material = original

	if hit_particle:
		var p: Node2D = hit_particle.instantiate()
		get_parent().add_child(p)
		p.global_position = global_position

	if hp <= 0:
		is_dying = true
		die()


func die() -> void:
	remove_from_group("enemies")

	if player and player.has_method("gain_xp"):
		var xp: float = 20.0
		if resource and resource.get("xp_reward") != null:
			xp = float(resource.xp_reward)
		player.gain_xp(xp)

	if death_sfx:
		_play_node_detached(death_sfx)

	if dissolve_material and animated_sprite_2d:
		animated_sprite_2d.material = dissolve_material
		var t := create_tween()
		t.tween_property(animated_sprite_2d.material, "shader_parameter/dissolve", 1.0, 0.5)
		t.tween_callback(queue_free)
	else:
		queue_free()


func _play_node_detached(player_node: AudioStreamPlayer2D) -> void:
	var parent := get_parent()
	remove_child(player_node)        # detach from enemy
	parent.add_child(player_node)    # reparent so it survives queue_free
	player_node.global_position = global_position
	player_node.play()
	player_node.finished.connect(player_node.queue_free)