extends RigidBody2D

var shot_power_multiplier = 0.8
var max_shot_distance = 200.0
var rest_velocity_threshold = 2.0

signal hit_count_changed

var is_aiming = false
var start_pos = Vector2()
var hit_count = 0
var shot_indicator
var was_moving = false
var ball_sprite
var trail_timer = 0.0


func _ready():
	shot_indicator = $ShotIndicator
	shot_indicator.visible = false
	shot_indicator.width = 3.0
	shot_indicator.top_level = true
	ball_sprite = $Ball
	ball_sprite.scale = Vector2(0.05, 0.05)
	linear_damp = 5.0
	angular_damp = 5.0
	gravity_scale = 1.0


func _physics_process(delta):
	if shot_indicator.visible:
		shot_indicator.global_position = global_position
		shot_indicator.global_rotation = 0

	if linear_velocity.length() > rest_velocity_threshold:
		was_moving = true
		trail_timer += delta
		if trail_timer > 0.05:
			trail_timer = 0.0
			spawn_trail_particle()
	elif was_moving:
		was_moving = false
		trail_timer = 0.0
		linear_velocity = Vector2.ZERO
		angular_velocity = 0.0
		spawn_land_particles()
		squash_ball(Vector2(0.065, 0.035), Vector2(0.05, 0.05))


func _input(event):
	if linear_velocity.length() < rest_velocity_threshold and not was_moving:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed:
					if global_position.distance_to(get_global_mouse_position()) < 50.0:
						is_aiming = true
						start_pos = global_position
						shot_indicator.visible = true
						shot_indicator.global_position = global_position
						shot_indicator.global_rotation = 0
						shot_indicator.points = [Vector2.ZERO, Vector2.ZERO]
				else:
					if is_aiming:
						is_aiming = false
						shot_indicator.visible = false
						var end_pos = get_global_mouse_position()
						var shot_vector = start_pos - end_pos
						if shot_vector.length() > max_shot_distance:
							shot_vector = shot_vector.normalized() * max_shot_distance

						if shot_vector.length() > 5.0:
							apply_impulse(shot_vector * shot_power_multiplier)
							spawn_shoot_particles(shot_vector)
							squash_ball(Vector2(0.03, 0.07), Vector2(0.05, 0.05))
							screen_shake(3.0, 0.15)
							hit_count += 1
							emit_signal("hit_count_changed", hit_count)
		elif event is InputEventMouseMotion:
			if is_aiming:
				var mouse_pos = get_global_mouse_position()
				var direction = start_pos - mouse_pos
				if direction.length() > max_shot_distance:
					direction = direction.normalized() * max_shot_distance
				shot_indicator.points = [Vector2.ZERO, direction]
				update_indicator_color(direction.length())


func update_indicator_color(power):
	var ratio = power / max_shot_distance
	var color = Color.GREEN.lerp(Color.RED, ratio)
	shot_indicator.default_color = color


func squash_ball(from_scale, to_scale):
	if ball_sprite:
		ball_sprite.scale = from_scale
		var tween = create_tween()
		tween.tween_property(ball_sprite, "scale", to_scale, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func screen_shake(intensity, duration):
	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.03)
		tween.tween_property(camera, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.03)
		tween.tween_property(camera, "offset", Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity)), 0.03)
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.06)


func spawn_shoot_particles(shot_vector):
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = -shot_vector.normalized()
	particles.spread = 30.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2(0, 100)
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.color = Color(1.0, 1.0, 1.0, 0.8)
	particles.position = global_position
	get_parent().add_child(particles)
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(particles.queue_free)


func spawn_land_particles():
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 8
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 60.0
	particles.initial_velocity_min = 15.0
	particles.initial_velocity_max = 35.0
	particles.gravity = Vector2(0, 120)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = Color(0.6, 0.4, 0.2, 0.7)
	particles.position = global_position
	get_parent().add_child(particles)
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(particles.queue_free)


func spawn_trail_particle():
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 3
	particles.lifetime = 0.3
	particles.explosiveness = 1.0
	particles.direction = Vector2.UP
	particles.spread = 180.0
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 8.0
	particles.gravity = Vector2.ZERO
	particles.scale_amount_min = 0.5
	particles.scale_amount_max = 1.5
	particles.color = Color(1.0, 1.0, 1.0, 0.3)
	particles.position = global_position
	get_parent().add_child(particles)
	var tween = create_tween()
	tween.tween_interval(0.8)
	tween.tween_callback(particles.queue_free)