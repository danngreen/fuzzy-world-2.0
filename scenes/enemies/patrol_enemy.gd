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

	# Check slide collisions
	var reversed := false
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player"):
			if collision.get_normal().y < -0.5:
				# Landed on player's head — hat shield, bounce off
				velocity.y = -300.0
			else:
				var away_dir = sign(collider.global_position.x - global_position.x)
				if away_dir == 0:
					away_dir = 1.0
				collider.velocity.x = away_dir * 300.0 / collider.SIZE_PARAMS[collider.size_scale]["mass"]
				collider.velocity.y = -200.0
				collider.take_damage()
			break
		# Reverse on hitting another enemy or a moving platform from the side
		if absf(collision.get_normal().x) > 0.5:
			if not reversed:
				direction *= -1.0
				reversed = true
				global_position.x += collision.get_normal().x * 2.0
			break

	# Turn around on wall (skip if already reversed from a collision)
	if not reversed and is_on_wall():
		direction *= -1.0

	# Turn around at ledge — check if raycast lost ground
	if is_on_floor():
		if not $EdgeDetector.is_colliding():
			direction *= -1.0

	# Keep raycast pointing in movement direction
	$EdgeDetector.target_position.x = direction * 16.0

	# Flip sprite
	$Sprite.scale.x = sign(direction) * absf($Sprite.scale.x)
