extends Camera2D

@export var target_path: NodePath
@export var smoothing: float = 5.0

@onready var target: Node2D = get_node(target_path)

var tunnel_active := false


func _process(_delta: float) -> void:
	if not tunnel_active:
		return
	# Runs every render frame — stays in sync with the tween that drives zoom
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var sprite: ColorRect = player.get_node("Sprite")
		var inv: float = player.size_scale / zoom.x
		var f := signf(sprite.scale.x) if sprite.scale.x != 0.0 else 1.0
		sprite.scale = Vector2(f * inv, inv)


func _physics_process(delta: float) -> void:
	if tunnel_active:
		return
	if target:
		global_position = global_position.lerp(target.global_position, smoothing * delta)


# Pure zoom-in → hold → teleport → zoom-out. No camera panning.
# Call this after setting global_position to enter_center.
func tunnel_transition(enter_center: Vector2, exit_center: Vector2,
		midpoint_fn: Callable, complete_fn: Callable) -> void:
	tunnel_active = true
	const ZOOM_IN   := 0.90
	const HOLD      := 0.24
	const ZOOM_OUT  := 0.90
	const PEAK_ZOOM := 46.0

	var t := create_tween()
	t.tween_property(self, "zoom", Vector2(PEAK_ZOOM, PEAK_ZOOM), ZOOM_IN) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_interval(HOLD)
	t.tween_callback(func():
		midpoint_fn.call()
		global_position = exit_center
		var t2 := create_tween()
		t2.tween_property(self, "zoom", Vector2(1, 1), ZOOM_OUT) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		t2.tween_callback(func():
			tunnel_active = false
			complete_fn.call()
		)
	)
