extends CanvasLayer

var heart_halves: Array = []  # Each element is [left_rect, right_rect]
var life_icons: Array[Control] = []
const HEART_FULL = Color(0.9, 0.1, 0.1, 1)
const HEART_HALF = Color(0.9, 0.1, 0.1, 0.35)
const HEART_EMPTY = Color(0.25, 0.1, 0.1, 1)


func _ready() -> void:
	_create_hearts()
	_create_life_icons()


func _create_hearts() -> void:
	for child in $HBoxContainer.get_children():
		$HBoxContainer.remove_child(child)
		child.queue_free()

	for i in 5:
		var container = Control.new()
		container.custom_minimum_size = Vector2(28, 28)

		var left = ColorRect.new()
		left.offset_left = 0; left.offset_top = 0
		left.offset_right = 14; left.offset_bottom = 28
		left.color = HEART_FULL
		container.add_child(left)

		var right = ColorRect.new()
		right.offset_left = 14; right.offset_top = 0
		right.offset_right = 28; right.offset_bottom = 28
		right.color = HEART_FULL
		container.add_child(right)

		$HBoxContainer.add_child(container)
		heart_halves.append([left, right])


func _create_life_icons() -> void:
	for i in 3:
		var hat = Control.new()
		hat.custom_minimum_size = Vector2(20, 14)

		# Top is 16 x 5
		var top = ColorRect.new()
		top.offset_left = 0; top.offset_top = 0
		top.offset_right = 16; top.offset_bottom = 5
		hat.add_child(top)
		# Brim is 18 x 2
		var brim = ColorRect.new()
		brim.offset_left = 0; brim.offset_top = top.offset_bottom
		brim.offset_right = 18; brim.offset_bottom = brim.offset_top + 2
		hat.add_child(brim)

		$LivesContainer.add_child(hat)
		life_icons.append(hat)


func update_hearts(current_health: float) -> void:
	for i in heart_halves.size():
		var left: ColorRect = heart_halves[i][0]
		var right: ColorRect = heart_halves[i][1]
		var heart_value := current_health - float(i)

		if heart_value >= 1.0:
			left.color = HEART_FULL
			right.color = HEART_FULL
		elif heart_value >= 0.5:
			left.color = HEART_FULL
			right.color = HEART_HALF
		else:
			left.color = HEART_EMPTY
			right.color = HEART_EMPTY


func update_lives(current_lives: int) -> void:
	for i in life_icons.size():
		if i < current_lives:
			life_icons[i].modulate = Color.WHITE
		else:
			life_icons[i].modulate = Color(1, 1, 1, 0.15)
