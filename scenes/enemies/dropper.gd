extends Node2D

enum DropMode { ALWAYS, WHEN_BELOW, UNLESS_BELOW }

@export var drop_interval: float = 2.0
@export var drop_mode: DropMode = DropMode.ALWAYS
@export var detection_width: float = 80.0

var timer: float = 0.0
var fireball_scene: PackedScene


func _ready():
	fireball_scene = preload("res://scenes/enemies/fireball.tscn")
	timer = drop_interval


func _physics_process(delta):
	timer -= delta
	if timer <= 0:
		timer = drop_interval
		if _should_drop():
			_drop_fireball()


func _should_drop() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return drop_mode == DropMode.ALWAYS
	var below = absf(player.global_position.x - global_position.x) <= detection_width
	match drop_mode:
		DropMode.ALWAYS:
			return true
		DropMode.WHEN_BELOW:
			return below
		DropMode.UNLESS_BELOW:
			return not below
	return false


func _drop_fireball():
	var fireball = fireball_scene.instantiate()
	get_parent().add_child(fireball)
	fireball.global_position = global_position + Vector2(0, 10)
