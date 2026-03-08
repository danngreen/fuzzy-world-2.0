extends CanvasLayer

var heart_rects: Array[ColorRect] = []
const HEART_FULL = Color(0.9, 0.1, 0.1, 1)
const HEART_EMPTY = Color(0.25, 0.1, 0.1, 1)


func _ready() -> void:
	for child in $HBoxContainer.get_children():
		if child is ColorRect:
			heart_rects.append(child)


func update_hearts(current_health: int) -> void:
	for i in heart_rects.size():
		if i < current_health:
			heart_rects[i].color = HEART_FULL
		else:
			heart_rects[i].color = HEART_EMPTY
