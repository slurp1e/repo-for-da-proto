extends Area2D

@onready var player: CharacterBody2D = %Player
@onready var healthbar = $Healthbar



func _on_body_entered(_body: Node2D) -> void:
	player.hurt(5)
