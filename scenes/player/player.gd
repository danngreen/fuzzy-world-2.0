extends CharacterBody2D

# Movement
const SPEED = 300.0
const ACCELERATION : float = 1800.0
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

# Lives
const MAX_LIVES = 3

# Size changing
const BASE_COLLISION_SIZE := Vector2(28, 48)
const MIN_SIZE_SCALE := 0.5
const MAX_SIZE_SCALE := 2.0
const SIZE_STEP := 0.5

# Per-size tweaks: size_scale -> [mass_ratio_from_1, accel_multiplier]
# mass_ratio is relative to size 1.0; accel_multiplier scales ACCELERATION
const SIZE_PARAMS := {
	0.5: { "mass": 0.80, "accel": 2.0, "speed": 1.5 },
	1.0: { "mass": 0.90, "accel": 0.85, "speed": 1.0 },
	1.5: { "mass": 1.5, "accel": 0.45, "speed": 0.85 },
	2.0: { "mass": 2.3, "accel": 0.25, "speed": 0.7 },
}

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false

var health: float = MAX_HEALTH
var invincible: bool = false
var invincibility_timer: float = 0.0
var flash_timer: float = 0.0
var spawn_position: Vector2

var lives: int = MAX_LIVES
var respawning := false

var hat_y: float
var size_scale := 1.0
var size_tween: Tween


func _ready() -> void:
	add_to_group("player")
	spawn_position = global_position
	$CollisionShape2D.shape = $CollisionShape2D.shape.duplicate()


func _physics_process(delta: float) -> void:
	if respawning:
		return

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

	# Size changing
	if Input.is_action_just_pressed("size_up"):
		_change_size(size_scale + SIZE_STEP)
	if Input.is_action_just_pressed("size_down"):
		_change_size(size_scale - SIZE_STEP)

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

	# Jump — scales slightly with size
	if jump_buffer_timer > 0 and coyote_timer > 0:
		velocity.y = JUMP_VELOCITY
		coyote_timer = 0.0
		jump_buffer_timer = 0.0
		_play_sound_jump()

	# Variable jump height - release early to jump shorter
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= JUMP_CUT_MULTIPLIER

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		var accel : float = ACCELERATION * SIZE_PARAMS[size_scale]["accel"]
		var max_speed : float = SPEED * SIZE_PARAMS[size_scale]["speed"]
		velocity.x = move_toward(velocity.x, direction * max_speed, accel * delta)
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
			var away_dir = sign(global_position.x - collider.global_position.x)
			if away_dir == 0:
				away_dir = 1.0
			# XL player stomps drones from above — crash drone, no damage
			if size_scale == 2.0 and collision.get_normal().y < -0.5 and collider.is_in_group("drone_guards"):
				collider.crash()
			elif collider.is_in_group("drone_guards"):
				# Drone guards knock the drone back, not the player
				collider.velocity = Vector2(-away_dir * 300.0, -200.0)
				take_damage()
			elif collision.get_normal().y > 0.5:
				# Enemy on head — hat shield, bounce enemy off
				collider.velocity.y = -300.0
			else:
				# Normal enemies knock the player back
				velocity.x = away_dir * 300.0 / SIZE_PARAMS[size_scale]["mass"]
				velocity.y = -200.0
				take_damage()
			break


func _change_size(new_scale: float) -> void:
	new_scale = clampf(new_scale, MIN_SIZE_SCALE, MAX_SIZE_SCALE)
	if is_equal_approx(new_scale, size_scale):
		return

	var old_scale := size_scale
	size_scale = new_scale

	# Momentum conservation: v_new = v_old * (old_mass / new_mass)
	var old_mass: float = SIZE_PARAMS[old_scale]["mass"]
	var new_mass: float = SIZE_PARAMS[size_scale]["mass"]
	velocity *= old_mass / new_mass

	# Keep feet grounded: adjust position so collision bottom stays at same Y
	position.y -= (size_scale - old_scale) * BASE_COLLISION_SIZE.y / 2.0

	# Update collision shape immediately (physics needs it)
	$CollisionShape2D.shape.size = BASE_COLLISION_SIZE * size_scale

	# Animate sprite scale from current visual size to target
	if size_tween and size_tween.is_valid():
		size_tween.kill()
	var visual_start := absf($Sprite.scale.y)
	size_tween = create_tween()
	size_tween.tween_method(func(t: float):
		var f := signf($Sprite.scale.x) if $Sprite.scale.x != 0.0 else 1.0
		$Sprite.scale = Vector2(f * t, t)
	, visual_start, size_scale, 0.15)


