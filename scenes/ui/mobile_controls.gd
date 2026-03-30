extends CanvasLayer

const FONT_PATH = "res://assets/ShareTechMono-Regular.ttf"

var _btns: Array = []        # [{action: String, rect: Rect2}]
var _active: Dictionary = {} # touch/mouse index -> action name

# Node2D used as a coordinate reference.
# get_global_transform_with_canvas() accounts for viewport stretch + CanvasLayer
# transform — the same technique TouchScreenButton uses internally.
var _ref: Node2D


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	var os_name := OS.get_name()
	if os_name != "iOS" and os_name != "Android" \
			and not (os_name == "Web" and DisplayServer.is_touchscreen_available()):
		return

	# Expand viewport to fill screen so controls can render in the pillarbox margins
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND

	_ref = Node2D.new()
	add_child(_ref)

	# Wait one frame for viewport size to update after aspect change
	await get_tree().process_frame
	_create_buttons()


func _create_buttons() -> void:
	var font := load(FONT_PATH) as Font
	var vp := get_viewport().get_visible_rect().size

	# Left side: movement (anchored to left + bottom edges)
	_def("move_left",  "<",  Rect2(15,      vp.y - 200, 120, 120),  Color(0.15, 0.25, 0.55, 0.8), font, 36)
	_def("move_right", ">",  Rect2(150,     vp.y - 200, 120, 120),  Color(0.15, 0.25, 0.55, 0.8), font, 36)
	_def("jump",    "jump",  Rect2(165/2,   vp.y - 300, 90, 90), Color(0.55, 0.15, 0.15, 0.8), font, 36)

	# Right side: jump + size (anchored to right + bottom edges)
	_def("jump",    "jump",  Rect2(vp.x - 180, vp.y - 200, 190, 120),  Color(0.55, 0.15, 0.15, 0.8), font, 36)
	_def("size_up",    "+",  Rect2(vp.x - 250, vp.y - 300, 120, 120),  Color(0.35, 0.15, 0.55, 0.8), font, 28)
	_def("size_down",  "-",  Rect2(vp.x - 115, vp.y - 300, 120, 120),  Color(0.35, 0.15, 0.55, 0.8), font, 28)


func _input(event: InputEvent) -> void:
	if _btns.is_empty():
		return

	var pos: Vector2
	var pressed: bool
	var idx: int

	if event is InputEventScreenTouch:
		pos     = event.position
		pressed = event.pressed
		idx     = event.index
	else:
		return

	# Convert screen/window coords → CanvasLayer logical coords
	var canvas_pos: Vector2 = _ref.get_global_transform_with_canvas().affine_inverse() * pos

	if pressed:
		for btn in _btns:
			if (btn as Dictionary).rect.has_point(canvas_pos):
				_active[idx] = btn.action
				_fire(btn.action, true)
				return
	else:
		if _active.has(idx):
			_fire(_active[idx], false)
			_active.erase(idx)


func _def(action: String, symbol: String, rect: Rect2,
		col: Color, font: Font, fsize: int) -> void:
	_btns.append({action = action, rect = rect})

	var bg := ColorRect.new()
	bg.position = rect.position
	bg.size = rect.size
	bg.color = col
	add_child(bg)

	var lbl := Label.new()
	lbl.position = rect.position
	lbl.size = rect.size
	lbl.text = symbol
	lbl.add_theme_font_override("font", font)
	lbl.add_theme_font_size_override("font_size", fsize)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lbl)


func _fire(action: String, pressed: bool) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	Input.parse_input_event(e)
