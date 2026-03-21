extends Node2D

@export var start_level: PackedScene

var current_level: Node
var level_num := 0


func _ready() -> void:
	add_to_group("game_manager")
	current_level = get_node_or_null("Level")
	if start_level:
		change_level(start_level)
	# Hide player until intro is dismissed
	var player = $Player
	player.respawning = true
	player.get_node("CollisionShape2D").disabled = true
	player.get_node("Sprite").visible = false
	_show_intro_animation()


func _show_intro_animation() -> void:
	get_tree().paused = true
	var anim = preload("res://scenes/ui/intro_animation.tscn").instantiate()
	add_child(anim)


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

	level_num += 1
	_show_level_title()


func _show_level_title() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 15
	add_child(layer)

	var label = Label.new()
	var font = load("res://assets/ShareTechMono-Regular.ttf")
	label.text = "LEVEL " + str(level_num)
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 20)
	label.size = Vector2(1280, 80)
	label.modulate.a = 0.0
	layer.add_child(label)

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(1.5)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(layer.queue_free)


func initial_spawn() -> void:
	var player = $Player
	player.global_position.y = player.spawn_position.y - 25
	player._begin_body_grow()


func start_guide() -> void:
	var guide = preload("res://scenes/ui/guide.tscn").instantiate()
	add_child(guide)


func game_over() -> void:
	get_tree().paused = true
	var screen = preload("res://scenes/ui/game_over_screen.tscn").instantiate()
	add_child(screen)


func _finish_game_over() -> void:
	var player = $Player
	# Restore player visual state after death animation
	player.respawning = false
	player.get_node("CollisionShape2D").disabled = false
	player.get_node("Sprite").visible = true
	player.get_node("Sprite/ColorRect").visible = true
	player.get_node("Sprite").pivot_offset = Vector2(14, 24)
	player._update_hud()
	level_num = 0
	change_level(start_level)
