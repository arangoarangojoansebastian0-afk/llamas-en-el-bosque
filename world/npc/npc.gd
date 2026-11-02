class_name Npc
extends Node2D
## Personaje no jugable. Se interactúa con E; la historia decide qué dice (ver FronteraStory).
## Origen = pies. Roles: ranger, firefighter, researcher, villager.

signal talked(npc: Npc)

@export var npc_id := ""
@export var display_name := "Elena"
@export var role := "ranger"
@export var facing_left := false
var has_news := false
var _phase := 0.0

func _ready() -> void:
	add_to_group("interactable")
	_phase = randf() * TAU

func get_prompt() -> String:
	return "E · Hablar con %s" % display_name

func interact(player: Node) -> void:
	var body := player as Node2D
	if body != null:
		facing_left = body.global_position.x < global_position.x
	talked.emit(self)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var dir := -1.0 if facing_left else 1.0
	var t := float(Time.get_ticks_msec()) / 1000.0
	var bob := sin(t * 2.2 + _phase)
	var skin := Color("e0b088")
	var coat := Color("3f6b3d")
	var pants := Color("5b4630")
	match role:
		"firefighter":
			coat = Color("e0b43a")
			pants = Color("2f3a4a")
		"researcher":
			coat = Color("e8e6df")
			pants = Color("3b4a5c")
		"villager":
			coat = Color("4a6fa5")
			pants = Color("6a5a44")
	draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(10.0, 4.0)), Color(0.0, 0.0, 0.0, 0.3))
	draw_rect(Rect2(-5.0, -9.0, 4.0, 9.0), pants)
	draw_rect(Rect2(1.0, -9.0, 4.0, 9.0), pants.darkened(0.15))
	draw_rect(Rect2(-5.0, -3.0, 4.0, 3.0), Color("2a2420"))
	draw_rect(Rect2(1.0, -3.0, 4.0, 3.0), Color("2a2420"))
	var coat_bottom := -4.0 if role == "researcher" else -8.0
	draw_rect(Rect2(-7.0, -21.0, 14.0, coat_bottom + 21.0), coat)
	draw_rect(Geo.flip_rect(3.0, -21.0, 4.0, coat_bottom + 21.0, dir), coat.darkened(0.2))
	draw_rect(Rect2(-7.0, -21.0, 14.0, 2.0), coat.lightened(0.15))
	draw_rect(Rect2(-10.0, -20.0 + bob * 0.4, 3.0, 10.0), coat.darkened(0.08))
	draw_rect(Rect2(7.0, -20.0 - bob * 0.4, 3.0, 10.0), coat.darkened(0.25))
	draw_rect(Rect2(-10.0, -10.0 + bob * 0.4, 3.0, 3.0), skin)
	draw_rect(Rect2(7.0, -10.0 - bob * 0.4, 3.0, 3.0), skin.darkened(0.15))
	draw_rect(Rect2(-5.0, -30.0, 10.0, 9.0), skin)
	draw_rect(Geo.flip_rect(-3.0 + 1.5, -27.0, 2.0, 2.0, dir), Color("36291f"))
	draw_rect(Geo.flip_rect(1.0 + 1.5, -27.0, 2.0, 2.0, dir), Color("36291f"))
	match role:
		"ranger":
			draw_rect(Rect2(-9.0, -32.0, 18.0, 3.0), Color("5e6b35"))
			draw_rect(Rect2(-5.0, -38.0, 10.0, 6.0), Color("6f7f3d"))
			draw_rect(Rect2(-5.0, -33.0, 10.0, 1.0), Color("3a4220"))
			draw_rect(Geo.flip_rect(2.0, -18.0, 3.0, 3.0, dir), Color("e8c24a"))
			draw_rect(Rect2(-5.0, -22.0, 10.0, 2.0), Color("c4503a"))
		"firefighter":
			draw_rect(Rect2(-8.0, -32.0, 16.0, 3.0), Color("a63d2a"))
			draw_rect(Rect2(-6.0, -37.0, 12.0, 6.0), Color("c4503a"))
			draw_rect(Rect2(-2.0, -36.0, 4.0, 3.0), Color("f2d36b"))
			draw_rect(Rect2(-7.0, -14.0, 14.0, 2.0), Color("e8e8d8"))
			draw_rect(Rect2(-7.0, -18.0, 14.0, 1.0), Color("e8e8d8"))
		"researcher":
			draw_rect(Rect2(-6.0, -33.0, 12.0, 5.0), Color("3a2a22"))
			draw_rect(Geo.flip_rect(-9.0, -31.0, 4.0, 8.0, dir), Color("3a2a22"))
			draw_rect(Rect2(-4.0, -28.0, 3.0, 2.0), Color("bfe8f0"))
			draw_rect(Rect2(1.0, -28.0, 3.0, 2.0), Color("bfe8f0"))
			draw_rect(Geo.flip_rect(8.0, -16.0, 5.0, 7.0, dir), Color("b88a4a"))
			draw_rect(Geo.flip_rect(9.0, -15.0, 3.0, 1.0, dir), Color("f4f1de"))
		_:
			draw_rect(Rect2(-10.0, -32.0, 20.0, 2.0), Color("d9c37a"))
			draw_rect(Rect2(-5.0, -36.0, 10.0, 5.0), Color("e0cd8a"))
			draw_rect(Rect2(-5.0, -33.0, 10.0, 1.0), Color("a8483a"))
	if has_news:
		var float_y := -52.0 + bob * 1.5
		draw_rect(Rect2(-3.0, float_y - 1.0, 6.0, 11.0), Color("3a2a10"))
		draw_rect(Rect2(-2.0, float_y, 4.0, 6.0), Color("ffd24a"))
		draw_rect(Rect2(-2.0, float_y + 7.0, 4.0, 2.0), Color("ffd24a"))
