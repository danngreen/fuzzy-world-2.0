extends Area2D

@export var linked_tunnel: Node

var transit_in_progress := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if transit_in_progress or not linked_tunnel or linked_tunnel.transit_in_progress:
		return
	if not body.is_in_group("player"):
		return
	_begin_transit(body)


func _begin_transit(player: Node) -> void:
	transit_in_progress = true
	linked_tunnel.transit_in_progress = true
	player.in_tunnel = true
	player.velocity = Vector2.ZERO
	player.get_node("CollisionShape2D").disabled = true

	if player.size_tween and player.size_tween.is_valid():
		player.size_tween.kill()

	var partner   := linked_tunnel as Node2D
	var player_n  := player as Node2D
	var sz: float  = player.size_scale

	# Where the player's centre should stand inside each tunnel
	var enter_target := Vector2(global_position.x, global_position.y - sz * 24.0)
	var exit_target  := Vector2(partner.global_position.x, partner.global_position.y - sz * 24.0)

	# Inner-rect centre (24 px above foot origin) — camera focus point
	var enter_center := global_position + Vector2(0, -24)
	var exit_center  := partner.global_position + Vector2(0, -24)

	# Phase 1: slide player to tunnel centre
	var slide := create_tween()
	slide.tween_property(player_n, "global_position", enter_target, 0.35) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	slide.tween_callback(func():
		# Phase 2+: snap camera to enter centre, then pure zoom
		var camera = get_viewport().get_camera_2d()
		camera.global_position = enter_center

		var on_midpoint := func():
			player_n.global_position = exit_target

		var on_complete := func():
			var sprite: ColorRect = player.get_node("Sprite")
			var f := signf(sprite.scale.x) if sprite.scale.x != 0.0 else 1.0
			sprite.scale = Vector2(f * sz, sz)
			player.get_node("CollisionShape2D").disabled = false
			player.in_tunnel = false
			transit_in_progress = false
			linked_tunnel.transit_in_progress = false

		camera.tunnel_transition(enter_center, exit_center, on_midpoint, on_complete)
	)
