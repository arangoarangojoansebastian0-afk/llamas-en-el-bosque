class_name Refuge
extends Node2D
## Refugio: claro seguro al que se guía a los animales rescatados.

@export var radius_x := 90.0
@export var radius_y := 56.0

func contains(point: Vector2) -> bool:
	var offset := point - global_position
	return Vector2(offset.x / radius_x, offset.y / radius_y).length() < 1.0

func _draw() -> void:
	draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(radius_x, radius_y)), Color(0.45, 0.75, 0.4, 0.28))
	draw_polyline(_ring_closed(), Color(0.7, 0.9, 0.55, 0.7), 2.0)
	for i in range(14):
		var angle := TAU * float(i) / 14.0
		var stone := Vector2(cos(angle) * radius_x, sin(angle) * radius_y)
		draw_rect(Rect2(stone.x - 3.0, stone.y - 2.0, 6.0, 4.0), Color("8a8f88"))
	var sign_base := Vector2(-radius_x * 0.55, -radius_y * 0.2)
	draw_rect(Rect2(sign_base.x - 1.0, sign_base.y - 18.0, 3.0, 18.0), Color("5b3d27"))
	draw_rect(Rect2(sign_base.x - 14.0, sign_base.y - 28.0, 30.0, 11.0), Color("8a5a36"))
	draw_rect(Rect2(sign_base.x - 12.0, sign_base.y - 26.0, 26.0, 7.0), Color("c9a468"))
	draw_string(ThemeDB.fallback_font, Vector2(sign_base.x - 11.0, sign_base.y - 20.0), "REFUGIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("3a2a1a"))

func _ring_closed() -> PackedVector2Array:
	var points := Geo.ellipse_points(Vector2.ZERO, Vector2(radius_x, radius_y), 40)
	points.append(points[0])
	return points
