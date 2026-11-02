class_name PauseMenu
extends CanvasLayer
## Menú de pausa: Continuar, Reiniciar, Controles, Configuración y Volver al menú.

signal restart_requested
signal menu_requested

var _first_button: Button

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.BG, MenuStyle.BORDER, 2, 26.0))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	column.add_child(MenuStyle.label("PAUSA", 36, MenuStyle.ACCENT))
	_first_button = MenuStyle.add_button(column, "Continuar", resume)
	MenuStyle.add_button(column, "Reiniciar", _on_restart)
	MenuStyle.add_button(column, "Controles", _on_controls)
	MenuStyle.add_button(column, "Configuración", _on_settings)
	MenuStyle.add_button(column, "Volver al menú principal", _on_menu)

func toggle() -> void:
	if visible:
		resume()
	else:
		visible = true
		get_tree().paused = true
		_first_button.grab_focus()

func resume() -> void:
	visible = false
	get_tree().paused = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		resume()

func _on_restart() -> void:
	restart_requested.emit()

func _on_menu() -> void:
	menu_requested.emit()

func _on_controls() -> void:
	_open(ControlsPanel.new())

func _on_settings() -> void:
	_open(SettingsPanel.new())

func _open(panel: OverlayPanel) -> void:
	add_child(panel)
	panel.closed.connect(_on_panel_closed)

func _on_panel_closed() -> void:
	_first_button.grab_focus()
