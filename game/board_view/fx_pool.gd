class_name FxPool
extends Node2D

const POOL_SIZE := 10

var bursts_emitted := 0

var _particles: Array[CPUParticles2D] = []
var _next := 0


func _ready() -> void:
	var texture := _make_dot_texture()
	for i in POOL_SIZE:
		var p := CPUParticles2D.new()
		p.emitting = false
		p.one_shot = true
		p.explosiveness = 0.95
		p.lifetime = 0.5
		p.texture = texture
		p.direction = Vector2.UP
		p.spread = 180.0
		p.initial_velocity_min = 160.0
		p.initial_velocity_max = 340.0
		p.gravity = Vector2(0, 700)
		p.scale_amount_min = 0.35
		p.scale_amount_max = 0.8
		p.local_coords = false
		add_child(p)
		_particles.append(p)


func burst(at: Vector2, color: Color, amount: int) -> void:
	if amount <= 0 or _particles.is_empty():
		return
	var p := _particles[_next]
	_next = (_next + 1) % POOL_SIZE
	p.position = at
	if p.amount != amount:
		p.amount = amount
	p.color = color
	p.restart()
	bursts_emitted += 1


static func _make_dot_texture() -> Texture2D:
	var image := Image.create(24, 24, false, Image.FORMAT_RGBA8)
	var center := Vector2(11.5, 11.5)
	for y in 24:
		for x in 24:
			var falloff := clampf(1.0 - Vector2(x, y).distance_to(center) / 11.5, 0.0, 1.0)
			image.set_pixel(x, y, Color(1, 1, 1, falloff))
	return ImageTexture.create_from_image(image)
