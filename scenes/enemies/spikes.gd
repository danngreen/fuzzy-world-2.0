@tool
extends StaticBody2D

@export var spike_count: int = 5:
	set(v):
		spike_count = maxi(v, 1)
		_update_visuals()

@export var spike_color: Color = Color(0.6, 0.6, 0.65, 1):
	set(v):
		spike_color = v
		_update_visuals()

const SPIKE_W := 16.0
const SPIKE_H := 12.0


func _ready() -> void:
	add_to_group("spikes")
	_update_visuals()


func _update_visuals() -> void:
	if not is_node_ready():
		return

	# Clear old spike visuals
	for child in get_children():
		if child is ColorRect:
			child.queue_free()

	var total_w := spike_count * SPIKE_W

	# Collision shape covers full spike area
	$CollisionShape2D.shape = RectangleShape2D.new()
	$CollisionShape2D.shape.size = Vector2(total_w, SPIKE_H)
	$CollisionShape2D.position.y = -SPIKE_H / 2.0

	# Each spike: 3 layers from tip (top) to base (bottom)
	var layers := [[2.0, 4.0], [8.0, 4.0], [14.0, 4.0]]
	for i in spike_count:
		var base_x := -total_w / 2.0 + i * SPIKE_W
		var y := -SPIKE_H
		for layer in layers:
			var w: float = layer[0]
			var h: float = layer[1]
			var rect = ColorRect.new()
			rect.color = spike_color
			rect.size = Vector2(w, h)
			rect.position = Vector2(base_x + (SPIKE_W - w) / 2.0, y)
			add_child(rect)
			y += h
