class_name MenuBackdrop
extends Control
## Fondo del menú principal: cielo nocturno con resplandor de incendio, luna, siluetas de
## pinos en capas y brasas que suben.

var _stars: Array[Vector2] = []
var _embers: CPUParticles2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(90):
		_stars.append(Vector2(rng.randf(), rng.randf() * 0.55))
	_embers = CPUParticles2D.new()
	_embers.amount = 70
	_embers.lifetime = 5.0
	_embers.preprocess = 5.0
	_embers.direction = Vector2(0.0, -1.0)
	_embers.spread = 22.0
	_embers.gravity = Vector2(10.0, -25.0)
	_embers.initial_velocity_min = 20.0
	_embers.initial_velocity_max = 60.0
	_embers.scale_amount_min = 2.0
	_embers.scale_amount_max = 4.0
	_embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_embers.color_ramp = Geo.ramp3(Color("ffd166"), Color("ef6a3a"), Color(0.4, 0.1, 0.1, 0.0))
	add_child(_embers)
	resized.connect(_on_resized)
	_on_resized()

func _on_resized() -> void:
	_embers.position = Vector2(size.x * 0.5, size.y)
	_embers.emission_rect_extents = Vector2(size.x * 0.5, 8.0)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var top := Color(0.04, 0.06, 0.13, 1.0)
	var bottom := Color(0.5, 0.17, 0.08, 1.0)
	var bands := 32
	for i in range(bands):
		var f := float(i) / float(bands)
		draw_rect(Rect2(0.0, h * f, w, h / float(bands) + 1.0), top.lerp(bottom, f * f))
	for star in _stars:
		draw_rect(Rect2(star.x * w, star.y * h, 2.0, 2.0), Color(1.0, 1.0, 0.9, 0.7))
	var moon := Vector2(w * 0.8, h * 0.2)
	draw_colored_polygon(Geo.ellipse_points(moon, Vector2(64.0, 64.0), 32), Color(0.9, 0.88, 0.75, 0.08))
	draw_colored_polygon(Geo.ellipse_points(moon, Vector2(44.0, 44.0), 32), Color(0.9, 0.88, 0.75, 0.15))
	draw_colored_polygon(Geo.ellipse_points(moon, Vector2(32.0, 32.0), 32), Color(0.93, 0.9, 0.78, 0.95))
	draw_colored_polygon(Geo.ellipse_points(Vector2(w * 0.5, h * 0.92), Vector2(w * 0.6, h * 0.22), 40), Color(1.0, 0.4, 0.1, 0.16))
	_draw_ridge(h * 0.74, 150.0, Color(0.16, 0.08, 0.08, 1.0), 1.0, 46.0)
	_draw_ridge(h * 0.86, 190.0, Color(0.09, 0.06, 0.06, 1.0), 3.0, 58.0)
	_draw_ridge(h * 1.0, 250.0, Color(0.04, 0.03, 0.04, 1.0), 5.0, 76.0)

func _draw_ridge(base_y: float, max_height: float, color: Color, seed_value: float, spacing: float) -> void:
	var x := -20.0
	var index := 0
	while x < size.x + 40.0:
		var wave := 0.5 + 0.5 * sin(float(index) * 1.7 + seed_value) * cos(float(index) * 0.6 + seed_value * 2.0)
		var height := max_height * (0.45 + 0.55 * wave)
		for tier in range(3):
			var ft := float(tier)
			var y_base := base_y - height * ft * 0.28
			var half := spacing * (0.62 - ft * 0.14)
			var tip := y_base - height * 0.42
			draw_colored_polygon(PackedVector2Array([Vector2(x - half, y_base), Vector2(x + half, y_base), Vector2(x, tip)]), color)
		draw_rect(Rect2(x - 3.0, base_y, 6.0, size.y), color)
		x += spacing * 0.8
		index += 1
