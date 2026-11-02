class_name Repairable
extends StaticBody2D
## Estructura dañada que puede repararse con el Kit de Reparación.
## Origen = base del objeto. Registra la reparación en WorldManager.

signal repaired

@export var repaired := false
@export var structure_name := "Estructura"
@export var wood_cost := 0
@export var seed_cost := 0

var _interact_range := 64.0

func _ready() -> void:
	add_to_group("repairable")
	add_to_group("interactable")
	collision_layer = 1
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24.0, 16.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -8.0)
	add_child(shape)

func get_prompt() -> String:
	if repaired:
		return ""
	var cost := ""
	if wood_cost > 0:
		cost += " (Madera: %d)" % wood_cost
	if seed_cost > 0:
		cost += " (Semillas: %d)" % seed_cost
	return "E · Reparar %s (Kit)%s" % [structure_name, cost]

func interact(_player: Node) -> void:
	if repaired:
		return
	repair(_player)

func repair(_player: Node) -> void:
	if repaired:
		return
	# Comprobar costes de recursos
	if wood_cost > 0 and not GameState.spend_resource("wood", wood_cost):
		GameState.post_message("No hay suficiente madera para reparar %s." % structure_name)
		return
	if seed_cost > 0 and not GameState.spend_resource("seed", seed_cost):
		GameState.post_message("No hay suficientes semillas para reparar %s." % structure_name)
		return
	if not GameState.use_tool("kit_reparacion"):
		GameState.post_message("Kit de reparación sin usos.")
		return
	repaired = true
	remove_from_group("repairable")
	remove_from_group("interactable")
	Sound.play("plant", -3.0)
	GameState.add_stat("structures_repaired")
	GameState.post_message("¡%s reparado!" % structure_name)
	WorldManager.register_repair(global_position)
	repaired.emit()
	queue_redraw()

func _draw() -> void:
	var cx := 0.0
	var cy := -12.0
	if repaired:
		# Estructura reparada: madera clara con cruz blanca
		draw_rect(Rect2(-12.0 * 1.0, cy - 14.0, 24.0 * 1.0, 14.0 * 1.0), Color("8b7355"))
		draw_rect(Rect2(-12.0 * 1.0, cy - 14.0, 24.0 * 1.0, 3.0 * 1.0), Color("a89070"))
		draw_rect(Rect2(-2.0 * 1.0, cy - 16.0, 4.0 * 1.0, 18.0 * 1.0), Color("f4f1de"))
		draw_rect(Rect2(-14.0 * 1.0, cy - 6.0, 28.0 * 1.0, 4.0 * 1.0), Color("f4f1de"))
	else:
		# Estructura dañada: madera oscura y rotura
		draw_rect(Rect2(-12.0 * 1.0, cy - 14.0, 24.0 * 1.0, 14.0 * 1.0), Color("4a3f35"))
		draw_rect(Rect2(-12.0 * 1.0, cy - 14.0, 24.0 * 1.0, 3.0 * 1.0), Color("2a2623"))
		draw_rect(Rect2(-10.0 * 1.0, cy - 10.0, 6.0 * 1.0, 2.0 * 1.0), Color("2a2623"))
		draw_rect(Rect2(-10.0 * 1.0, cy - 4.0, 4.0 * 1.0, 2.0 * 1.0), Color("2a2623"))
		# Línea de rotura (roja)
		draw_rect(Rect2(-1.0 * 1.0, cy - 16.0, 2.0 * 1.0, 18.0 * 1.0), Color("c4503a"))
		draw_rect(Rect2(-14.0 * 1.0, cy - 6.0, 28.0 * 1.0, 2.0 * 1.0), Color("c4503a"))