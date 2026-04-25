extends Node2D

@onready var player: CharacterBody2D = %Player

var enemy_2D: PackedScene = preload("res://Scenes/slime.tscn")
var rounds: int = 1
@onready var world: Node2D = $world
var wave: int = 1
var waving: bool = false
func wave_up() -> void:
	if waving:
		return
	if get_tree().get_nodes_in_group("enemies").is_empty():
		waving = true
		wave+= 1
		print("wave:", wave, " - ", "round: ", round)
		spawn_enemies()
		waving = false
func round_up() -> void:
	if wave>=5:
		rounds+=1
		wave = 1 
		print("wave:", wave, " - ", "round: ", round)
var spawn_rate: int = roundi((rounds*wave*1.5))
func _process(_delta: float) -> void:
	wave_up()
	round_up()
	
func _ready()-> void:
	randomize()
	spawn_enemies()
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
	
func camera_size() -> Rect2:
	var cam: Camera2D= get_viewport().get_camera_2d()
	var camsize: Vector2 =  get_viewport_rect().size * cam.zoom
	var top_left: Vector2= cam.global_position - camsize/2
	return Rect2(top_left, camsize)
func spawn_enemies() -> void:
	var rect: Rect2 = camera_size()
	var margin: int = 100
	
	for i: int in range(spawn_rate):
		var e: Node2D = enemy_2D.instantiate()
		
		world.add_child(e)
		e.player = $Player
		e.global_position = Vector2(randf_range(rect.position.x - margin, rect.end.x + margin),
		randf_range(player.position.y - margin, player.position.y + margin))
		await wait(1.0)
		print("Enemies alive: ", get_tree().get_nodes_in_group("enemies").size())
func quit() -> void:
	get_tree().quit()
