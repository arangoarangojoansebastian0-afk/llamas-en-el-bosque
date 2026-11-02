class_name Decor
extends Node2D
## Decoración sin colisión: arbustos, flores, setas, troncos caídos y juncos.

enum Kind { BUSH, FLOWERS, MUSHROOMS, LOG, REEDS }

@export var kind: Kind = Kind.BUSH
@export var variant := 0   # 0..2: variación de color

func _draw() -> void:
	draw_colored_polygon(Geo.ellipse_points(Vector2(2.0, 0.0), Vector2(11.0, 4.0)), Color(0.0, 0.0, 0.0, 0.2))
	match kind:
		Kind.BUSH:
			_draw_bush()
		Kind.FLOWERS:
			_draw_flowers()
		Kind.MUSHROOMS:
			_draw_mushrooms()
		Kind.LOG:
			_draw_log()
		Kind.REEDS:
			_draw_reeds()

func _draw_bush() -> void:
	draw_colored_polygon(Geo.ellipse_points(Vector2(0.0, -7.0), Vector2(14.0, 9.0)), Color("2f6a36"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-4.0, -9.0), Vector2(9.0, 7.0)), Color("40873f"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-5.0, -12.0), Vector2(5.0, 3.0)), Color("5fb050"))
	if variant == 1:
		draw_rect(Rect2(4.0, -9.0, 2.0, 2.0), Color("d94a4a"))
		draw_rect(Rect2(-2.0, -5.0, 2.0, 2.0), Color("d94a4a"))
		draw_rect(Rect2(8.0, -5.0, 2.0, 2.0), Color("d94a4a"))

func _draw_flowers() -> void:
	var palette: Array[Color] = [Color("f4f1de"), Color("f6d55c"), Color("e56b8f")]
	var head := palette[variant % 3]
	for i in range(4):
		var x := float(i) * 4.0 - 6.0
		var h := 5.0 + float((i * 3 + variant) % 4)
		draw_rect(Rect2(x, -h, 1.0, h), Color("3f8a3a"))
		draw_rect(Rect2(x - 1.0, -h - 2.0, 3.0, 3.0), head)
		draw_rect(Rect2(x, -h - 1.0, 1.0, 1.0), Color("e8a63a"))

func _draw_mushrooms() -> void:
	draw_rect(Rect2(-5.0, -5.0, 2.0, 5.0), Color("e8dfc2"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-4.0, -6.0), Vector2(5.0, 3.0), 12), Color("c4503a"))
	draw_rect(Rect2(-5.0, -7.0, 1.0, 1.0), Color("f4f1de"))
	draw_rect(Rect2(3.0, -4.0, 2.0, 4.0), Color("e8dfc2"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(4.0, -5.0), Vector2(4.0, 2.0), 12), Color("d9693f"))

func _draw_log() -> void:
	draw_rect(Rect2(-16.0, -9.0, 32.0, 9.0), Color("5b3d27"))
	draw_rect(Rect2(-16.0, -9.0, 32.0, 3.0), Color("7a5636"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-16.0, -4.5), Vector2(3.0, 4.5), 10), Color("c29a62"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-16.0, -4.5), Vector2(1.5, 2.5), 10), Color("8a6a3c"))
	draw_rect(Rect2(4.0, -11.0, 6.0, 2.0), Color("4f9a45"))

func _draw_reeds() -> void:
	for i in range(5):
		var x := float(i) * 3.0 - 6.0
		var h := 12.0 + float((i * 5 + variant) % 7)
		draw_line(Vector2(x, 0.0), Vector2(x + 1.0, -h), Color("6f9a4a"), 1.0)
		if i % 2 == 0:
			draw_rect(Rect2(x, -h - 3.0, 2.0, 4.0), Color("7a5636"))
