extends Control

var title_label
var ball_icon
var time = 0.0


func _ready():
	var bg = ColorRect.new()
	bg.color = Color(0.15, 0.2, 0.3)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 30)
	center.add_child(container)

	title_label = Label.new()
	title_label.text = "Golf"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 80)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	title_label.add_theme_constant_override("shadow_offset_x", 3)
	title_label.add_theme_constant_override("shadow_offset_y", 3)
	container.add_child(title_label)

	var subtitle = Label.new()
	subtitle.text = "A Tiny Golf Adventure"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 22)
	subtitle.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	container.add_child(subtitle)

	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	container.add_child(spacer)

	var play_button = Button.new()
	play_button.text = "Play"
	play_button.add_theme_font_size_override("font_size", 28)
	play_button.custom_minimum_size = Vector2(200, 60)
	play_button.pressed.connect(_on_play_pressed)
	container.add_child(play_button)

	var quit_button = Button.new()
	quit_button.text = "Quit"
	quit_button.add_theme_font_size_override("font_size", 22)
	quit_button.custom_minimum_size = Vector2(200, 50)
	quit_button.pressed.connect(_on_quit_pressed)
	container.add_child(quit_button)

	var version_label = Label.new()
	version_label.text = "v0.1"
	version_label.add_theme_font_size_override("font_size", 14)
	version_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.3))
	version_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version_label.position = Vector2(-50, -30)
	add_child(version_label)

	container.modulate.a = 0.0
	container.scale = Vector2(0.8, 0.8)
	container.pivot_offset = container.size / 2
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(container, "modulate:a", 1.0, 0.6)
	tween.tween_property(container, "scale", Vector2(1.0, 1.0), 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _process(delta):
	time += delta
	if title_label:
		title_label.position.y = sin(time * 2.0) * 5.0


func _on_play_pressed():
	get_tree().change_scene_to_file("res://level_1.tscn")


func _on_quit_pressed():
	get_tree().quit()