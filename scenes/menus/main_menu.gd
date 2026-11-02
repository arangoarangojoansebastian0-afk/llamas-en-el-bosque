extends Control
## Menú principal: Jugar, Continuar, Controles, Configuración, Créditos y Salir.

var _continue_button: Button
var _first_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = false
	Sound.stop_all_loops()
	Sound.play_music("calm")
	var backdrop := MenuBackdrop.new()
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_top", 40)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	margin.add_child(column)
	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 14)
	title_row.add_child(_title("LLAMAS", 46, Color("f2a65a")))
	title_row.add_child(_title("EN EL BOSQUE", 46, Color("e8dfc2")))
	column.add_child(title_row)
	column.add_child(MenuStyle.label("Aventura de exploración y prevención de incendios forestales", 14, Color("c8bf91")))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 14.0)
	column.add_child(spacer)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 8)
	buttons.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	column.add_child(buttons)
	_first_button = MenuStyle.add_button(buttons, "Jugar", _on_play)
	_continue_button = MenuStyle.add_button(buttons, "Continuar", _on_continue)
	_continue_button.disabled = not SaveSystem.has_save()
	MenuStyle.add_button(buttons, "Controles", _on_controls)
	MenuStyle.add_button(buttons, "Configuración", _on_settings)
	MenuStyle.add_button(buttons, "Créditos", _on_credits)
	MenuStyle.add_button(buttons, "Salir", _on_quit)
	column.add_child(MenuStyle.label("Beta · noviembre de 2026", 12, Color(0.7, 0.7, 0.6, 0.8)))
	_first_button.grab_focus()

func _title(text: String, font_size: int, color: Color) -> Label:
	var item := MenuStyle.label(text, font_size, color)
	item.add_theme_constant_override("outline_size", 8)
	item.add_theme_color_override("font_outline_color", Color(0.05, 0.03, 0.03, 1.0))
	return item

func _on_play() -> void:
	SaveSystem.pending_load = false
	Transition.go_to(Transition.FRONTERA_SCENE)

func _on_continue() -> void:
	SaveSystem.pending_load = true
	Transition.go_to(Transition.FRONTERA_SCENE)

func _on_controls() -> void:
	_open(ControlsPanel.new())

func _on_settings() -> void:
	_open(SettingsPanel.new())

func _on_credits() -> void:
	_open(CreditsPanel.new())

func _on_quit() -> void:
	get_tree().quit()

func _open(panel: OverlayPanel) -> void:
	add_child(panel)
	panel.closed.connect(_on_panel_closed)

func _on_panel_closed() -> void:
	_first_button.grab_focus()
