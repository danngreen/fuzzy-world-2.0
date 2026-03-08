@tool
extends AnimatableBody2D

enum MoveMode { ALWAYS, PLAYER_ON, PLAYER_OFF }

@export var platform_size := Vector2(160, 20):
	set(value):
		platform_size = value
		_update_platform()

@export var platform_color := Color(0.4, 0.7, 0.3, 1):
	set(value):
		platform_color = value
		_update_platform()

@export var move_offset := Vector2(200, 0)
@export var move_speed := 100.0
@export var move_mode: MoveMode = MoveMode.ALWAYS

var start_position := Vector2.ZERO
var player_on := false
var _moving_forward := true


func _ready() -> void:
	_update_platform()
	if not Engine.is_editor_hint():
		start_position = global_position
		$PlayerDetector.body_entered.connect(_on_body_entered)
		$PlayerDetector.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var should_move := false
	match move_mode:
		MoveMode.ALWAYS:
			should_move = true
		MoveMode.PLAYER_ON:
			should_move = player_on
		MoveMode.PLAYER_OFF:
			should_move = not player_on

	if not should_move:
		return

	var end_position := start_position + move_offset
	var target := end_position if _moving_forward else start_position
	var direction := (target - global_position).normalized()
	var distance_to_target := global_position.distance_to(target)
	var step := move_speed * delta

	if step >= distance_to_target:
		global_position = target
		_moving_forward = not _moving_forward
	else:
		global_position += direction * step


func _update_platform() -> void:
	if not is_node_ready():
		return
	$CollisionShape2D.shape = RectangleShape2D.new()
	$CollisionShape2D.shape.size = platform_size
	$Visual.size = platform_size
	$Visual.position = -platform_size / 2
	$Visual.color = platform_color
	$PlayerDetector/CollisionShape2D.shape = RectangleShape2D.new()
	$PlayerDetector/CollisionShape2D.shape.size = platform_size + Vector2(0, 10)
	$PlayerDetector/CollisionShape2D.position = Vector2(0, -5)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_on = true


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_on = false
