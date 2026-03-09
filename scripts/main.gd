extends Node2D

@export var start_level: PackedScene

var current_level: Node


func _ready() -> void:
	add_to_group("game_manager")
	current_level = get_node_or_null("Level")
	if start_level:
		change_level(start_level)
	_show_intro()


func _show_intro() -> void:
	get_tree().paused = true
	var intro = preload("res://scenes/ui/intro_screen.tscn").instantiate()
	add_child(intro)


func change_level(level_scene: PackedScene) -> void:
	if current_level:
		remove_child(current_level)
		current_level.queue_free()

	var new_level = level_scene.instantiate()
	new_level.name = "Level"
	add_child(new_level)
	current_level = new_level

	# Move player to spawn point
	var player = $Player
	var spawn = new_level.get_node_or_null("SpawnPoint")
	if spawn:
		player.global_position = spawn.global_position
	else:
		player.global_position = Vector2(300, 670)

	player.set_z_index(RenderingServer.CANVAS_ITEM_Z_MAX)
	player.velocity = Vector2.ZERO
	player.spawn_position = player.global_position


func game_over() -> void:
	var player = $Player
	player._update_hud()
	change_level(start_level)
