class_name Clue
extends Node2D
## Indicio examinable (causa de incendio). Se resalta con la habilidad de observación.

signal examined(clue: Clue)

@export var clue_id := ""
@export var kind := "campfire"   # campfire, cigarette, dry_grass
@export var title := "indicio"
@export_multiline var text := ""

var _done := false
var _reveal := 0.0

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("observable")

func is_examined() -> bool:
	return _done

func get_prompt() -> String:
	return "E · Examinar %s" % title

func reveal(duration: float) -> void:
	_reveal = duration

func interact(_player: Node) -> void:
	if _done:
		return
	mark_examined()
	Dialogue.start([Dialogue.say("Observación · " + title, text)])
	examined.emit(self)

func mark_examined() -> void:
	_done = true
	remove_from_group("interactable")
	queue_redraw()

func _process(delta: float) -> void:
	if _reveal > 0.0:
		_reveal = maxf(0.0, _reveal - delta)
		queue_redraw()

func _draw() -> void:
	draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(11.0, 4.0)), Color(0.0, 0.0, 0.0, 0.2))
	match kind:
		"campfire":
			for i in range(7):
				var angle := TAU * float(i) / 7.0
				var stone := Vector2(cos(angle) * 9.0, sin(angle) * 4.0 - 2.0)
				draw_rect(Rect2(stone.x - 2.0, stone.y - 2.0, 4.0, 3.0), Color("7a7a74"))
			draw_rect(Rect2(-6.0, -5.0, 12.0, 3.0), Color("2a2623"))
			draw_rect(Rect2(-4.0, -7.0, 8.0, 3.0), Color("3b3633"))
			draw_rect(Rect2(-1.0, -5.0, 2.0, 1.0), Color("ff7a30"))
			draw_line(Vector2(0.0, -8.0), Vector2(1.0, -16.0), Color(0.6, 0.6, 0.6, 0.35), 1.0)
		"cigarette":
			draw_rect(Rect2(-4.0, -2.0, 7.0, 2.0), Color("f2efe4"))
			draw_rect(Rect2(3.0, -2.0, 2.0, 2.0), Color("e0732f"))
		_:
			for i in range(7):
				var x := float(i) * 3.0 - 9.0
				var h := 8.0 + float((i * 5) % 6)
				draw_line(Vector2(x, 0.0), Vector2(x + 1.0, -h), Color("d6bf5a") if i % 2 == 0 else Color("b8a345"), 2.0)
	if _reveal > 0.0 and not _done:
		var pulse := 1.0 + 0.2 * sin(float(Time.get_ticks_msec()) / 150.0)
		draw_arc(Vector2(0.0, -6.0), 16.0 * pulse, 0.0, TAU, 32, Color(1.0, 0.9, 0.4, minf(1.0, _reveal)), 2.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(0.0, -28.0), Vector2(4.0, -32.0), Vector2(0.0, -36.0), Vector2(-4.0, -32.0)]), Color("ffe08a"))
