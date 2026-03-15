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
			var s := randi() % 3
			if s == 0:
				_story_hat_from_space()
			elif s == 1:
				_story_dino_dig()
			else:
				_story_hat_chooses())


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

	# Planet — single container so everything pans together and fills to screen bottom
	var planet_y := SCREEN_H + 30.0
	var planet := Node2D.new()
	planet.position.y = planet_y
	_root.add_child(planet)
	_tw().tween_property(planet, "position:y", planet_y - PAN, DUR) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Blue atmosphere glow at the horizon (top edge of the planet)
	_rect(planet, -50, -20, SCREEN_W + 100, 24, Color(0.25, 0.65, 1.00, 0.70))
	_rect(planet, -50,   4, SCREEN_W + 100, 20, Color(0.18, 0.52, 0.92, 0.40))

	# Ocean base — extends far below screen so there's no black gap
	_rect(planet, -50, 22, SCREEN_W + 100, SCREEN_H + PAN + 200, Color(0.07, 0.16, 0.48))

	# Green land masses
	_rect(planet,  -30,  48, 310, 210, Color(0.12, 0.38, 0.10))
	_rect(planet,   65,  90, 185, 105, Color(0.08, 0.28, 0.06))  # darker interior
	_rect(planet,  360,  52, 285, 220, Color(0.10, 0.35, 0.09))
	_rect(planet,  700,  85, 355, 180, Color(0.12, 0.40, 0.10))
	_rect(planet,  820, 125, 195, 105, Color(0.08, 0.28, 0.07))  # darker interior

	# Brown / arid zones
	_rect(planet,  255,  82, 130, 135, Color(0.50, 0.34, 0.13))
	_rect(planet,  585, 178, 155, 115, Color(0.46, 0.30, 0.11))
	_rect(planet,   95, 252, 225, 130, Color(0.36, 0.25, 0.09))

	# Polar ice caps
	_rect(planet,  -50, 22, 175, 25, Color(0.86, 0.91, 0.96, 0.65))
	_rect(planet,  960, 22, 430, 22, Color(0.86, 0.91, 0.96, 0.60))

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

	# Alien sun — upper right
	_rect(_root, 1082, 44, 58, 58, Color(1.00, 0.94, 0.55))
	_rect(_root, 1095, 57, 32, 32, Color(1.00, 0.99, 0.82))

	# Clouds
	_rect(_root,   76,  88, 140, 16, Color(0.92, 0.96, 1.0, 0.88))
	_rect(_root,   99,  73, 100, 18, Color(0.92, 0.96, 1.0, 0.88))
	_rect(_root,  508, 118, 118, 15, Color(0.92, 0.96, 1.0, 0.84))
	_rect(_root,  526, 104,  84, 16, Color(0.92, 0.96, 1.0, 0.84))
	_rect(_root,  888,  92, 132, 17, Color(0.92, 0.96, 1.0, 0.88))
	_rect(_root,  910,  78,  94, 17, Color(0.92, 0.96, 1.0, 0.88))

	# Distant hills (bluish — atmospheric perspective)
	var hc := Color(0.30, 0.50, 0.72)
	_rect(_root,    0, 442, 355, 133, hc)
	_rect(_root,   38, 396, 208,  46, hc)
	_rect(_root,  308, 462, 415, 113, hc)
	_rect(_root,  718, 448, 382, 127, hc)
	_rect(_root, 1018, 464, 282, 111, hc)
	_rect(_root, 1098, 428, 205,  36, hc)

	# Ground
	_rect(_root, 0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y, Color(0.35, 0.25, 0.12))
	_rect(_root, 0, GROUND_Y, SCREEN_W, 5, Color(0.52, 0.4, 0.2))

	# Rocks on the ground
	_rect(_root,  128, 558, 24, 14, Color(0.28, 0.20, 0.09))
	_rect(_root,  140, 551, 14,  8, Color(0.28, 0.20, 0.09))
	_rect(_root,  388, 560, 20, 12, Color(0.26, 0.18, 0.08))
	_rect(_root,  758, 555, 28, 16, Color(0.28, 0.20, 0.09))
	_rect(_root,  770, 548, 16,  9, Color(0.26, 0.18, 0.08))
	_rect(_root, 1028, 557, 22, 14, Color(0.28, 0.20, 0.09))

	# Alien teal plants at the crowd edges
	var pc := Color(0.12, 0.44, 0.40)
	for px: float in [46.0, 96.0, 1182.0, 1232.0]:
		_rect(_root, px - 2, GROUND_Y - 34,  4, 34, pc)
		_rect(_root, px - 13, GROUND_Y - 20, 13,  4, pc)
		_rect(_root, px + 2,  GROUND_Y - 20, 13,  4, pc)
		_rect(_root, px -  9, GROUND_Y - 30,  9,  4, pc)
		_rect(_root, px + 2,  GROUND_Y - 30,  9,  4, pc)

	# Background crowd — bodies only (no hats yet, the hat is unique)
	for cx: float in [180.0, 310.0, 480.0, 820.0, 960.0, 1090.0]:
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


