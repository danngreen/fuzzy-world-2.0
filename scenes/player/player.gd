extends CharacterBody2D

# Movement
const SPEED = 300.0
const ACCELERATION = 1800.0
const FRICTION = 2400.0

# Jumping
const JUMP_VELOCITY = -500.0
const JUMP_CUT_MULTIPLIER = 0.4
const COYOTE_TIME = 0.1
const JUMP_BUFFER_TIME = 0.1

# Gravity
const GRAVITY = 1200.0
const MAX_FALL_SPEED = 900.0

# Health
const MAX_HEALTH = 5
const INVINCIBILITY_DURATION = 1.0

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false

var health: int = MAX_HEALTH
var invincible: bool = false
var invincibility_timer: float = 0.0
var flash_timer: float = 0.0
var spawn_position: Vector2

var hat_y: float


func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position


func _physics_process(delta: float) -> void:
	# Invincibility frames
	if invincible:
		invincibility_timer -= delta
		flash_timer += delta
		# Flash sprite every 0.1s
		if fmod(flash_timer, 0.1) < 0.05:
			$Sprite.visible = false
		else:
			$Sprite.visible = true
		if invincibility_timer <= 0:
			invincible = false
			$Sprite.visible = true
			flash_timer = 0.0

	# Gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	# Coyote time tracking
	if is_on_floor():
		coyote_timer = COYOTE_TIME
	elif was_on_floor:
		coyote_timer = COYOTE_TIME
	if coyote_timer > 0:
		coyote_timer -= delta
	was_on_floor = is_on_floor()

	# Jump buffer
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	if jump_buffer_timer > 0:
		jump_buffer_timer -= delta

	# Jump
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0

	# Variable jump height - release early to jump shorter
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		# Hat animation:
		hat_y += 0.05
		if hat_y >= 1:
			hat_y = 0
			# Convert 0..0.5 => -15..-10, and 0.5..1 => -10..-15 
		$Sprite/ColorRect.position.y = (10 * hat_y - 15) if (hat_y < 0.5) else (-5*(hat_y-0.5) - 10)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)

	# Flip sprite based on direction
	if direction != 0:
		$Sprite.scale.x = sign(direction) * absf($Sprite.scale.x)

	move_and_slide()

	# Check enemy collisions after move_and_slide
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("enemies"):
			# Normal points away from collider — if it points up, enemy is on top
			if collision.get_normal().y > 0.5 and collider is CharacterBody2D:
				collider.velocity.y = -400.0
			take_damage()
			break


func take_damage() -> void:
	if invincible:
		return
	health -= 1
	_update_hud()
	if health <= 0:
		die()
		return
	invincible = true
	invincibility_timer = INVINCIBILITY_DURATION
	flash_timer = 0.0


func die() -> void:
	health = MAX_HEALTH
	_update_hud()
	global_position = spawn_position
	velocity = Vector2.ZERO
	invincible = true
	invincibility_timer = INVINCIBILITY_DURATION
	flash_timer = 0.0


func _update_hud() -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud:
		hud.update_hearts(health)
