extends CharacterBody2D

@export var speed: float = 100.0

const GRAVITY = 1200.0
const MAX_FALL_SPEED = 900.0

var direction: float = 1.0


func _ready() -> void:
	add_to_group("enemies")
	add_to_group("patrol")
	# Patrol enemies pass through each other
	for node in get_tree().get_nodes_in_group("patrol"):
		if node != self:
			add_collision_exception_with(node)
			node.add_collision_exception_with(self)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	# Edge detection BEFORE moving — cast straight down from leading edge
	$EdgeDetector.position.x = direction * 10.0
	$EdgeDetector.target_position = Vector2(0, 20)
	$EdgeDetector.force_raycast_update()
	if is_on_floor() and not $EdgeDetector.is_colliding():
		direction *= -1.0

	# Move horizontally
	velocity.x = direction * speed

	move_and_slide()

	# Check slide collisions
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

	# Turn around on wall
	if is_on_wall():
		direction *= -1.0

	# Flip sprite
	$Sprite.scale.x = sign(direction) * absf($Sprite.scale.x)
