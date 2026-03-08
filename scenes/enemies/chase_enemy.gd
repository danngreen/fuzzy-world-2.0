extends CharacterBody2D

@export var speed: float = 120.0
@export var detection_radius: float = 200.0

const GRAVITY = 1200.0
const MAX_FALL_SPEED = 900.0
var eye_pos: float = 0
const EYE_SPEED = 8

var target: CharacterBody2D = null
var chasing: bool = false

const IDLE_BURST_SPEED = 100.0
const CHASE_BURST_SPEED = 400.0
const BURST_LIFETIME = 1
const IDLE_EMIT_INTERVAL = 2
const CHASE_EMIT_INTERVAL = 0.2
const IDLE_BURST_COUNT = 4
const CHASE_BURST_COUNT = 36
var burst_particles: Array[ColorRect] = []
var emit_timer: float = 0.0


func _ready() -> void:
	add_to_group("enemies")
	# Set detection area radius
	var circle = $DetectionArea/CollisionShape2D.shape as CircleShape2D
	circle.radius = detection_radius


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	if chasing and target:
		var dir = sign(target.global_position.x - global_position.x)
		velocity.x = dir * speed
		# Flip sprite
		if dir != 0:
			$Sprite.scale.x = sign(dir) * absf($Sprite.scale.x)
		$eye.color = Color(1, 0, 0, 1)
		eye_pos += delta * EYE_SPEED
		$eye.position.x = sin(eye_pos) * 8
		
	else:
		velocity.x = move_toward(velocity.x, 0, 400.0 * delta)
		$eye.color = Color(0, 0, 0, 1)

	move_and_slide()

	# Emit particle bursts on a timer
	emit_timer -= delta
	if emit_timer <= 0:
		if chasing:
			emit_timer = CHASE_EMIT_INTERVAL
			_spawn_burst(CHASE_BURST_COUNT, CHASE_BURST_SPEED)
		else:
			emit_timer = IDLE_EMIT_INTERVAL
			_spawn_burst(IDLE_BURST_COUNT, IDLE_BURST_SPEED)
 
	# Update burst particles
	var i = burst_particles.size() - 1
	while i >= 0:
		var p = burst_particles[i]
		p.position += p.get_meta("vel") * delta
		var life = p.get_meta("life") - delta
		p.set_meta("life", life)
		p.modulate.a = life / BURST_LIFETIME
		if life <= 0:
			p.queue_free()
			burst_particles.remove_at(i)
		i -= 1


func _spawn_burst(count: int, speed: int) -> void:
	for i in count:
		var angle = (TAU / count) * i
		var p = ColorRect.new()
		p.size = Vector2(2, 2)
		p.color = Color(1, 0.4, 0.1, 1)
		p.position = Vector2(-2, -2)
		p.set_meta("vel", Vector2(cos(angle), sin(angle)) * speed)
		p.set_meta("life", BURST_LIFETIME)
		add_child(p)
		burst_particles.append(p)


func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		target = body
		chasing = true
		emit_timer = 0.0


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body == target:
		chasing = false
		target = null
