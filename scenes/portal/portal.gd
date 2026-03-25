extends Area2D

@export var next_level: PackedScene

var pulse_time: float = 0.0
const PULSE_SPEED = 4
const PULSE_MIN = 0.5
const PULSE_MAX = 1.0

var particles: Array[ColorRect] = []
const PARTICLE_COUNT = 10
const PARTICLE_SPEED = 40.0

const BURST_SPEED = 1200.0
const BURST_LIFETIME = 6
const EMIT_INTERVAL = 0.1
const BURST_COUNT = 36
var burst_particles: Array[ColorRect] = []
var transitioning: bool = false
var transition_timer: float = 0.0
var emit_timer: float = 0.0
const TRANSITION_DELAY = 1.5
var transition_player: CharacterBody2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_spawn_particles()


func _process(delta: float) -> void:
	# Pulsing glow
	pulse_time += delta * PULSE_SPEED
	var h = sin(pulse_time) / 2
	$Visual.color = Color.from_hsv(h, 1.0, 1.0, 1.0)

	# Burst transition
	if transitioning:
		_update_burst(delta)
		transition_timer -= delta
		# Shrink player toward portal center
		if transition_player:
			var t = transition_timer / TRANSITION_DELAY
			transition_player.scale = Vector2(t, t)
			transition_player.global_position = global_position + (transition_player.get_meta("start_pos") - global_position) * t

		if transition_timer <= 0:
			transitioning = false
			if transition_player:
				transition_player.scale = Vector2.ONE
				transition_player = null
			get_tree().call_group("game_manager", "change_level", next_level)
		else:
			emit_timer += delta
			if emit_timer > EMIT_INTERVAL:
				emit_timer = 0
				_spawn_burst()

	# Particle shimmer
	for p in particles:
		p.position.y -= PARTICLE_SPEED * delta
		p.modulate.a -= delta * 0.8
		if p.modulate.a <= 0:
			_reset_particle(p)


func _spawn_particles() -> void:
	for i in PARTICLE_COUNT:
		var p = ColorRect.new()
		p.size = Vector2(3, 3)
		p.color = Color(0.6, 1.0, 0.7, 1)
		_reset_particle(p)
		# Stagger initial positions so they don't all start at the bottom
		p.position.y = randf_range(-48, 0)
		p.modulate = Color.from_hsv(randf(), 0.8, 1.0, 1.0)
		add_child(p)
		particles.append(p)


func _reset_particle(p: ColorRect) -> void:
	p.position = Vector2(randf_range(-10, 10), randf_range(-8, 16))
	p.modulate.a = randf_range(0.6, 1.0)

### BURST
func _update_burst(delta: float) -> void:
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

func _spawn_burst() -> void:
	for i in BURST_COUNT:
		var angle = (TAU / BURST_COUNT) * i
		var p = ColorRect.new()
		p.size = Vector2(4, 4)
		p.color = Color(1, 0.4, 0.1, 1)
		p.position = Vector2(-2, -2)
		p.set_meta("vel", Vector2(cos(angle), sin(angle)) * BURST_SPEED)
		p.set_meta("life", BURST_LIFETIME)
		add_child(p)
		burst_particles.append(p)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and next_level and not transitioning:
		transitioning = true
		transition_timer = TRANSITION_DELAY
		transition_player = body
		transition_player.set_meta("start_pos", body.global_position)
		body.get_node("SFX/Portal/Portal").play()
		_spawn_burst()
