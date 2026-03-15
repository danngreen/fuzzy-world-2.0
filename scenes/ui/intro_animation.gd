extends CanvasLayer

const SCREEN_W := 1280.0
const SCREEN_H := 720.0
const FONT := "res://assets/ShareTechMono-Regular.ttf"
const BODY_COLOR := Color(0.96, 0.03, 0.0)

var _tweens: Array[Tween] = []
var _skip_requested := false
var _root: Control


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.clip_contents = true
	add_child(_root)
	_phase_title()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump") and not _skip_requested:
		_skip_requested = true
		_kill_tweens()
		_go_to_menu()


func _kill_tweens() -> void:
	for t in _tweens:
		if is_instance_valid(t):
			t.kill()
	_tweens.clear()


func _go_to_menu() -> void:
	var main := get_tree().get_first_node_in_group("game_manager")
	if main:
		main._show_intro()
	queue_free()


func _clear() -> void:
	for child in _root.get_children():
		child.queue_free()


func _tw() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t


# --- Drawing helpers ---

func _bg(color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.size = Vector2(SCREEN_W, SCREEN_H)
	_root.add_child(r)
	return r


func _rect(parent: Node, x: float, y: float, w: float, h: float, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.color = color
	r.size = Vector2(w, h)
	r.position = Vector2(x, y)
	parent.add_child(r)
	return r


func _label(text: String, font_size: int, color: Color, y: float) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_override("font", load(FONT))
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(SCREEN_W, font_size + 16)
	lbl.position = Vector2(0, y)
	lbl.modulate.a = 0.0
	_root.add_child(lbl)
	return lbl


# Player body only — Node2D with origin at feet (y=0).
# Body: 28x48 red rect at (-14, -48).
func _make_player_body(parent: Node, cx: float, ground_y: float) -> Node2D:
	var n := Node2D.new()
	n.position = Vector2(cx, ground_y)
	parent.add_child(n)
	var body := ColorRect.new()
	body.color = BODY_COLOR
	body.size = Vector2(28, 48)
	body.position = Vector2(-14, -48)
	n.add_child(body)
	return n


# Add hat to an existing player Node2D (origin at feet).
# Matches player.tscn exactly: brim 18x2 at (-9,-59), top 16x5 at (-9,-64).
func _add_hat_to_player(player: Node2D) -> void:
	var brim := ColorRect.new()
	brim.color = Color.WHITE
	brim.size = Vector2(18, 2)
	brim.position = Vector2(-9, -59)
	player.add_child(brim)
	var top := ColorRect.new()
	top.color = Color.WHITE
	top.size = Vector2(16, 5)
	top.position = Vector2(-9, -64)
	player.add_child(top)


# Standalone hat Node2D — origin at brim bottom (y=0).
# Brim: 18x2 at (-9,-2). Top: 16x5 at (-9,-7).
# Use initial_scale to animate a growing hat (space scene). Default 1.0 = game size.
func _make_hat_node(parent: Node, cx: float, by: float, initial_scale: float = 1.0) -> Node2D:
	var n := Node2D.new()
	n.position = Vector2(cx, by)
	n.scale = Vector2(initial_scale, initial_scale)
	parent.add_child(n)
	var brim := ColorRect.new()
	brim.color = Color.WHITE
	brim.size = Vector2(18, 2)
	brim.position = Vector2(-9, -2)
	n.add_child(brim)
	var top := ColorRect.new()
	top.color = Color.WHITE
	top.size = Vector2(16, 5)
	top.position = Vector2(-9, -7)
	n.add_child(top)
	return n


# ============================================================
# TITLE PHASE (common to all stories)
# ============================================================

func _phase_title() -> void:
	_bg(Color.BLACK)
	var title := _label("HATS IN SPACE", 80, Color.WHITE, 238)
	var sub   := _label("a very true story", 30, Color(0.72, 0.72, 0.72), 346)
	var hint  := _label("[ SPACE to skip ]", 18, Color(0.38, 0.38, 0.38), 688)

	var tw := _tw()
	tw.tween_property(title, "modulate:a", 1.0, 0.7)
	tw.tween_interval(0.2)
	tw.tween_property(sub, "modulate:a", 1.0, 0.5)
	tw.tween_interval(0.3)
	tw.tween_property(hint, "modulate:a", 1.0, 0.5)
	tw.tween_interval(2.5)
	tw.set_parallel(true)
	tw.tween_property(title, "modulate:a", 0.0, 0.5)
	tw.tween_property(sub,   "modulate:a", 0.0, 0.5)
	tw.tween_property(hint,  "modulate:a", 0.0, 0.5)
	tw.set_parallel(false)
	tw.tween_callback(func():
		if not _skip_requested:
			_clear()
			_story_hat_from_space())


# ============================================================
# STORY 1: The Hat from Space
# ============================================================

func _story_hat_from_space() -> void:
	_phase_space()


func _phase_space() -> void:
	_bg(Color(0.02, 0.02, 0.06))

	const PAN := 480.0
	const DUR := 6.5

	# Stars scattered across screen + PAN-distance below so they scroll into view
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in 75:
		var star := ColorRect.new()
		var b := rng.randf_range(0.35, 1.0)
		star.color = Color(b, b, b * rng.randf_range(0.85, 1.0))
		star.size = Vector2(2 if rng.randf() < 0.2 else 1, 2 if rng.randf() < 0.2 else 1)
		star.position = Vector2(rng.randf() * SCREEN_W, rng.randf_range(-80.0, SCREEN_H + PAN))
		_root.add_child(star)
		_tw().tween_property(star, "position:y", star.position.y - PAN, DUR) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Planet surface — starts below screen, pans up into view at the bottom
	var planet_y := SCREEN_H + 30.0
	_tw().tween_property(
		_rect(_root, -50, planet_y, SCREEN_W + 100, 350, Color(0.1, 0.22, 0.1)),
		"position:y", planet_y - PAN, DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Atmosphere glow strip on horizon
	_tw().tween_property(
		_rect(_root, -50, planet_y, SCREEN_W + 100, 14, Color(0.3, 0.75, 0.35, 0.55)),
		"position:y", planet_y - PAN, DUR).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Hat — tiny at top-center, swells and falls as it approaches
	var hat := _make_hat_node(_root, SCREEN_W / 2.0, 80.0, 0.1)
	_tw().tween_property(hat, "scale", Vector2(5.5, 5.5), DUR - 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tw().tween_property(hat, "position:y", SCREEN_H * 0.85, DUR - 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Flash white (atmosphere entry), then cut to surface
	var flash := _rect(_root, 0, 0, SCREEN_W, SCREEN_H, Color(1, 1, 1, 0))
	flash.z_index = 10
	var tw := _tw()
	tw.tween_interval(DUR - 0.4)
	tw.tween_property(flash, "color:a", 1.0, 0.45)
	tw.tween_callback(func():
		if not _skip_requested:
			_clear()
			_phase_surface())


func _phase_surface() -> void:
	const GROUND_Y := 570.0

	_bg(Color(0.38, 0.65, 0.92))
	_rect(_root, 0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y, Color(0.35, 0.25, 0.12))
	_rect(_root, 0, GROUND_Y, SCREEN_W, 5, Color(0.52, 0.4, 0.2))  # horizon strip

	# Background crowd — bodies only (no hats yet, the hat is unique)
	for cx in [180.0, 310.0, 480.0, 820.0, 960.0, 1090.0]:
		_make_player_body(_root, cx, GROUND_Y)

	# The chosen one
	var chosen := _make_player_body(_root, 640.0, GROUND_Y)

	# Hat falls from above. Origin is brim-bottom; landing y = GROUND_Y - 57
	# (brim bottom sits where body top is in the player: -57 in feet-space)
	var hat := _make_hat_node(_root, chosen.position.x, -50.0, 1.0)

	var tw := _tw()
	tw.tween_interval(0.35)
	tw.tween_property(hat, "position:y", GROUND_Y - 57.0, 0.42) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		if not _skip_requested:
			_landing_impact(hat, chosen, GROUND_Y))


func _landing_impact(hat: Node2D, chosen: Node2D, ground_y: float) -> void:
	# Bounce
	var land_y := hat.position.y
	var tw_b := _tw()
	tw_b.tween_property(hat, "position:y", land_y - 10.0, 0.09).set_trans(Tween.TRANS_SINE)
	tw_b.tween_property(hat, "position:y", land_y, 0.11).set_trans(Tween.TRANS_SINE)

	# Dust puff
	var rng := RandomNumberGenerator.new()
	for i in 6:
		var dust := ColorRect.new()
		dust.color = Color(0.65, 0.52, 0.3, 0.85)
		dust.size = Vector2(rng.randf_range(3, 6), rng.randf_range(3, 6))
		dust.position = Vector2(chosen.position.x + rng.randf_range(-14, 14), ground_y - 4)
		_root.add_child(dust)
		var dest := dust.position + Vector2(rng.randf_range(-24, 24), rng.randf_range(-20, -6))
		var tw_d := _tw()
		tw_d.set_parallel(true)
		tw_d.tween_property(dust, "position", dest, 0.38).set_ease(Tween.EASE_OUT)
		tw_d.tween_property(dust, "modulate:a", 0.0, 0.38)
		tw_d.set_parallel(false)
		tw_d.tween_callback(dust.queue_free)

	# Transfer hat from standalone node into chosen player node, then discard standalone
	var tw := _tw()
	tw.tween_interval(0.2)
	tw.tween_callback(func():
		hat.queue_free()
		_add_hat_to_player(chosen))

	# Pause then awaken
	tw.tween_interval(0.7)
	tw.tween_callback(func():
		if not _skip_requested:
			_phase_awaken(chosen, ground_y))


func _phase_awaken(chosen: Node2D, ground_y: float) -> void:
	var orig_cx := chosen.position.x

	# Jiggle
	var tw_jig := _tw()
	for i in 7:
		tw_jig.tween_property(chosen, "position:x",
			orig_cx + (3.5 if i % 2 == 0 else -3.5), 0.05)
	tw_jig.tween_property(chosen, "position:x", orig_cx, 0.04)

	# Look left: flip + walk left a few pixels, then return
	# Look right: walk right a few pixels, then return
	var tw := _tw()
	tw.tween_interval(0.42)
	tw.tween_callback(func(): chosen.scale.x = -1.0)  # face left
	tw.tween_property(chosen, "position:x", orig_cx - 10.0, 0.22).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_callback(func(): chosen.scale.x = 1.0)   # face right
	tw.tween_property(chosen, "position:x", orig_cx, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.25)
	tw.tween_property(chosen, "position:x", orig_cx + 10.0, 0.22).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.35)
	tw.tween_property(chosen, "position:x", orig_cx, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.28)
	tw.tween_callback(func():
		if not _skip_requested:
			_phase_jump(chosen, ground_y))


func _phase_jump(chosen: Node2D, ground_y: float) -> void:
	var orig_y := chosen.position.y

	# Jump up
	_tw().tween_property(chosen, "position:y", orig_y - 130.0, 0.38) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var tw := _tw()
	tw.tween_interval(0.38)
	tw.tween_callback(func():
		# Land
		_tw().tween_property(chosen, "position:y", orig_y, 0.3) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		var tw2 := _tw()
		tw2.tween_interval(0.38)
		tw2.tween_callback(func():
			# Walk right off screen
			_tw().tween_property(chosen, "position:x", SCREEN_W + 100, 1.7) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

			# Fade to black
			var fade := _rect(_root, 0, 0, SCREEN_W, SCREEN_H, Color(0, 0, 0, 0))
			fade.z_index = 20
			var tw3 := _tw()
			tw3.tween_interval(1.0)
			tw3.tween_property(fade, "color:a", 1.0, 0.7)
			tw3.tween_callback(func():
				if not _skip_requested:
					_go_to_menu())))
