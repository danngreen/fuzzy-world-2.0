extends CanvasLayer

var player: CharacterBody2D = null
var shown_guides := {}
var guide_panel: Control = null
var active_trigger: Node2D = null
var anim_time := 0.0
var anim_update: Callable

# Movement guide nodes
var left_key_bg: ColorRect
var right_key_bg: ColorRect
var fake_player: ColorRect

const KEY_COLOR = Color(0.25, 0.25, 0.3, 1)
const KEY_PRESSED_COLOR = Color(0.7, 0.6, 0.15, 1)
const BOX_BG = Color(0.08, 0.08, 0.12, 0.92)
const ANIM_CYCLE = 2.4


func _physics_process(delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	_check_triggers()

	if guide_panel:
		anim_time += delta
		if anim_update.is_valid():
			anim_update.call()


func _check_triggers():
	# Dismiss if active trigger was freed (level change) or player moved away
	if guide_panel and active_trigger:
		if not is_instance_valid(active_trigger):
			_dismiss_guide()
			return
		if player.global_position.distance_to(active_trigger.global_position) > active_trigger.dismiss_radius:
			_dismiss_guide()
			return

	# Don't check for new triggers while one is showing
	if guide_panel:
		return

	for trigger in get_tree().get_nodes_in_group("guide_triggers"):
		if trigger.guide_id in shown_guides:
			continue
		if player.global_position.distance_to(trigger.global_position) < trigger.trigger_radius:
			shown_guides[trigger.guide_id] = true
			active_trigger = trigger
			_show_guide(trigger.guide_id)
			break


func _show_guide(guide_id: String):
	match guide_id:
		"movement":
			_show_movement_guide()
		"jump":
			_show_jump_guide()
		"grow_shrink":
			_show_growshrink_guide()
		"super_jump":
			_show_superjump_guide()
		_:
			pass


func _dismiss_guide():
	if not guide_panel:
		return
	active_trigger = null
	var panel = guide_panel
	guide_panel = null
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(panel.queue_free)

func _show_movement_guide():
	anim_time = 0.0

	var panel = _make_panel(310, 130)

	# Left arrow key
	left_key_bg = _make_key(panel, 20, 12, "\u2190")

	# Right arrow key
	right_key_bg = _make_key(panel, 76, 12, "\u2192")

	# Ground line (animation area on right side)
	var ground = ColorRect.new()
	ground.color = Color(0.35, 0.35, 0.4, 1)
	ground.size = Vector2(140, 3)
	ground.position = Vector2(148, 60)
	panel.add_child(ground)

	_make_player(panel)

	# Instruction text
	_make_text(panel, "Press \u2190 \u2192 or A D to move", 15, 90)

	anim_update = _update_movement_anim

func _update_movement_anim():
	var phase = fmod(anim_time, ANIM_CYCLE) / ANIM_CYCLE * TAU
	var offset = -sin(phase) * 45.0
	var vel_sign = -cos(phase)

	fake_player.scale.x = sign(vel_sign)
	
	left_key_bg.color = KEY_PRESSED_COLOR if vel_sign < -0.1 else KEY_COLOR
	right_key_bg.color = KEY_PRESSED_COLOR if vel_sign > -0.1 else KEY_COLOR

	fake_player.position.x = 211.0 + offset

func _show_jump_guide():
	anim_time = 0.0
	var panel = _make_panel(310, 130)

	# Actually is SP, not left_key
	left_key_bg = _make_key(panel, 30, 40, "\u2420")
	left_key_bg.size = Vector2(80, 26)

	_make_ground(panel)
	_make_player(panel)
	_make_text(panel, "Press space bar to jump", 15, 90)

	anim_update = _update_jump_anim


func _update_jump_anim():
	const CYCLE = 1.6
	const DELAY = 0.3       # pause on ground before launch
	const VEL = -175.0      # upward velocity (px/s)
	const GRAV = 440.0      # gravity (px/s^2)
	const GROUND_Y = 36.0
	const PEAK_T = DELAY + (-VEL / GRAV)  # ~0.7s

	var t = fmod(anim_time, CYCLE)
	var jump_t = t - DELAY

	if jump_t > 0:
		var y = GROUND_Y + VEL * jump_t + 0.5 * GRAV * jump_t * jump_t
		fake_player.position.y = minf(y, GROUND_Y)
	else:
		fake_player.position.y = GROUND_Y

	# Key lit from just before launch until peak (like holding space)
	left_key_bg.color = KEY_PRESSED_COLOR if (t >= 0.15 and t < PEAK_T) else KEY_COLOR


func _show_growshrink_guide():
	anim_time = 0.0
	var panel = _make_panel(310, 130)

	left_key_bg = _make_key(panel, 30, 15, "\u2191")
	right_key_bg = _make_key(panel, 30, 40, "\u2193")

	_make_ground(panel)
	_make_player(panel)
	fake_player.pivot_offset = Vector2(7, 24)  # scale from feet
	_make_text(panel, "Press \u2191 \u2193 or W S to grow and shrink
		Enemies cause more damage when small
		but you can fit in more places!", 15, 90)
	anim_update = _update_growshrink_anim


func _update_growshrink_anim():
	const CYCLE = 2.4
	# 0.0-0.3: rest at normal
	# 0.3-0.5: up key, grow normal → big
	# 0.5-0.9: rest at big
	# 0.9-1.1: down key, shrink big → small
	# 1.1-1.5: rest at small
	# 1.5-1.7: up key, grow small → normal
	# 1.7-2.4: rest at normal

	var t = fmod(anim_time, CYCLE)
	var s: float
	var up := false
	var down := false

	if t < 0.3:
		s = 1.0
	elif t < 0.5:
		up = true
		s = lerpf(1.0, 1.5, (t - 0.3) / 0.2)
	elif t < 0.9:
		s = 1.5
	elif t < 1.1:
		down = true
		s = lerpf(1.5, 0.65, (t - 0.9) / 0.2)
	elif t < 1.5:
		s = 0.65
	elif t < 1.7:
		up = true
		s = lerpf(0.65, 1.0, (t - 1.5) / 0.2)
	else:
		s = 1.0

	fake_player.scale = Vector2(s, s)
	left_key_bg.color = KEY_PRESSED_COLOR if up else KEY_COLOR
	right_key_bg.color = KEY_PRESSED_COLOR if down else KEY_COLOR


func _show_superjump_guide():
	anim_time = 0.0
	var panel = _make_panel(310, 200)

	# Space bar key
	left_key_bg = _make_key(panel, 15, 15, "\u2420")
	left_key_bg.size = Vector2(80, 26)

	# Down arrow key
	right_key_bg = _make_key(panel, 15, 50, "\u2193")

	# Ground near bottom of panel for tall jump
	var ground = ColorRect.new()
	ground.color = Color(0.35, 0.35, 0.4, 1)
	ground.size = Vector2(140, 3)
	ground.position = Vector2(148, 155)
	panel.add_child(ground)

	_make_player(panel)
	fake_player.position = Vector2(211, 131)
	fake_player.pivot_offset = Vector2(7, 24)  # scale from feet

	_make_text(panel, "Shrink right after jumping\nto launch super-high!", 15, 165)

	anim_update = _update_superjump_anim


func _update_superjump_anim():
	const CYCLE = 3.0
	const JUMP_T = 0.25       # space press
	const SHRINK_T = 0.45     # down press
	const GROW_T = 2.2        # grow back after landing
	const GROW_END = 2.4

	const VEL1 = -300.0       # initial jump velocity
	const GRAV = 480.0
	const BOOST = 1.5         # momentum boost from shrinking
	const GROUND_Y = 155.0
	const SMALL_SCALE = 0.5

	# Pre-compute phase 1 endpoint
	const DT_PRE = SHRINK_T - JUMP_T
	const VEL_AT_SHRINK = VEL1 + GRAV * DT_PRE
	const Y_AT_SHRINK = VEL1 * DT_PRE + 0.5 * GRAV * DT_PRE * DT_PRE
	const VEL2 = VEL_AT_SHRINK * BOOST

	var t = fmod(anim_time, CYCLE)
	var feet_y = GROUND_Y
	var s = 1.0
	var space = false
	var down = false

	if t < JUMP_T:
		pass  # rest on ground
	elif t < SHRINK_T:
		# Normal size jump phase
		space = true
		var dt = t - JUMP_T
		feet_y = GROUND_Y + VEL1 * dt + 0.5 * GRAV * dt * dt
	elif t < GROW_T:
		# Boosted jump (small)
		var dt = t - SHRINK_T
		feet_y = GROUND_Y + Y_AT_SHRINK + VEL2 * dt + 0.5 * GRAV * dt * dt
		feet_y = minf(feet_y, GROUND_Y)
		s = SMALL_SCALE
		space = t < SHRINK_T + 0.1
		down = t < SHRINK_T + 0.15
	elif t < GROW_END:
		# Grow back to normal
		s = lerpf(SMALL_SCALE, 1.0, (t - GROW_T) / (GROW_END - GROW_T))

	fake_player.position.y = feet_y - 24
	fake_player.scale = Vector2(s, s)
	left_key_bg.color = KEY_PRESSED_COLOR if space else KEY_COLOR
	right_key_bg.color = KEY_PRESSED_COLOR if down else KEY_COLOR


# --- Shared helpers ---

func _make_ground(panel):
	var ground = ColorRect.new()
	ground.color = Color(0.35, 0.35, 0.4, 1)
	ground.size = Vector2(140, 3)
	ground.position = Vector2(148, 60)
	panel.add_child(ground)

func _make_player(panel):
	# Fake player (red body like the real player)
	fake_player = ColorRect.new()
	fake_player.color = Color(0.85, 0.15, 0.1, 1)
	fake_player.size = Vector2(14, 24)
	fake_player.position = Vector2(211, 36)
	panel.add_child(fake_player)

	# Hat on fake player
	var hat_top = ColorRect.new()
	hat_top.color = Color(1, 1, 1, 1)
	hat_top.size = Vector2(8, 3)
	hat_top.position = Vector2(2, -11)
	fake_player.add_child(hat_top)
	var hat_brim = ColorRect.new()
	hat_brim.color = Color(1, 1, 1, 1)
	hat_brim.size = Vector2(10, 2)
	hat_brim.position = Vector2(2, -8)
	fake_player.add_child(hat_brim)

func _make_panel(w: float, h: float) -> Control:
	var panel = Control.new()
	panel.position = Vector2(1280 - w - 16, 16)
	add_child(panel)
	guide_panel = panel

	var bg = ColorRect.new()
	bg.color = BOX_BG
	bg.size = Vector2(w, h)
	panel.add_child(bg)

	panel.modulate.a = 0.0
	var tween = panel.create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.4)

	return panel


func _make_key(parent: Control, x: float, y: float, symbol: String) -> ColorRect:
	var key_bg = ColorRect.new()
	key_bg.color = KEY_COLOR
	key_bg.size = Vector2(48, 36)
	key_bg.position = Vector2(x, y)
	parent.add_child(key_bg)

	var lbl = Label.new()
	lbl.text = symbol
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.position = Vector2(15, 5)
	key_bg.add_child(lbl)

	return key_bg


func _make_text(parent: Control, msg: String, x: float, y: float) -> Label:
	var text = Label.new()
	text.text = msg
	text.add_theme_font_size_override("font_size", 15)
	text.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85, 1))
	text.position = Vector2(x, y)
	parent.add_child(text)
	return text
