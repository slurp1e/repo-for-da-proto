extends Area2D

@export var speed: float = 400.0

var target_node: Node2D   # tracks the enemy node, not just position
var damage: int = 0
var lifesteal: float = 0.0
var player: Node = null


func setup(enemy: Node2D, dmg: int, ls: float) -> void:
	target_node = enemy
	damage = dmg
	lifesteal = ls
	player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	# If enemy died mid-flight, self-destruct cleanly
	if not is_instance_valid(target_node):
		queue_free()
		return

	var target_pos := target_node.global_position
	var dir := (target_pos - global_position).normalized()

	# Rotate sprite to face direction of travel
	rotation = dir.angle()

	global_position += dir * speed * delta

	if global_position.distance_to(target_pos) < 12.0:
		explode()


func explode() -> void:
	if is_instance_valid(target_node):
		target_node.take_dmg(damage)
		if player and lifesteal > 0 and player.has_method("heal"):
			player.heal(damage * lifesteal)

	# Trigger particles if you have them as a child
	var particles := get_node_or_null("GPUParticles2D")
	if particles:
		particles.emitting = true
		# Detach from scene so explosion plays out after fireball logic ends
		var p = particles.duplicate()
		get_tree().current_scene.add_child(p)
		p.global_position = global_position
		p.emitting = true
		p.one_shot = true
		# Auto-clean after lifetime
		get_tree().create_timer(p.lifetime + 0.1).timeout.connect(p.queue_free)

	queue_free()