# ============================================================
# STORY 2: Dino Dig
# ============================================================

# T-Rex silhouette — Node2D origin at feet (y=0), facing right by default.
func _make_dino(parent: Node, cx: float, ground_y: float) -> Node2D:
	var col  := Color(0.20, 0.36, 0.12)
	var dark := Color(0.13, 0.24, 0.08)
	var n := Node2D.new()
	n.position = Vector2(cx, ground_y)
	parent.add_child(n)
	# Tail
	_rect(n, -62, -38, 42, 10, col)
	_rect(n, -78, -32, 20,  7, col)
	# Spine bumps along back
	_rect(n, -14, -50,  5,  6, dark)
	_rect(n,  -4, -50,  5,  6, dark)
	_rect(n,   6, -50,  5,  5, dark)
	# Body
	_rect(n, -20, -44, 46, 22, col)
	# Neck
	_rect(n,  22, -56, 10, 14, col)
	# Head
	_rect(n,  24, -64, 30, 18, col)
	# Lower jaw (darker)
	_rect(n,  44, -56, 18, 10, dark)
	# Teeth (white, inside lower jaw)
	_rect(n,  46, -55,  3,  5, Color.WHITE)
	_rect(n,  51, -55,  3,  5, Color.WHITE)
	_rect(n,  56, -55,  3,  5, Color.WHITE)
	# Nostril
	_rect(n,  50, -59,  3,  2, dark)
	# Eye + highlight
	_rect(n,  42, -60,  4,  4, dark)
	_rect(n,  43, -61,  2,  2, Color.WHITE)
	# Tiny arm + claw
	_rect(n,  14, -40, 10,  6, dark)
	_rect(n,  20, -36,  6,  7, dark)
	# Legs
	_rect(n, -12, -24, 16, 18, col)
	_rect(n,   4, -24, 14, 18, col)
	# Feet
	_rect(n, -14,  -6, 20,  6, dark)
	_rect(n,   4,  -6, 18,  6, dark)
	return n


func _story_dino_dig() -> void:
	_phase_dino_scene()


