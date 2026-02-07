extends RigidBody2D

var shot_power_multiplier = 5.0
var max_shot_distance = 350.0
var rest_velocity_threshold = 5.0
var max_speed = 900.0

signal hit_count_changed

var is_aiming = false
var start_pos = Vector2()
var hit_count = 0
var shot_indicator: Line2D
var was_moving = false
var ball_sprite
var trail_timer = 0.0

var physics_dt: float
var gravity_vector: Vector2
var damp_factor: float

var dot_indicator: Line2D
var power_label: Label


func _ready():
	shot_indicator = $ShotIndicator
	shot_indicator.visible = false
	shot_indicator.width = 2.0
	shot_indicator.top_level = true

	dot_indicator = Line2D.new()
	dot_indicator.width = 2.0
	dot_indicator.top_level = true
	dot_indicator.visible = false
	dot_indicator.default_color = Color(1, 1, 1, 0.5)
	dot_indicator.z_index = 10
	add_child(dot_indicator)

	power_label = Label.new()
	power_label.top_level = true
	power_label.visible = false
	power_label.add_theme_font_size_override("font_size", 14)
	power_label.add_theme_color_override("font_color", Color.WHITE)
	power_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	power_label.add_theme_constant_override("shadow_offset_x", 1)
	power_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(power_label)

	ball_sprite = $Ball
	ball_sprite.scale = Vector2(0.03, 0.03)

	linear_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	linear_damp = 1.2
	angular_damp_mode = RigidBody2D.DAMP_MODE_REPLACE
	angular_damp = 2.0
	gravity_scale = 1.8
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	mass = 0.5

	physics_dt = 1.0 / float(ProjectSettings.get_setting("physics/common/physics_ticks_per_second"))
	var grav_value = ProjectSettings.get_setting("physics/2d/default_gravity")
	var grav_dir = ProjectSettings.get_setting("physics/2d/default_gravity_vector")
	gravity_vector = grav_dir * grav_value * gravity_scale
	damp_factor = maxf(1.0 - physics_dt * linear_damp, 0.0)

	var mat = PhysicsMaterial.new()
	mat.friction = 0.5
	mat.bounce = 0.45
	physics_material_override = mat


func _integrate_forces(state: PhysicsDirectBodyState2D):
	state.linear_velocity = state.linear_velocity.limit_length(max_speed)

	if state.linear_velocity.length() < rest_velocity_threshold and was_moving:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0


func _physics_process(delta):
	if shot_indicator.visible:
		shot_indicator.global_position = global_position
		shot_indicator.global_rotation = 0
	if dot_indicator.visible:
		dot_indicator.global_position = Vector2.ZERO
		dot_indicator.global_rotation = 0

	if linear_velocity.length() > rest_velocity_threshold:
		was_moving = true
		trail_timer += delta
		if trail_timer > 0.05:
			trail_timer = 0.0
			spawn_trail_particle()
	elif was_moving:
		was_moving = false
		trail_timer = 0.0
		spawn_land_particles()
		squash_ball(Vector2(0.039, 0.021), Vector2(0.03, 0.03))


func is_ball_at_rest() -> bool:
	return linear_velocity.length() < rest_velocity_threshold and not was_moving


func _input(event):
	if not is_ball_at_rest():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if global_position.distance_to(get_global_mouse_position()) < 60.0:
					is_aiming = true
					start_pos = global_position
					shot_indicator.visible = true
					dot_indicator.visible = true
					power_label.visible = true
					shot_indicator.global_position = global_position
					shot_indicator.global_rotation = 0
					shot_indicator.points = [Vector2.ZERO, Vector2.ZERO]
			else:
				if is_aiming:
					is_aiming = false
					shot_indicator.visible = false
					dot_indicator.visible = false
					power_label.visible = false
					var end_pos = get_global_mouse_position()
					var shot_vector = start_pos - end_pos
					if shot_vector.length() > max_shot_distance:
						shot_vector = shot_vector.normalized() * max_shot_distance

					if shot_vector.length() > 5.0:
						apply_impulse(shot_vector * shot_power_multiplier)
						spawn_shoot_particles(shot_vector)
						squash_ball(Vector2(0.018, 0.042), Vector2(0.03, 0.03))
						screen_shake(4.0)
						hit_count += 1
						emit_signal("hit_count_changed", hit_count)
	elif event is InputEventMouseMotion:
		if is_aiming:
			update_aim()


func update_aim():
	var mouse_pos = get_global_mouse_position()
	var direction = start_pos - mouse_pos
	if direction.length() > max_shot_distance:
		direction = direction.normalized() * max_shot_distance

	var power_ratio = direction.length() / max_shot_distance
	update_indicator_color(direction.length())

	shot_indicator.points = [Vector2.ZERO, direction * 0.3]

	power_label.text = str(int(power_ratio * 100)) + "%"
	power_label.global_position = global_position + Vector2(15, -25)

	update_trajectory_preview(direction * shot_power_multiplier)


func update_trajectory_preview(impulse: Vector2):
	var points: PackedVector2Array = []
	var vel = impulse / mass
	var pos = global_position
	var dt = physics_dt
	var space = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.new()
	query.exclude = [get_rid()]
	query.collision_mask = collision_mask

	points.append(pos)

	for i in range(90):
		var old_pos = pos

		vel *= damp_factor
		vel += gravity_vector * dt
		pos += vel * dt

		if vel.length() > max_speed:
			vel = vel.limit_length(max_speed)

		query.from = old_pos
		query.to = pos
		var result = space.intersect_ray(query)
		if result:
			points.append(result.position)
			var normal = result.normal
			vel = vel.bounce(normal) * physics_material_override.bounce
			pos = result.position + normal * 2.0

			if vel.length() < rest_velocity_threshold * 2:
				break

		points.append(pos)

		if vel.length() < rest_velocity_threshold:
			break

	dot_indicator.points = points
	dot_indicator.default_color = shot_indicator.default_color * Color(1, 1, 1, 0.4)


func update_indicator_color(power):
	var ratio = power / max_shot_distance
	var color: Color
	if ratio < 0.5:
		color = Color.GREEN.lerp(Color.YELLOW, ratio * 2.0)
	else:
		color = Color.YELLOW.lerp(Color.RED, (ratio - 0.5) * 2.0)
	shot_indicator.default_color = color


func squash_ball(from_scale, to_scale):
	if ball_sprite:
		ball_sprite.scale = from_scale
		var tween = create_tween()
		tween.tween_property(ball_sprite, "scale", to_scale, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func screen_shake(intensity):
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
