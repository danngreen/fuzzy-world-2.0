extends Node2D

enum DropMode { ALWAYS, WHEN_BELOW, UNLESS_BELOW }

@export var drop_interval: float = 2.0
@export var drop_mode: DropMode = DropMode.ALWAYS
@export var detection_width: float = 80.0

var timer: float = 0.0
var fireball_scene: PackedScene
var body: ColorRect

const COLOR_DIM    = Color(0.4,  0.1,  0.1,  1)
const COLOR_ACTIVE = Color(0.85, 0.2,  0.05, 1)


func _ready():
	fireball_scene = preload("res://scenes/enemies/fireball.tscn")
	timer = drop_interval
	body = $Body


func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	var active = _is_active(player)
	body.color = COLOR_ACTIVE if active else COLOR_DIM
	timer -= delta
	if timer <= 0:
		timer = drop_interval
		if active:
			_drop_fireball()


func _is_active(player: Node) -> bool:
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