func _phase_dino_scene() -> void:
	const GROUND_Y := 520.0
	const DIG_BOBS := 6

	var hill_col  := Color(0.48, 0.30, 0.15)
	var fern_col  := Color(0.14, 0.32, 0.10)
	var frond_col := Color(0.18, 0.40, 0.13)

	# Amber prehistoric sky
	_bg(Color(0.82, 0.52, 0.18))

	# Sun — warm golden square, upper right
	_rect(_root, 1090, 42, 65, 65, Color(1.00, 0.88, 0.28))
	_rect(_root, 1103, 55, 40, 40, Color(1.00, 0.96, 0.62))

	# Distant hill silhouettes (drawn before ground)
	_rect(_root,  -30, 435, 370,  90, hill_col)
	_rect(_root,   30, 362, 225,  73, hill_col)
	_rect(_root,  300, 455, 650,  68, hill_col)
	_rect(_root,  930, 442, 380,  83, hill_col)
	_rect(_root, 1010, 370, 210,  72, hill_col)

	# Rocky brown ground
	_rect(_root, 0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y, Color(0.45, 0.30, 0.14))
	_rect(_root, 0, GROUND_Y, SCREEN_W, 6, Color(0.58, 0.42, 0.22))

	# Dig pit (darker hole in ground at center)
	var pit_cx := 640.0
	var pit_w  := 80.0
	_rect(_root, pit_cx - pit_w * 0.5, GROUND_Y, pit_w, 55, Color(0.28, 0.18, 0.08))

	# Excavated dirt pile next to pit
	var pile_x := pit_cx + pit_w * 0.5
	_rect(_root, pile_x,       GROUND_Y - 14, 52, 14, Color(0.50, 0.34, 0.16))
	_rect(_root, pile_x +  8,  GROUND_Y - 26, 36, 12, Color(0.50, 0.34, 0.16))
	_rect(_root, pile_x + 16,  GROUND_Y - 35, 20,  9, Color(0.50, 0.34, 0.16))

	# Pit rope markers (stakes + rope)
	_rect(_root, pit_cx - pit_w * 0.5 - 5, GROUND_Y - 22,  5, 22, Color(0.62, 0.46, 0.26))
	_rect(_root, pit_cx + pit_w * 0.5,     GROUND_Y - 22,  5, 22, Color(0.62, 0.46, 0.26))
	_rect(_root, pit_cx - pit_w * 0.5 - 3, GROUND_Y - 18, pit_w + 8, 3, Color(0.72, 0.56, 0.30, 0.85))

	# Bystander crowd watching from each side
	for cx: float in [80.0, 134.0, 190.0, 248.0]:
		_make_player_body(_root, cx, GROUND_Y)
	for cx: float in [1032.0, 1090.0, 1148.0, 1200.0]:
		_make_player_body(_root, cx, GROUND_Y)

	# Fern plants flanking the dig site
	var lfx := pit_cx - pit_w * 0.5 - 42.0
	_rect(_root, lfx - 2,  GROUND_Y - 30,  4, 30, fern_col)
	_rect(_root, lfx - 22, GROUND_Y - 22, 22,  5, frond_col)
	_rect(_root, lfx + 2,  GROUND_Y - 22, 22,  5, frond_col)
	_rect(_root, lfx - 16, GROUND_Y - 33, 15,  4, frond_col)
	_rect(_root, lfx + 2,  GROUND_Y - 33, 15,  4, frond_col)
	_rect(_root, lfx - 5,  GROUND_Y - 42,  9,  4, frond_col)
	var rfx := pit_cx + pit_w * 0.5 + 42.0
	_rect(_root, rfx - 2,  GROUND_Y - 30,  4, 30, fern_col)
	_rect(_root, rfx - 22, GROUND_Y - 22, 22,  5, frond_col)
	_rect(_root, rfx + 2,  GROUND_Y - 22, 22,  5, frond_col)
	_rect(_root, rfx - 16, GROUND_Y - 33, 15,  4, frond_col)
	_rect(_root, rfx + 2,  GROUND_Y - 33, 15,  4, frond_col)
	_rect(_root, rfx - 5,  GROUND_Y - 42,  9,  4, frond_col)

	# Two dinos facing inward toward the pit
	var left_dino  := _make_dino(_root, 380.0, GROUND_Y)
	var right_dino := _make_dino(_root, 900.0, GROUND_Y)
	right_dino.scale.x = -1.0

	# Player buried — starts squished flat at ground level, hat on from the start
	var chosen := _make_player_body(_root, pit_cx, GROUND_Y)
	_add_hat_to_player(chosen)
	chosen.scale.y = 0.05

	# Digging bob for both dinos
	for dino: Node2D in [left_dino, right_dino]:
		var base_y := dino.position.y
		var tw_dig := _tw()
		for i in DIG_BOBS:
			tw_dig.tween_property(dino, "position:y", base_y + 12.0, 0.22) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw_dig.tween_property(dino, "position:y", base_y, 0.28) \
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Dirt particles fly up from pit during digging
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 12:
		var dirt := ColorRect.new()
		dirt.color = Color(0.52, 0.38, 0.18, 0.85)
		dirt.size = Vector2(rng.randf_range(3, 7), rng.randf_range(3, 7))
		dirt.position = Vector2(pit_cx + rng.randf_range(-28, 28), GROUND_Y - 4)
		_root.add_child(dirt)
		var dest  := dirt.position + Vector2(rng.randf_range(-35, 35), rng.randf_range(-65, -15))
		var delay := rng.randf_range(0.0, 2.4)
		var dur   := rng.randf_range(0.45, 0.85)
		var tw_d := _tw()
		tw_d.tween_interval(delay)
		tw_d.set_parallel(true)
		tw_d.tween_property(dirt, "position", dest, dur).set_ease(Tween.EASE_OUT)
		tw_d.tween_property(dirt, "modulate:a", 0.0, dur)
		tw_d.set_parallel(false)
		tw_d.tween_callback(dirt.queue_free)

	# After dig finishes, player emerges
	var tw := _tw()
	tw.tween_interval(DIG_BOBS * 0.5)
	tw.tween_callback(func():
		if not _skip_requested:
			_dino_player_emerges(left_dino, right_dino, chosen, GROUND_Y))


