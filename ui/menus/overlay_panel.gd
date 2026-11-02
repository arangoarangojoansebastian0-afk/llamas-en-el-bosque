class_name OverlayPanel
extends Control
## Base de paneles modales (controles, ajustes, créditos). Se cierra con "Volver" o ESC.

signal closed

var title_text := ""
var close_action := ""
var content: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.BG, MenuStyle.BORDER, 2, 26.0))
	center.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.custom_minimum_size = Vector2(520.0, 0.0)
	panel.add_child(content)
	content.add_child(MenuStyle.label(title_text, 30, MenuStyle.ACCENT))
	_build(content)
	var back := MenuStyle.add_button(content, "Volver", close)
	back.grab_focus()

func _build(_box: VBoxContainer) -> void:
	pass

func close() -> void:
	closed.emit()
	queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or (close_action != "" and event.is_action_pressed(close_action)):
		get_viewport().set_input_as_handled()
		close()
