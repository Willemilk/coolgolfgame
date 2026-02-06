extends Area2D

var base_position = Vector2()
var time = 0.0
var bob_height = 6.0
var bob_speed = 2.0
var collected = false
var sprite


func _ready():
	base_position = position
	sprite = $Sprite2D
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
		body.freeze = true
		spawn_collect_particles()
		play_collect_animation(body.hit_count)


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
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var label = Label.new()
	label.text = "Level Complete!\nShots: " + str(shots)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.add_theme_font_size_override("font_size", 48)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.modulate.a = 0.0
	label.scale = Vector2(0.5, 0.5)
	label.pivot_offset = label.size / 2

	var restart_label = Label.new()
	restart_label.text = "Click anywhere to restart"
	restart_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	restart_label.set_anchors_preset(Control.PRESET_CENTER)
	restart_label.position.y = 60
	restart_label.add_theme_font_size_override("font_size", 20)
	restart_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	restart_label.modulate.a = 0.0

	var canvas = CanvasLayer.new()
	canvas.layer = 10
	canvas.add_child(overlay)
	overlay.add_child(label)
	overlay.add_child(restart_label)
	get_tree().root.add_child(canvas)

	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(overlay, "color:a", 0.6, 0.5)
	t.tween_property(label, "modulate:a", 1.0, 0.4).set_delay(0.2)
	t.tween_property(label, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_property(restart_label, "modulate:a", 1.0, 0.3).set_delay(0.6)

	await t.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.gui_input.connect(_on_overlay_clicked)


func _on_overlay_clicked(event):
	if event is InputEventMouseButton and event.pressed:
		get_tree().reload_current_scene()