func _dino_player_emerges(left_dino: Node2D, right_dino: Node2D, chosen: Node2D, ground_y: float) -> void:
	# Player springs up out of the ground
	_tw().tween_property(chosen, "scale:y", 1.0, 0.8) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Once player is visible, dinos react with surprise hop backward
	var tw := _tw()
	tw.tween_interval(0.65)
	tw.tween_callback(func():
		# Left dino hops left
		var ld_base_y := left_dino.position.y
		_tw().tween_property(left_dino, "position:x", left_dino.position.x - 100.0, 0.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var tw_l := _tw()
		tw_l.tween_property(left_dino, "position:y", ld_base_y - 55.0, 0.22) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_l.tween_property(left_dino, "position:y", ld_base_y, 0.28) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# Right dino hops right
		var rd_base_y := right_dino.position.y
		_tw().tween_property(right_dino, "position:x", right_dino.position.x + 100.0, 0.5) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var tw_r := _tw()
		tw_r.tween_property(right_dino, "position:y", rd_base_y - 55.0, 0.22) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_r.tween_property(right_dino, "position:y", rd_base_y, 0.28) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

		# Brief pause then proceed to player awakening
		var tw2 := _tw()
		tw2.tween_interval(1.5)
		tw2.tween_callback(func():
			if not _skip_requested:
				_phase_awaken(chosen, ground_y)))


# ============================================================
# STORY 3: The Hat Chooses
# ============================================================

# Decorative hat stand: pole + grey hat silhouette.
func _hat_stand(parent: Node, cx: float, ground_y: float) -> void:
	_rect(parent, cx - 2, ground_y - 44,  4, 44, Color(0.45, 0.32, 0.20))
	_rect(parent, cx - 9, ground_y - 46, 18,  2, Color(0.70, 0.70, 0.70))
	_rect(parent, cx - 8, ground_y - 52, 16,  5, Color(0.70, 0.70, 0.70))


func _story_hat_chooses() -> void:
	_phase_hat_shop()


func _phase_hat_shop() -> void:
	const GROUND_Y  := 575.0
	const PED_X     := 640.0
	const PED_HAT_Y := GROUND_Y - 60.0   # hat node brim-bottom rests here

	var ped_col := Color(0.82, 0.74, 0.56)

	# Warm dark interior
	_bg(Color(0.20, 0.13, 0.08))

	# Ceiling band
	_rect(_root, 0, 0, SCREEN_W, 80, Color(0.14, 0.09, 0.05))

	# Shop window — left wall with blue sky glimpse outside
	_rect(_root, 42,  96, 210, 265, Color(0.40, 0.60, 0.80))   # sky
	_rect(_root, 42, 361, 210,  65, Color(0.42, 0.30, 0.15))   # outside ground
	_rect(_root, 38,  90, 222,  10, ped_col)                    # top frame
	_rect(_root, 38, 425, 222,   8, ped_col)                    # bottom frame
	_rect(_root, 38,  90,  10, 345, ped_col)                    # left frame
	_rect(_root, 250, 90,  10, 345, ped_col)                    # right frame

	# Floor — dark wood planks with grain
	_rect(_root, 0, GROUND_Y, SCREEN_W, SCREEN_H - GROUND_Y, Color(0.28, 0.18, 0.10))
	for i in 6:
		_rect(_root, 0, GROUND_Y + 8 + i * 18, SCREEN_W, 3, Color(0.34, 0.22, 0.12))

	# Display counter along right wall
	_rect(_root, 978, 400, 304, 170, Color(0.30, 0.20, 0.11))
	_rect(_root, 978, 395, 304,   6, ped_col)
	for i in 3:
		var hx := 1012.0 + i * 90.0
		_rect(_root, hx - 7, 388, 14, 2, Color(0.82, 0.82, 0.82))
		_rect(_root, hx - 6, 382, 12, 5, Color(0.82, 0.82, 0.82))

	# Decorative hat stands along back wall
	for sx: float in [150.0, 330.0, 960.0, 1140.0]:
		_hat_stand(_root, sx, GROUND_Y)

	# Subtle spotlight cone above pedestal
	_rect(_root, PED_X - 30, 80, 60, GROUND_Y - 80 - 60, Color(1.0, 0.95, 0.70, 0.05))
	# Glow on floor at pedestal base
	_rect(_root, PED_X - 22, GROUND_Y - 3, 44, 5, Color(1.0, 0.95, 0.70, 0.22))

	# Pedestal
	_rect(_root, PED_X - 18, GROUND_Y - 10, 36, 10, ped_col)   # base
	_rect(_root, PED_X -  6, GROUND_Y - 52, 12, 42, ped_col)   # column
	_rect(_root, PED_X - 14, GROUND_Y - 60, 28,  8, ped_col)   # top platform

	# Sign
	var sign := _label("HAT  EMPORIUM", 42, Color(0.92, 0.80, 0.42), 20)
	sign.modulate.a = 1.0

	# The hat of destiny, waiting on its pedestal
	var ped_hat := _make_hat_node(_root, PED_X, PED_HAT_Y)

	# Brief pause to establish the scene, then begin
	var tw := _tw()
	tw.tween_interval(1.0)
	tw.tween_callback(func():
		if not _skip_requested:
			_hat_shop_cust1(ped_hat, PED_X, PED_HAT_Y, GROUND_Y))


# Hat hops slightly away from a customer (it's shy — or picky).
func _hat_shop_cust_hop(hat: Node2D, dir: float) -> void:
	var ox := hat.position.x
	var oy := hat.position.y
	# X: scoot sideways
	_tw().tween_property(hat, "position:x", ox + dir * 20.0, 0.22) \
		.set_trans(Tween.TRANS_SINE)
	# Y: small hop (independent tween)
	var tw_y := _tw()
	tw_y.tween_property(hat, "position:y", oy - 16.0, 0.14) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw_y.tween_property(hat, "position:y", oy, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _hat_shop_cust1(hat: Node2D, ped_x: float, ped_hat_y: float, ground_y: float) -> void:
	var c := _make_player_body(_root, -60.0, ground_y)
	(c.get_child(0) as ColorRect).color = Color(0.52, 0.52, 0.56)
	var tw := _tw()
	tw.tween_property(c, "position:x", ped_x - 55.0, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.25)
	tw.tween_callback(func(): _hat_shop_cust_hop(hat, 1.0))  # hat scoots away
	tw.tween_interval(0.55)
	tw.tween_callback(func(): c.scale.x = -1.0)              # turn around, dejected
	tw.tween_property(c, "position:x", -80.0, 0.75) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		c.queue_free()
		if not _skip_requested:
			_hat_shop_cust2(hat, ped_x, ped_hat_y, ground_y))


func _hat_shop_cust2(hat: Node2D, ped_x: float, ped_hat_y: float, ground_y: float) -> void:
	var c := _make_player_body(_root, SCREEN_W + 60.0, ground_y)
	(c.get_child(0) as ColorRect).color = Color(0.52, 0.52, 0.56)
	c.scale.x = -1.0  # enters from right, facing left
	var tw := _tw()
	tw.tween_property(c, "position:x", ped_x + 55.0, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.25)
	tw.tween_callback(func(): _hat_shop_cust_hop(hat, -1.0))  # hat scoots the other way
	tw.tween_interval(0.55)
	tw.tween_callback(func(): c.scale.x = 1.0)                # turn around
	tw.tween_property(c, "position:x", SCREEN_W + 80.0, 0.75) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		c.queue_free()
		if not _skip_requested:
			_hat_shop_hero(hat, ped_x, ped_hat_y, ground_y))


