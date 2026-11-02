class_name Prop
extends StaticBody2D
## Elemento sólido del escenario (árbol, árbol muerto, roca). Origen = base del objeto.
## Luz desde la izquierda: lado izquierdo claro, derecho en sombra.

enum Kind { PINE, BROADLEAF, DEAD, ROCK }

@export var kind: Kind = Kind.PINE
@export var scale_factor := 1.0
@export var tone_shift := 0.0   # variación de color entre ejemplares (-0.1 a 0.1)

func _ready() -> void:
	var shape := CollisionShape2D.new()
	if kind == Kind.ROCK:
		var circle := CircleShape2D.new()
		circle.radius = 11.0 * scale_factor
		shape.shape = circle
		shape.position = Vector2(0.0, -6.0 * scale_factor)
	else:
		var rect := RectangleShape2D.new()
		rect.size = Vector2(10.0, 7.0) * scale_factor
		shape.shape = rect
		shape.position = Vector2(0.0, -3.0)
	add_child(shape)

func _tone(color: Color) -> Color:
	return color.lightened(tone_shift) if tone_shift >= 0.0 else color.darkened(-tone_shift)

func _draw() -> void:
	var s := scale_factor
	draw_colored_polygon(Geo.ellipse_points(Vector2(4.0 * s, 0.0), Vector2(24.0 * s, 8.0 * s)), Color(0.0, 0.0, 0.0, 0.26))
	match kind:
		Kind.PINE:
			_draw_pine(s)
		Kind.BROADLEAF:
			_draw_broadleaf(s)
		Kind.DEAD:
			_draw_dead(s)
		Kind.ROCK:
			_draw_rock(s)

func _draw_pine(s: float) -> void:
	draw_rect(Rect2(-3.0 * s, -16.0 * s, 6.0 * s, 16.0 * s), Color("5b3d27"))
	draw_rect(Rect2(-3.0 * s, -16.0 * s, 2.0 * s, 16.0 * s), Color("7a5636"))
	var shades: Array[Color] = [Color("2a6a3a"), Color("34804a"), Color("3f9556"), Color("52ad66")]
	for i in range(4):
		var fi := float(i)
		var base_y := (-10.0 - fi * 15.0) * s
		var half := (26.0 - fi * 5.5) * s
		var tip_y := base_y - 26.0 * s
		var lit := _tone(shades[i])
		draw_colored_polygon(PackedVector2Array([Vector2(-half, base_y), Vector2(half, base_y), Vector2(0.0, tip_y)]), lit.darkened(0.22))
		draw_colored_polygon(PackedVector2Array([Vector2(-half, base_y), Vector2(0.0, base_y), Vector2(0.0, tip_y)]), lit)
		draw_colored_polygon(PackedVector2Array([Vector2(-half * 0.6, base_y - 4.0 * s), Vector2(-half * 0.1, base_y - 4.0 * s), Vector2(-half * 0.1, base_y - 14.0 * s)]), lit.lightened(0.14))

func _draw_broadleaf(s: float) -> void:
	draw_rect(Rect2(-4.0 * s, -32.0 * s, 8.0 * s, 32.0 * s), Color("5b3d27"))
	draw_rect(Rect2(-4.0 * s, -32.0 * s, 3.0 * s, 32.0 * s), Color("7a5636"))
	draw_colored_polygon(PackedVector2Array([Vector2(-8.0 * s, 0.0), Vector2(-4.0 * s, -8.0 * s), Vector2(4.0 * s, -8.0 * s), Vector2(8.0 * s, 0.0)]), Color("5b3d27"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(2.0 * s, -52.0 * s), Vector2(33.0 * s, 27.0 * s)), _tone(Color("2a6a33")))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-10.0 * s, -58.0 * s), Vector2(23.0 * s, 19.0 * s)), _tone(Color("3a8040")))
	draw_colored_polygon(Geo.ellipse_points(Vector2(10.0 * s, -54.0 * s), Vector2(20.0 * s, 16.0 * s)), _tone(Color("2f7437")))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-12.0 * s, -66.0 * s), Vector2(13.0 * s, 9.0 * s)), _tone(Color("5aab50")))
	draw_colored_polygon(Geo.ellipse_points(Vector2(5.0 * s, -69.0 * s), Vector2(9.0 * s, 7.0 * s)), _tone(Color("6fc25e")))

func _draw_dead(s: float) -> void:
	var char_color := Color("2a2623")
	draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(16.0 * s, 6.0 * s)), Color("3b3633"))
	draw_rect(Rect2(-3.0 * s, -48.0 * s, 6.0 * s, 48.0 * s), char_color)
	draw_rect(Rect2(-3.0 * s, -48.0 * s, 2.0 * s, 48.0 * s), Color("3d3733"))
	draw_line(Vector2(0.0, -30.0 * s), Vector2(-14.0 * s, -44.0 * s), char_color, 3.0)
	draw_line(Vector2(0.0, -38.0 * s), Vector2(12.0 * s, -52.0 * s), char_color, 3.0)
	draw_line(Vector2(0.0, -46.0 * s), Vector2(-6.0 * s, -58.0 * s), char_color, 2.0)

func _draw_rock(s: float) -> void:
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13.0 * s, 0.0), Vector2(-10.0 * s, -14.0 * s), Vector2(0.0, -19.0 * s),
		Vector2(11.0 * s, -13.0 * s), Vector2(14.0 * s, 0.0)]), Color("6d7370"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10.0 * s, -14.0 * s), Vector2(0.0, -19.0 * s), Vector2(-1.0 * s, -8.0 * s),
		Vector2(-8.0 * s, -4.0 * s)]), Color("9aa29d"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(2.0 * s, -18.0 * s), Vector2(11.0 * s, -13.0 * s), Vector2(14.0 * s, 0.0),
		Vector2(2.0 * s, -2.0 * s)]), Color("565c59"))
