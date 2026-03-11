extends CanvasLayer

const PHRASES = [
	"This cheese has expired, man.",
	"Totally Bogus!!",
	"AHHHHHHHHHHHHHHHHHHHHHHHHHHHH",
	"Well, that didn't go as planned, did it?",
	"[queue sad trombone]",
	"Well what should we try next?",
	"When's this game going to be over?!?!?",
	"Plot Twist: you died",
	"You aimed for the stars...",
	"Have you tried not dying?",
	"The hat survived, at least.",
	"Task failed successfully.",
	"Skill issue.",
	"Error 404: Player not found",
	"Your hat will be missed.",
	"Achievement Unlocked: Game Over",
	"10/10 would die again",
	"You fought bravely. Just not well.",
	"Narrator: It was, in fact, not fine.",
	"Insert coin to continue... just kidding",
	"RIP in peace",
]

var ready_for_input := false


func _ready():
	var font = load("res://assets/ShareTechMono-Regular.ttf")

	# Dark overlay
	var bg = ColorRect.new()
	bg.color = Color(0.03, 0.02, 0.05, 0.0)
	bg.size = Vector2(1280, 720)
	add_child(bg)

	# GAME OVER title
	var title = Label.new()
	title.text = "GAME OVER"
	title.add_theme_font_override("font", font)
	title.add_theme_font_size_override("font_size", 72)
	title.add_theme_color_override("font_color", Color(0.9, 0.15, 0.1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 200)
	title.size = Vector2(1280, 80)
	title.modulate.a = 0.0
	add_child(title)

	# Random phrase
	var phrase = Label.new()
	phrase.text = PHRASES.pick_random()
	phrase.add_theme_font_override("font", font)
	phrase.add_theme_font_size_override("font_size", 28)
	phrase.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
	phrase.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	phrase.position = Vector2(0, 320)
	phrase.size = Vector2(1280, 40)
	phrase.modulate.a = 0.0
	add_child(phrase)

	# Continue prompt
	var prompt = Label.new()
	prompt.text = "Press space to continue"
	prompt.add_theme_font_override("font", font)
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.position = Vector2(0, 500)
	prompt.size = Vector2(1280, 30)
	prompt.modulate.a = 0.0
	add_child(prompt)

	# Animate in sequence
	var tween = create_tween()
	tween.tween_property(bg, "color:a", 0.92, 0.6)
	tween.tween_property(title, "modulate:a", 1.0, 0.4)
	tween.tween_property(phrase, "modulate:a", 1.0, 0.5)
	tween.tween_property(prompt, "modulate:a", 1.0, 0.3)
	tween.tween_callback(func(): ready_for_input = true)


func _unhandled_input(event):
	if ready_for_input and event.is_action_pressed("jump"):
		ready_for_input = false
		var main = get_tree().get_first_node_in_group("game_manager")
		main._finish_game_over()
		get_tree().paused = false
		queue_free()