func _hat_shop_hero(hat: Node2D, ped_x: float, ped_hat_y: float, ground_y: float) -> void:
	var chosen := _make_player_body(_root, -60.0, ground_y)
	var tw := _tw()
	# Hero strolls in, unaware
	tw.tween_property(chosen, "position:x", ped_x + 65.0, 1.0) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_interval(0.15)
	tw.tween_callback(func():
		# Hat LAUNCHES in an arc straight to the hero's head
		var hero_head_y := ground_y - 57.0
		_tw().tween_property(hat, "position:x", chosen.position.x, 0.42) \
			.set_trans(Tween.TRANS_SINE)
		var tw_arc := _tw()
		tw_arc.tween_property(hat, "position:y", ped_hat_y - 62.0, 0.21) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_arc.tween_property(hat, "position:y", hero_head_y, 0.22) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		# After landing: bounce, transfer, then awaken
		var tw2 := _tw()
		tw2.tween_interval(0.42)
		tw2.tween_callback(func():
			var land_y := hat.position.y
			var tw_b := _tw()
			tw_b.tween_property(hat, "position:y", land_y - 8.0, 0.08).set_trans(Tween.TRANS_SINE)
			tw_b.tween_property(hat, "position:y", land_y,       0.10).set_trans(Tween.TRANS_SINE)
			var tw3 := _tw()
			tw3.tween_interval(0.22)
			tw3.tween_callback(func():
				hat.queue_free()
				_add_hat_to_player(chosen)
				var tw4 := _tw()
				tw4.tween_interval(0.5)
				tw4.tween_callback(func():
					if not _skip_requested:
						_phase_awaken(chosen, ground_y)))))
