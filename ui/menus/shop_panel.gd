class_name ShopPanel
extends CanvasLayer
## Panel de la tienda. Muestra el inventario de la tienda y permite comprar y vender.

signal closed

@export var shop_name := "Tienda"
@export var stock: Array[String] = []

var _panel: PanelContainer
var _selected_id := ""
var _selected_idx := 0
var _buttons: Array[Button] = []

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()

func _build_ui() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 120)
	margin.add_theme_constant_override("margin_right", 120)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_theme_constant_override("margin_bottom", 60)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(margin)

	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.BG, MenuStyle.BORDER, 2, 16.0))
	margin.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(vbox)

	# Header
	var title_label := MenuStyle.label(shop_name.to_upper(), 22, MenuStyle.ACCENT)
	vbox.add_child(title_label)

	var coins_label := MenuStyle.label("Monedas: %d" % GameState.coins, 16, Color("f0c830"))
	vbox.add_child(coins_label)
	GameState.coins_changed.connect(func(c): coins_label.text = "Monedas: %d" % c)

	var separator := HSeparator.new()
	vbox.add_child(separator)

	# Scroll de items
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0.0, 320.0)
	vbox.add_child(scroll)

	var items_vbox := VBoxContainer.new()
	items_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(items_vbox)

	for item_id in stock:
		var data := ItemDatabase.get_item(item_id)
		if data.is_empty():
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		items_vbox.add_child(row)

		# Icono del item (dibujado)
		var icon_rect := ItemIconRect.new()
		icon_rect.item_id = item_id
		icon_rect.custom_minimum_size = Vector2(40.0, 40.0)
		row.add_child(icon_rect)

		# Info
		var info_vbox := VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info_vbox)

		var name_label := MenuStyle.label(str(data.get("name", item_id)), 15, MenuStyle.TEXT)
		info_vbox.add_child(name_label)

		var desc_label := MenuStyle.label(str(data.get("desc", "")), 12, Color(0.7, 0.7, 0.6))
		info_vbox.add_child(desc_label)

		# Precio y boton
		var price_row := HBoxContainer.new()
		row.add_child(price_row)

		var price := int(data.get("price", 0))
		var price_label := MenuStyle.label("%d monedas" % price, 14, Color("f0c830"))
		price_row.add_child(price_label)

		var buy_btn := MenuStyle.button("Comprar")
		buy_btn.custom_minimum_size = Vector2(100.0, 36.0)
		var captured_id := item_id
		buy_btn.pressed.connect(func(): _buy(captured_id))
		_buttons.append(buy_btn)
		price_row.add_child(buy_btn)

	# Footer
	var close_btn := MenuStyle.button("Cerrar tienda")
	close_btn.custom_minimum_size = Vector2(200.0, 44.0)
	close_btn.pressed.connect(_close)
	vbox.add_child(close_btn)

func _buy(item_id: String) -> void:
	var data := ItemDatabase.get_item(item_id)
	if data.is_empty():
		return
	var price := int(data.get("price", 0))
	if not GameState.spend_coins(price):
		GameState.post_message("No tienes suficientes monedas. Necesitas %d." % price)
		return
	var category := str(data.get("category", ""))
	if category == "tool":
		GameState.add_tool(item_id)
	else:
		var res_id := str(data.get("resource_id", ""))
		var amount := int(data.get("amount", 1))
		if res_id != "":
			GameState.add_resource(res_id, amount)
	Sound.play("pickup", -2.0)
	GameState.post_message("Comprado: %s" % ItemDatabase.get_name(item_id))

func _close() -> void:
	Sound.play_click()
	queue_free()
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_close()


