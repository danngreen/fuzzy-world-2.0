extends CanvasLayer

var selected := 0
var labels := []
var arrow: Label
var start_y := 290.0
var spacing := 80.0
var arrow_x: float
var text_x: float
var guide_enabled := false


func _ready():
	var vp := get_viewport().get_visible_rect().size
	var cx := vp.x / 2.0
	text_x = cx - 120.0
	arrow_x = cx - 170.0

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.05, 0.1, 0.92)
	bg.size = vp
	add_child(bg)

	var menu_items = ["Play", "Guide: Off", "Replay Intro"]
	var font = load("res://assets/ShareTechMono-Regular.ttf")

	for i in menu_items.size():
		var label = Label.new()
		label.text = menu_items[i]
		label.add_theme_font_override("font", font)
		label.add_theme_font_size_override("font_size", 52)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.position = Vector2(text_x, start_y + i * spacing)
		label.pivot_offset = Vector2(0, 30)
		add_child(label)
		labels.append(label)

	arrow = Label.new()
	arrow.text = ">"
	arrow.add_theme_font_size_override("font_size", 44)
	arrow.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	arrow.position = Vector2(arrow_x, start_y + 4)
	add_child(arrow)

	_update_selection(true)


func _unhandled_input(event):
	if event.is_action_pressed("size_up") or event.is_action_pressed("move_left"):
		_change_selection(-1)
	elif event.is_action_pressed("size_down") or event.is_action_pressed("move_right"):
		_change_selection(1)
	elif event.is_action_pressed("jump"):
		_confirm()


func _change_selection(dir: int):
	var old = selected
	selected = wrapi(selected + dir, 0, labels.size())
	if old != selected:
		_update_selection(false)


func _update_selection(instant: bool):
	var target_y = start_y + selected * spacing + 4
	if instant:
		arrow.position.y = target_y
	else:
		var tween = arrow.create_tween()
		tween.tween_property(arrow, "position:y", target_y, 0.1).set_ease(Tween.EASE_OUT)

	for i in labels.size():
		if i == selected:
			if not instant:
				labels[i].scale = Vector2(1.0, 1.0)
				var t = labels[i].create_tween()
				t.tween_property(labels[i], "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		else:
			labels[i].scale = Vector2(1.0, 1.0)


func _confirm():
	if selected == 0:  # Play
		var main = get_tree().get_first_node_in_group("game_manager")
		if guide_enabled:
			main.start_guide()
		get_tree().paused = false
		main.initial_spawn()
		queue_free()
	elif selected == 2:  # Replay Intro
		var main = get_tree().get_first_node_in_group("game_manager")
		queue_free()
		main._show_intro_animation()
	elif selected == 1:  # Guide toggle
		guide_enabled = not guide_enabled
		labels[1].text = "Guide: On" if guide_enabled else "Guide: Off"
		labels[1].scale = Vector2(1.0, 1.0)
		var t = labels[1].create_tween()
		t.tween_property(labels[1], "scale", Vector2(1.15, 1.15), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
