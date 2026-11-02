class_name Geo
extends RefCounted
## Utilidades geométricas compartidas (evita duplicar código entre escenas).

static func ellipse_points(center: Vector2, radii: Vector2, segments: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in range(segments):
		var angle := TAU * float(i) / float(segments)
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	return points

static func distance_to_polyline(point: Vector2, points: Array[Vector2]) -> float:
	var best := INF
	for i in range(points.size() - 1):
		var a: Vector2 = points[i]
		var b: Vector2 = points[i + 1]
		var segment := b - a
		var t := clampf((point - a).dot(segment) / segment.length_squared(), 0.0, 1.0)
		best = minf(best, point.distance_to(a + segment * t))
	return best

static func ramp3(first: Color, middle: Color, last: Color) -> Gradient:
	var ramp := Gradient.new()
	ramp.set_color(0, first)
	ramp.set_color(1, last)
	ramp.add_point(0.5, middle)
	return ramp

## Rectángulo reflejado horizontalmente (direction = 1 normal, -1 espejo). Para sprites dibujados.
static func flip_rect(x: float, y: float, w: float, h: float, direction: float) -> Rect2:
	var x0 := x * direction
	var x1 := (x + w) * direction
	return Rect2(minf(x0, x1), y, absf(x1 - x0), h)
