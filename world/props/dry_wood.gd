class_name DryWood
extends Prop
## Árbol seco cortable con el hacha. Origen = base del objeto.
## Al ser cortado entrega madera y registra un cortafuego en WorldManager.

signal chopped

@export var chopped := false
@export var wood_amount := 1

func _ready() -> void:
	super._ready()
	if not chopped:
		add_to_group("dry_wood")
		add_to_group("interactable")
	collision_layer = 1
	collision_mask = 1

func get_prompt() -> String:
	if chopped:
		return ""
	return "E · Cortar árbol seco (Hacha)"

func interact(_player: Node) -> void:
	if chopped:
		return
	chop(_player)

func chop(_player: Node) -> void:
	if chopped:
		return
	chopped = true
	remove_from_group("dry_wood")
	remove_from_group("interactable")
	Sound.play("plant", -4.0)
	chopped.emit()
	queue_redraw()

func _draw() -> void:
	var s := scale_factor
	if chopped:
		# Tocón cortado
		draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(14.0 * s, 4.0 * s)), Color("3b3633"))
		draw_rect(Rect2(-3.0 * s, -8.0 * s, 6.0 * s, 8.0 * s), Color("2a2623"))
		draw_rect(Rect2(-3.0 * s, -8.0 * s, 2.0 * s, 8.0 * s), Color("3d3733"))
		# Anillos del tronco
		draw_colored_polygon(Geo.ellipse_points(Vector2(0.0, -2.0 * s), Vector2(10.0 * s, 3.0 * s)), Color("4a423a"))
		draw_colored_polygon(Geo.ellipse_points(Vector2(0.0, -1.0 * s), Vector2(9.0 * s, 2.5 * s)), Color("5a5048"))
	else:
		super._draw()
		# Indicador visual de árbol seco (raya blanca en el tronco)
		draw_line(Vector2(-1.0 * s, -48.0 * s), Vector2(-1.0 * s, -16.0 * s), Color("f4f1de"), 1.0)