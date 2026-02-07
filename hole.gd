extends Area2D

@export var next_level_path: String = ""

var base_position = Vector2()
var time = 0.0
var bob_height = 6.0
var bob_speed = 2.0
var collected = false
var sprite


func _ready():
	base_position = position
	sprite = $Sprite2D
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _process(delta):
	if not collected:
		time += delta
		position.y = base_position.y + sin(time * bob_speed) * bob_height


func _on_body_entered(body):
	if body.name == "Ball" and not collected:
		collected = true
		body.linear_velocity = Vector2.ZERO
		body.angular_velocity = 0.0
		call_deferred("freeze_ball", body)
		spawn_collect_particles()
		play_collect_animation(body.hit_count)


func freeze_ball(body):
	body.freeze = true


func spawn_collect_particles():
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 30.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2(0, 60)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color_ramp = Gradient.new()
	particles.color_ramp.set_color(0, Color(1.0, 0.3, 0.3, 1.0))
	particles.color_ramp.set_color(1, Color(1.0, 0.8, 0.0, 0.0))
	particles.position = global_position
	get_parent().add_child(particles)
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(particles.queue_free)


func play_collect_animation(shots):
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.15)

	var tween2 = create_tween()
	tween2.tween_interval(0.15)
	tween2.tween_property(sprite, "scale", Vector2(0.0, 0.0), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween2.tween_property(sprite, "rotation", TAU, 0.3).from(0.0)

	var tween3 = create_tween()
	tween3.tween_interval(0.15)
	tween3.tween_property(sprite, "modulate:a", 0.0, 0.3)

	await tween2.finished
	show_level_complete(shots)


func show_level_complete(shots):
	var canvas = CanvasLayer.new()
	canvas.layer = 10

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var container = VBoxContainer.new()
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 20)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var title_label = Label.new()
	title_label.text = "Level Complete!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 48)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)

	var shots_label = Label.new()
	shots_label.text = "Shots: " + str(shots)
	shots_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shots_label.add_theme_font_size_override("font_size", 28)
	shots_label.add_theme_color_override("font_color", Color(1, 1, 0.6))

	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 20)

	var restart_button = Button.new()
	restart_button.text = "Restart"
	restart_button.add_theme_font_size_override("font_size", 22)
	restart_button.custom_minimum_size = Vector2(150, 50)
	restart_button.pressed.connect(_on_restart_pressed)

	var next_button = Button.new()
	next_button.text = "Next Level"
	next_button.add_theme_font_size_override("font_size", 22)
	next_button.custom_minimum_size = Vector2(150, 50)
	next_button.pressed.connect(_on_next_level_pressed)

	if next_level_path == "":
		next_button.disabled = true
		next_button.tooltip_text = "No more levels"

	button_container.add_child(restart_button)
	button_container.add_child(next_button)

	container.add_child(title_label)
	container.add_child(shots_label)
	container.add_child(button_container)

	center.add_child(container)
	overlay.add_child(center)
	canvas.add_child(overlay)
	get_tree().current_scene.add_child(canvas)

	container.modulate.a = 0.0
	container.scale = Vector2(0.5, 0.5)
	container.pivot_offset = container.size / 2

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(overlay, "color:a", 0.6, 0.5)
	t.tween_property(container, "modulate:a", 1.0, 0.4).set_delay(0.2)
	t.tween_property(container, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	await t.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP


func _on_restart_pressed():
	get_tree().reload_current_scene()


func _on_next_level_pressed():
	if next_level_path != "":
		get_tree().change_scene_to_file(next_level_path)