# Icono visual de item dibujado proceduralente
class ItemIconRect extends Control:
	var item_id := ""

	func _draw() -> void:
		var r := Rect2(0.0, 4.0, 36.0, 32.0)
		match item_id:
			"extinguisher":
				draw_rect(Rect2(10.0, 2.0, 16.0, 30.0), Color("d03030"))
				draw_rect(Rect2(14.0, 0.0, 8.0, 6.0), Color("a02020"))
				draw_rect(Rect2(14.0, 0.0, 8.0, 2.0), Color("c0c0c0"))
				draw_line(Vector2(18.0, 0.0), Vector2(18.0, -8.0), Color("808080"), 2.0)
				draw_line(Vector2(18.0, -8.0), Vector2(28.0, -8.0), Color("808080"), 2.0)
				draw_rect(Rect2(12.0, 14.0, 12.0, 4.0), Color("ffffff"))
			"medkit":
				draw_rect(r, Color("e03030"))
				draw_rect(Rect2(14.0, 8.0, 8.0, 20.0), Color("ffffff"))
				draw_rect(Rect2(8.0, 14.0, 20.0, 8.0), Color("ffffff"))
			"lantern":
				draw_colored_polygon(Geo.ellipse_points(Vector2(18.0, 16.0), Vector2(14.0, 18.0)), Color("f0c830"))
				draw_rect(Rect2(14.0, 2.0, 8.0, 8.0), Color("808040"))
				draw_line(Vector2(18.0, 0.0), Vector2(18.0, 2.0), Color("808080"), 2.0)
			"radio_pro", "radio":
				draw_rect(Rect2(6.0, 6.0, 24.0, 26.0), Color("a88a50"))
				draw_rect(Rect2(10.0, 10.0, 16.0, 12.0), Color("384b3a"))
				draw_line(Vector2(24.0, 6.0), Vector2(32.0, -4.0), Color("d6c080"), 2.0)
				draw_circle(Vector2(32.0, -4.0), 2.0, Color("df7550"))
			"fire_suit":
				draw_rect(Rect2(4.0, 4.0, 28.0, 28.0), Color("e0a830"))
				draw_rect(Rect2(4.0, 4.0, 4.0, 28.0), Color("f0c040"))
				draw_colored_polygon(Geo.ellipse_points(Vector2(18.0, 10.0), Vector2(12.0, 8.0)), Color("e8d880"))
			"axe":
				draw_line(Vector2(10.0, 30.0), Vector2(28.0, 4.0), Color("7a5232"), 4.0)
				draw_colored_polygon(PackedVector2Array([
					Vector2(24.0, 2.0), Vector2(34.0, 8.0), Vector2(30.0, 20.0), Vector2(22.0, 14.0)]), Color("8a8888"))
				draw_colored_polygon(PackedVector2Array([
					Vector2(24.0, 2.0), Vector2(30.0, 0.0), Vector2(34.0, 8.0)]), Color("a0a8a8"))
			"shovel":
				draw_line(Vector2(18.0, 2.0), Vector2(18.0, 26.0), Color("7a5232"), 4.0)
				draw_colored_polygon(PackedVector2Array([
					Vector2(8.0, 22.0), Vector2(28.0, 22.0), Vector2(24.0, 38.0), Vector2(12.0, 38.0)]), Color("8a8888"))
			"backpack":
				draw_rect(Rect2(4.0, 6.0, 28.0, 26.0), Color("8a5a36"))
				draw_rect(Rect2(4.0, 6.0, 28.0, 4.0), Color("a87a50"))
				draw_rect(Rect2(14.0, 2.0, 8.0, 8.0), Color("7a4a2a"))
			"water":
				draw_rect(Rect2(6.0, 6.0, 24.0, 24.0), Color("7a5232"))
				draw_rect(Rect2(6.0, 6.0, 24.0, 6.0), Color("4e9ac4"))
			"seed":
				draw_rect(Rect2(10.0, 12.0, 16.0, 14.0), Color("a37a4c"))
				draw_rect(Rect2(14.0, 8.0, 8.0, 5.0), Color("c29a62"))
				draw_rect(Rect2(17.0, 2.0, 2.0, 7.0), Color("5fae4e"))
				draw_rect(Rect2(19.0, 3.0, 5.0, 2.0), Color("7ccf5f"))
			"box":
				draw_rect(Rect2(4.0, 8.0, 28.0, 24.0), Color("c8a060"))
				draw_rect(Rect2(4.0, 8.0, 28.0, 4.0), Color("a07840"))
				draw_line(Vector2(18.0, 8.0), Vector2(18.0, 32.0), Color("80603a"), 1.5)
				draw_line(Vector2(4.0, 18.0), Vector2(32.0, 18.0), Color("80603a"), 1.5)
			_:
				draw_rect(Rect2(4.0, 4.0, 28.0, 28.0), Color("888888"))
