class_name ForestGround
extends Node2D
## Suelo de la región: hierba con parches de color, sendero con guijarros y estanque.
## Se dibuja una sola vez.

var world_rect := Rect2()
var path_points: Array[Vector2] = []
var pond_center := Vector2.ZERO
var pond_radii := Vector2(95.0, 58.0)

func _draw() -> void:
	draw_rect(world_rect, Color("4f7f3b"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261105
	for i in range(190):
		var center := Vector2(rng.randf_range(0.0, world_rect.size.x), rng.randf_range(0.0, world_rect.size.y))
		var r := rng.randf_range(36.0, 110.0)
		var roll := rng.randf()
		var tone := Color("5b8f43") if roll < 0.45 else (Color("447334") if roll < 0.85 else Color("6a9a48"))
		draw_colored_polygon(Geo.ellipse_points(center, Vector2(r, r * 0.6)), tone)
	var path := PackedVector2Array(path_points)
	draw_polyline(path, Color("6b583a"), 62.0, true)
	draw_polyline(path, Color("a38a5e"), 52.0, true)
	draw_polyline(path, Color("b49a6c"), 30.0, true)
	for i in range(220):
		var p := Vector2(rng.randf_range(10.0, world_rect.size.x - 10.0), rng.randf_range(10.0, world_rect.size.y - 10.0))
		if Geo.distance_to_polyline(p, path_points) > 24.0:
			continue
		var stone := Color("8a7a60") if rng.randf() < 0.5 else Color("c4b48c")
		draw_rect(Rect2(floorf(p.x), floorf(p.y), 2.0, 1.0), stone)
	draw_colored_polygon(Geo.ellipse_points(pond_center, pond_radii + Vector2(9.0, 7.0)), Color("3b5a3a"))
	draw_colored_polygon(Geo.ellipse_points(pond_center, pond_radii + Vector2(4.0, 3.0)), Color("8c7a55"))
	draw_colored_polygon(Geo.ellipse_points(pond_center, pond_radii), Color("2f7c96"))
	draw_colored_polygon(Geo.ellipse_points(pond_center + Vector2(-10.0, -6.0), pond_radii * 0.62), Color("48a0bb"))
	draw_line(pond_center + Vector2(-34.0, -16.0), pond_center + Vector2(-10.0, -16.0), Color("c4eaf5"), 1.0)
	draw_line(pond_center + Vector2(16.0, 10.0), pond_center + Vector2(42.0, 10.0), Color("c4eaf5"), 1.0)
	draw_colored_polygon(Geo.ellipse_points(pond_center + Vector2(30.0, -12.0), Vector2(8.0, 4.0), 12), Color("5fae4e"))
	draw_colored_polygon(Geo.ellipse_points(pond_center + Vector2(-40.0, 14.0), Vector2(7.0, 3.0), 12), Color("4f9a45"))
	for i in range(1700):
		var p := Vector2(rng.randf_range(10.0, world_rect.size.x - 10.0), rng.randf_range(10.0, world_rect.size.y - 10.0))
		if Geo.distance_to_polyline(p, path_points) < 34.0:
			continue
		if (p - pond_center).length() < 112.0:
			continue
		var blade := Color("7db85a") if rng.randf() < 0.5 else Color("386a30")
		draw_line(p, p + Vector2(rng.randf_range(-2.0, 2.0), -rng.randf_range(3.0, 6.0)), blade, 1.0)
