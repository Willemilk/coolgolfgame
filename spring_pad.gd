extends Area2D

@export var launch_force: float = 800.0
@export var direction: Vector2 = Vector2.UP

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Ball":
		var launch = direction.normalized() * launch_force
		body.linear_velocity = launch
		body.angular_velocity = 0.0
		spawn_particles()

func spawn_particles():
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 10
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = direction.normalized()
	particles.spread = 25.0
	particles.initial_velocity_min = 60.0
	particles.initial_velocity_max = 120.0
	particles.gravity = Vector2(0, 150)
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.color = Color(1.0, 0.8, 0.0, 0.9)
	particles.position = global_position
	get_parent().add_child(particles)
	var tween = create_tween()
	tween.tween_interval(1.0)
	tween.tween_callback(particles.queue_free)