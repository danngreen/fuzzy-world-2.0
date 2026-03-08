extends CharacterBody2D

@export var speed: float = 100.0

const GRAVITY = 1200.0
const MAX_FALL_SPEED = 900.0

var direction: float = 1.0


func _ready() -> void:
	add_to_group("enemies")


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

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
	$EdgeDetector.target_position.x = direction * 16.0

	# Flip sprite
	$Sprite.scale.x = sign(direction) * absf($Sprite.scale.x)
