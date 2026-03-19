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

	# Kill any ongoing size tween to avoid visual conflict
	if player.size_tween and player.size_tween.is_valid():
		player.size_tween.kill()

	var sprite: ColorRect = player.get_node("Sprite")
	sprite.pivot_offset = Vector2(14, 48)  # pivot at feet — bottom stays fixed

	var tween := create_tween()
	tween.tween_property(sprite, "scale:y", 0.0, 0.3) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func():
		# Teleport, placing player's feet at the partner tunnel's origin
		player.global_position = Vector2(
			linked_tunnel.global_position.x,
			linked_tunnel.global_position.y - player.size_scale * 24.0
		)
		sprite.pivot_offset = Vector2(14, 48)
		sprite.scale.y = 0.01
		var t2 := create_tween()
		t2.tween_property(sprite, "scale:y", player.size_scale, 0.3) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		t2.tween_callback(func():
			sprite.pivot_offset = Vector2(14, 24)
			player.in_tunnel = false
			transit_in_progress = false
			linked_tunnel.transit_in_progress = false
		)
	)
