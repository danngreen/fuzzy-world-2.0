@tool
extends StaticBody2D

@export var platform_size := Vector2(160, 20):
	set(value):
		platform_size = value
		_update_platform()

@export var platform_color := Color(0.4, 0.7, 0.3, 1):
	set(value):
		platform_color = value
		_update_platform()


func _ready() -> void:
	_update_platform()


func _update_platform() -> void:
	if not is_node_ready():
		return
	$CollisionShape2D.shape = RectangleShape2D.new()
	$CollisionShape2D.shape.size = platform_size
	$Visual.size = platform_size
	$Visual.position = -platform_size / 2
	$Visual.color = platform_color
