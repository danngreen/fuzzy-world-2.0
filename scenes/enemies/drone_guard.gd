extends CharacterBody2D

@export var fly_speed: float = 90.0

const GRAVITY = 1200.0
const MAX_FALL_SPEED = 900.0

enum State { IDLE, ALERTED, CRASHED }

var state: State = State.IDLE
var target: CharacterBody2D = null
var alert_count: int = 0
var knockback_timer: float = 0.0


func _ready() -> void:
	add_to_group("drone_guards")


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO

		State.ALERTED:
			if knockback_timer > 0:
				knockback_timer -= delta
			elif target and is_instance_valid(target):
				var dir = (target.global_position - global_position).normalized()
				velocity = dir * fly_speed
			else:
				velocity = Vector2.ZERO

			move_and_slide()

			# Check slide collisions
			for i in get_slide_collision_count():
				var collider = get_slide_collision(i).get_collider()
				if collider.is_in_group("drone_guards"):
					crash()
					collider.crash()
					return
				if collider.is_in_group("player"):
					# XL player stomps drone from above
					var normal = get_slide_collision(i).get_normal()
					if collider.size_scale == 2.0 and normal.y > 0.5:
						crash()
					else:
						# Knock drone back away from player
						var away_dir = sign(global_position.x - collider.global_position.x)
						if away_dir == 0:
							away_dir = 1.0
						velocity = Vector2(away_dir * 300.0, -200.0)
						knockback_timer = 0.3
						collider.take_damage()
					return

			_update_visuals()
			return

		State.CRASHED:
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
			velocity.x = move_toward(velocity.x, 0, 200.0 * delta)

	move_and_slide()
	_update_visuals()


func alert(player: CharacterBody2D) -> void:
	if state == State.CRASHED:
		return
	alert_count += 1
	target = player
	state = State.ALERTED
	add_to_group("enemies")


func cancel_alert() -> void:
	if state == State.CRASHED:
		return
	alert_count = maxi(alert_count - 1, 0)
	if alert_count <= 0:
		state = State.IDLE
		target = null
		velocity = Vector2.ZERO
		if is_in_group("enemies"):
			remove_from_group("enemies")


func crash() -> void:
	state = State.CRASHED
	target = null
	alert_count = 0
	if is_in_group("enemies"):
		remove_from_group("enemies")


func _update_visuals() -> void:
	match state:
		State.IDLE:
			modulate = Color(1, 1, 1, 1)
		State.ALERTED:
			modulate = Color(1, 0.5, 0.5, 1)
		State.CRASHED:
			modulate = Color(0.4, 0.4, 0.4, 1)
