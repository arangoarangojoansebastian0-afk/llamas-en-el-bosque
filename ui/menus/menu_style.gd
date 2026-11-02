class_name MenuStyle
extends RefCounted
## Estilo visual compartido por todos los menús (colores, botones, etiquetas, paneles).

const BG := Color(0.05, 0.09, 0.07, 0.94)
const BORDER := Color(0.59, 0.53, 0.37, 1.0)
const TEXT := Color(0.93, 0.89, 0.79, 1.0)
const ACCENT := Color(1.0, 0.87, 0.6, 1.0)

static func box(fill: Color, border: Color, border_width: int = 2, margin: float = 12.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(margin)
	return style

static func label(text: String, font_size: int, color: Color = TEXT) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	return item

static func button(text: String) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size = Vector2(300.0, 42.0)
	item.add_theme_font_size_override("font_size", 18)
	item.add_theme_color_override("font_color", TEXT)
	item.add_theme_color_override("font_hover_color", ACCENT)
	item.add_theme_color_override("font_focus_color", ACCENT)
	item.add_theme_color_override("font_pressed_color", ACCENT)
	item.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.45, 1.0))
	item.add_theme_stylebox_override("normal", box(Color(0.1, 0.16, 0.12, 0.95), BORDER, 2, 8.0))
	item.add_theme_stylebox_override("hover", box(Color(0.2, 0.3, 0.2, 0.98), ACCENT, 2, 8.0))
	item.add_theme_stylebox_override("pressed", box(Color(0.27, 0.38, 0.22, 1.0), ACCENT, 2, 8.0))
	item.add_theme_stylebox_override("disabled", box(Color(0.08, 0.1, 0.09, 0.8), Color(0.3, 0.3, 0.26, 1.0), 1, 8.0))
	item.add_theme_stylebox_override("focus", box(Color(0.2, 0.3, 0.2, 0.98), ACCENT, 2, 8.0))
	item.pressed.connect(Sound.play_click)
	return item

static func add_button(parent: Control, text: String, callback: Callable) -> Button:
	var item := button(text)
	item.pressed.connect(callback)
	parent.add_child(item)
	return item
