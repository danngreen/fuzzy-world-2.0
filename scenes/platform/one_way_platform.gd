@tool
extends StaticBody2D

@export var platform_width: float = 160.0:
	set(value):
		platform_width = maxf(value, 8.0)
		_update_platform()

@export var platform_color := Color(0.55, 0.85, 0.45, 1):
	set(value):
		platform_color = value
		_update_platform()

const HEIGHT := 20.0


func _ready() -> void:
	_update_platform()


func _update_platform() -> void:
	if not is_node_ready():
		return
	var shape = RectangleShape2D.new()
	shape.size = Vector2(platform_width, HEIGHT)
	$CollisionShape2D.shape = shape
	$CollisionShape2D.one_way_collision = true

	$Visual.size = Vector2(platform_width, HEIGHT)
	$Visual.position = Vector2(-platform_width / 2.0, -HEIGHT / 2.0)
	$Visual.color = platform_color
