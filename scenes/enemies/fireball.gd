extends Area2D

const GRAVITY = 1200.0
const MAX_FALL_SPEED = 900.0

var fall_speed: float = 0.0


func _ready():
	body_entered.connect(_on_body_entered)


func _physics_process(delta):
	fall_speed = minf(fall_speed + GRAVITY * delta, MAX_FALL_SPEED)
	global_position.y += fall_speed * delta
	# Slight orange/yellow flicker
	modulate.g = randf_range(0.85, 1.0)
	modulate.b = randf_range(0.6, 0.85)


func _on_body_entered(body):
	if body.is_in_group("player"):
		var away_dir = sign(body.global_position.x - global_position.x)
		if away_dir == 0:
			away_dir = 1.0
		body.velocity.x = away_dir * 300.0 / body.SIZE_PARAMS[body.size_scale]["mass"]
		body.velocity.y = -200.0
		if not body.invincible:
			body.spawn_fire_effect()
		body.take_damage()
		queue_free()
	elif not body.is_in_group("enemies") and not body.is_in_group("drone_guards"):
		_spawn_splash()
		queue_free()


func _spawn_splash():
	var pos = global_position
	for i in 6:
		var p = ColorRect.new()
		p.size = Vector2(3, 3)
		p.color = Color(1, randf_range(0.3, 0.6), 0, 1)
		get_parent().add_child(p)
		p.global_position = pos + Vector2(randf_range(-8, 8), randf_range(-4, 0))
		var dest = p.position + Vector2(randf_range(-30, 30), randf_range(-60, -15))
		var tween = p.create_tween()
		tween.set_parallel(true)
		tween.tween_property(p, "position", dest, 0.4)
		tween.tween_property(p, "modulate:a", 0.0, 0.4)
		tween.set_parallel(false)
		tween.tween_callback(p.queue_free)