func _reset_size() -> void:
	size_scale = 1.0
	$CollisionShape2D.shape.size = BASE_COLLISION_SIZE
	var facing := signf($Sprite.scale.x) if $Sprite.scale.x != 0.0 else 1.0
	$Sprite.scale = Vector2(facing, 1.0)


func take_damage() -> void:
	if invincible:
		return
	var damage := 2.5 - size_scale
	health -= damage
	_update_hud()
	if health <= 0.0:
		die()
		return
	invincible = true
	invincibility_timer = INVINCIBILITY_DURATION
	flash_timer = 0.0


func die() -> void:
	lives -= 1
	_update_hud()

	if lives <= 0:
		_game_over()
		return

	# Respawn with hat animation
	health = MAX_HEALTH
	_update_hud()
	_reset_size()
	velocity = Vector2.ZERO
	_start_respawn()


func _start_respawn() -> void:
	respawning = true
	$CollisionShape2D.disabled = true
	$Sprite.visible = true
	$Sprite/ColorRect.visible = false
	global_position = Vector2(spawn_position.x, spawn_position.y - 250)

	# Pivot at bottom of hat brim (Sprite rect coords) so body grows downward from hat
	$Sprite.pivot_offset = Vector2(14, -9)
	$Sprite.scale = Vector2(1, 0.01)

	# Standalone hat at the Sprite hat's full-scale position
	var hat = Node2D.new()
	hat.name = "RespawnHat"
	var top = ColorRect.new()
	top.offset_left = -9; top.offset_top = -40
	top.offset_right = 7; top.offset_bottom = -35
	hat.add_child(top)
	var brim = ColorRect.new()
	brim.offset_left = -9; brim.offset_top = -35
	brim.offset_right = 9; brim.offset_bottom = -33
	hat.add_child(brim)
	add_child(hat)

	var tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_property($Sprite, "scale:y", 1.0, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func():
		hat.queue_free()
		$Sprite/ColorRect.visible = true
		_finish_respawn()
	)


func _finish_respawn() -> void:
	$Sprite.pivot_offset = Vector2(14, 24)
	$CollisionShape2D.disabled = false
	respawning = false
	invincible = true
	invincibility_timer = INVINCIBILITY_DURATION
	flash_timer = 0.0


func _game_over() -> void:
	lives = MAX_LIVES
	health = MAX_HEALTH
	_reset_size()
	velocity = Vector2.ZERO
	var manager = get_tree().get_first_node_in_group("game_manager")
	if manager:
		manager.game_over()


func _update_hud() -> void:
	var hud = get_node_or_null("/root/Main/HUD")
	if hud:
		hud.update_hearts(health)
		hud.update_lives(lives)

func spawn_fire_effect():
	var count = randi_range(6, 8)
	for i in count:
		var p = ColorRect.new()
		p.size = Vector2(3, 3)
		p.color = Color(1, randf_range(0.2, 0.5), 0, 1)
		p.position = Vector2(randf_range(-10, 10), randf_range(-20, 10))
		add_child(p)
		var lifetime = randf_range(0.4, 0.7)
		var dest = p.position + Vector2(randf_range(-20, 20), randf_range(-50, -20))
		var tween = p.create_tween()
		tween.set_parallel(true)
		tween.tween_property(p, "position", dest, lifetime)
		tween.tween_property(p, "modulate:a", 0.0, lifetime)
		tween.set_parallel(false)
		tween.tween_callback(p.queue_free)


func _play_sound_jump() -> void:
	if size_scale == 0.5:
		$SFX/Jump/Small.play()
	elif size_scale == 1:
		$SFX/Jump/Med.play()
	elif size_scale == 1.5:
		$SFX/Jump/Large.play()
	elif size_scale == 2:
		$SFX/Jump/XL.play()
