class_name Pickup
extends Node2D
## Objeto recogible o fuente de recurso (agua, semillas...). Se usa con E.
## Los objetos de un solo uso desaparecen al recogerse.

@export var resource_id := "water"
@export var amount := 1
@export var one_shot := true
@export var label := "Agua"
@export var prompt_text := ""

var _taken := false

func _ready() -> void:
	add_to_group("interactable")

func is_taken() -> bool:
	return _taken

func get_prompt() -> String:
	if prompt_text != "":
		return prompt_text
	return "E · Recoger %s" % label

func interact(_player: Node) -> void:
	if _taken:
		return
	var added := GameState.add_resource(resource_id, amount)
	if added <= 0:
		GameState.post_message("Ya llevas todo lo que puedes de este recurso.")
		return
	GameState.post_message("+%d %s" % [added, label])
	Sound.play("refill" if resource_id == "water" else "pickup", -2.0)
	if resource_id == "seed":
		GameState.add_stat("seeds", added)
	if one_shot:
		mark_taken()

## Retira el objeto del mundo (también se usa al cargar una partida).
func mark_taken() -> void:
	_taken = true
	remove_from_group("interactable")
	set_process(false)
	hide()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(10.0, 4.0)), Color(0.0, 0.0, 0.0, 0.3))
	match resource_id:
		"water":
			draw_rect(Rect2(-7.0, -12.0, 14.0, 12.0), Color("7a5232"))
			draw_rect(Rect2(-7.0, -12.0, 14.0, 3.0), Color("4e9ac4"))
			draw_rect(Rect2(-7.0, -6.0, 14.0, 1.0), Color("4a3220"))
			draw_rect(Rect2(-7.0, -12.0, 2.0, 12.0), Color("8f6540"))
		"seed":
			draw_rect(Rect2(-5.0, -9.0, 10.0, 9.0), Color("a37a4c"))
			draw_rect(Rect2(-3.0, -12.0, 6.0, 3.0), Color("c29a62"))
			draw_rect(Rect2(-1.0, -17.0, 2.0, 5.0), Color("5fae4e"))
			draw_rect(Rect2(1.0, -17.0, 4.0, 2.0), Color("7ccf5f"))
		_:
			draw_rect(Rect2(-6.0, -10.0, 12.0, 10.0), Color("c8b27a"))
	var bob := sin(t * 3.0) * 2.0
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -24.0 + bob), Vector2(3.0, -27.0 + bob),
		Vector2(0.0, -30.0 + bob), Vector2(-3.0, -27.0 + bob)]), Color("ffe08a"))
