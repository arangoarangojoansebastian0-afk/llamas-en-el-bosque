class_name Shop
extends Node2D
## Tienda interactiva. Se coloca en el mundo como objeto interactuable.
## Abre un panel de compra/venta al pulsar E.

signal shop_closed

@export var shop_id := "tienda_pinar"
@export var shop_name := "Tienda El Pinar"
@export var stock: Array[String] = ["extinguisher", "medkit", "lantern", "water", "seed", "shovel", "axe"]

var _open := false
var _panel: ShopPanel = null
var _phase := 0.0

func _ready() -> void:
	add_to_group("interactable")
	_phase = randf() * TAU

func get_prompt() -> String:
	return "E - Tienda: %s" % shop_name

func interact(_player: Node) -> void:
	if _open:
		return
	_open = true
	_panel = ShopPanel.new()
	_panel.shop_name = shop_name
	_panel.stock = stock
	_panel.closed.connect(_on_panel_closed)
	get_tree().get_root().add_child(_panel)
	get_tree().paused = true

func _on_panel_closed() -> void:
	_open = false
	get_tree().paused = false
	shop_closed.emit()

func _process(_delta: float) -> void:
	_phase += _delta * 2.0
	queue_redraw()

func _draw() -> void:
	var s := 1.0
	# Sombra
	draw_colored_polygon(Geo.ellipse_points(Vector2(4.0, 4.0), Vector2(28.0, 10.0)), Color(0.0, 0.0, 0.0, 0.3))
	# Estructura: base de madera
	draw_rect(Rect2(-22.0, -40.0, 44.0, 40.0), Color("7a5636"))
	draw_rect(Rect2(-22.0, -40.0, 3.0, 40.0), Color("9a7050"))
	# Tejado triangular
	draw_colored_polygon(PackedVector2Array([
		Vector2(-28.0, -40.0), Vector2(28.0, -40.0), Vector2(0.0, -60.0)]), Color("8a3a2a"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-28.0, -40.0), Vector2(-4.0, -40.0), Vector2(0.0, -60.0)]), Color("a04a38"))
	# Puerta
	draw_rect(Rect2(-7.0, -22.0, 14.0, 22.0), Color("4a2e18"))
	draw_rect(Rect2(-5.0, -20.0, 5.0, 20.0), Color("5c3a22"))
	draw_circle(Vector2(5.0, -11.0), 2.0, Color("d4a030"))
	# Ventana
	draw_rect(Rect2(-18.0, -34.0, 10.0, 8.0), Color("7ac8d8"))
	draw_rect(Rect2(-18.0, -30.0, 10.0, 1.0), Color("5a9aaa"))
	draw_rect(Rect2(-13.0, -34.0, 1.0, 8.0), Color("5a9aaa"))
	# Letrero
	draw_rect(Rect2(-18.0, -52.0, 36.0, 10.0), Color("d4a030"))
	draw_string(ThemeDB.fallback_font, Vector2(-16.0, -44.0), "TIENDA", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("3a2010"))
	# Icono moneda flotante
	var bob := sin(_phase) * 2.0
	draw_circle(Vector2(0.0, -70.0 + bob), 7.0, Color("f0c830"))
	draw_string(ThemeDB.fallback_font, Vector2(-4.0, -66.0 + bob), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("3a2010"))
