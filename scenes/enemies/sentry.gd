extends CharacterBody2D

@export var speed: float = 40.0
@export var detection_radius: float = 250.0
@export var alert_timeout: float = 3.0

const GRAVITY = 1200.0
const MAX_FALL_SPEED = 900.0

var direction: float = 1.0
var alert_active: bool = false
var direction_timer: float = 0.0
var alert_timer: float = 0.0
var alert_timing_out: bool = false


func _ready() -> void:
	add_to_group("enemies")
	# Set detection area radius
	var circle = $DetectionArea/CollisionShape2D.shape as CircleShape2D
	circle.radius = detection_radius
	_pick_random_direction()


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	# Random direction changes
	direction_timer -= delta
	if direction_timer <= 0:
		_pick_random_direction()

	# Move horizontally
	velocity.x = direction * speed

	move_and_slide()

	# Turn around on wall
	if is_on_wall():
		direction *= -1.0

	# Turn around at ledge — check if raycast lost ground
	if is_on_floor():
		if not $EdgeDetector.is_colliding():
			direction *= -1.0

	# Keep raycast pointing in movement direction
	if direction != 0:
		$EdgeDetector.target_position.x = sign(direction) * 16.0

	# Flip sprite
	if direction != 0:
		$Sprite.scale.x = sign(direction) * absf($Sprite.scale.x)

	# Alert timeout countdown
	if alert_timing_out:
		alert_timer -= delta
		if alert_timer <= 0:
			alert_timing_out = false
			_set_alert(false)

	# Blink alert light
	if alert_active:
		$AlertLight.visible = fmod(Engine.get_process_frames(), 20) < 10
	else:
		$AlertLight.visible = false


func _pick_random_direction() -> void:
	direction = [-1.0, 0.0, 1.0].pick_random()
	direction_timer = randf_range(1.0, 3.0)


func _set_alert(active: bool) -> void:
	alert_active = active
	if not active:
		for drone in get_tree().get_nodes_in_group("drone_guards"):
			drone.cancel_alert()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		alert_timing_out = false
		alert_active = true
		for drone in get_tree().get_nodes_in_group("drone_guards"):
			drone.alert(body)


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		alert_timing_out = true
		alert_timer = alert_timeout
