extends Area2D

@export var destination: Vector2 = Vector2.ZERO

var transit_in_progress := false

const COLS := 7
const ROWS := 12
const DISSOLVE_TIME  := 0.7   # total dissolve duration (first block to last block starting)
const FADE_DUR       := 0.22  # each block fade duration
const MATERIALIZE_TIME := 0.6


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if transit_in_progress:
		return
	if not body.is_in_group("player"):
		return
	_begin_transit(body)


func _build_blocks(player_n: Node2D, sz: float, sprite_color: Color, alpha: float) -> Array:
	# Sprite covers (-14*sz, -24*sz) to (14*sz, 24*sz) in player-local space.
	var block_w: float = 28.0 * sz / COLS
	var block_h: float = 48.0 * sz / ROWS
	var offset_x: float = -14.0 * sz
	var offset_y: float = -24.0 * sz
	var blocks: Array = []
	for row in ROWS:
		for col in COLS:
			var b := ColorRect.new()
			b.size = Vector2(block_w + 1.0, block_h + 1.0)  # +1 avoids seam gaps
			b.color = sprite_color
			b.position = Vector2(offset_x + col * block_w, offset_y + row * block_h)
			b.modulate.a = alpha
			b.z_index = 5
			player_n.add_child(b)
			blocks.append(b)
	return blocks


func _begin_transit(player: Node) -> void:
	transit_in_progress = true
	player.in_tunnel = true
	player.velocity = Vector2.ZERO

	if player.size_tween and player.size_tween.is_valid():
		player.size_tween.kill()

	player.get_node("SFX/Teleport/Teleport").play()

	var player_n  := player as Node2D
	var sz: float  = player.size_scale
	var sprite: ColorRect = player.get_node("Sprite")
	var body_color := sprite.color

	# Show dissolve grid, hide real sprite
	var blocks := _build_blocks(player_n, sz, body_color, 1.0)
	sprite.visible = false
	player.get_node("CollisionShape2D").disabled = true

	# Shuffle for random dissolve order
	blocks.shuffle()

	# Stagger fade-out tweens across DISSOLVE_TIME
	var interval: float = (DISSOLVE_TIME - FADE_DUR) / maxf(blocks.size() - 1, 1)
	for i in blocks.size():
		var b: ColorRect = blocks[i]
		var tw := create_tween()
		tw.tween_interval(i * interval)
		tw.tween_property(b, "modulate:a", 0.0, FADE_DUR)

	# After all blocks have faded: teleport + materialize
	var finish := create_tween()
	finish.tween_interval(DISSOLVE_TIME + FADE_DUR)
	finish.tween_callback(func():
		for b in blocks:
			b.queue_free()

		# Teleport
		player_n.global_position = destination

		# Snap camera — no panning
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.global_position = destination

		# Materialize grid fades in
		var blocks2 := _build_blocks(player_n, sz, body_color, 0.0)
		blocks2.shuffle()
		var interval2: float = (MATERIALIZE_TIME - FADE_DUR) / maxf(blocks2.size() - 1, 1)
		for i in blocks2.size():
			var b: ColorRect = blocks2[i]
			var tw := create_tween()
			tw.tween_interval(i * interval2)
			tw.tween_property(b, "modulate:a", 1.0, FADE_DUR)

		var done := create_tween()
		done.tween_interval(MATERIALIZE_TIME + FADE_DUR)
		done.tween_callback(func():
			for b in blocks2:
				b.queue_free()
			sprite.visible = true
			player.get_node("CollisionShape2D").disabled = false
			player.in_tunnel = false
			transit_in_progress = false
		)
	)
