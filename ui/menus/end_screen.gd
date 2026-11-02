class_name EndScreen
extends CanvasLayer
## Pantallas de victoria y derrota.

signal restart_requested
signal checkpoint_requested
signal menu_requested
signal continue_requested

var _box: VBoxContainer

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	root.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	root.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.BG, MenuStyle.BORDER, 2, 28.0))
	center.add_child(panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 10)
	_box.custom_minimum_size = Vector2(440.0, 0.0)
	panel.add_child(_box)

func show_defeat() -> void:
	_clear()
	Sound.stop_music()
	Sound.stop_all_loops()
	Sound.play("defeat")
	_box.add_child(MenuStyle.label("HAS CAÍDO", 38, Color("e0735a")))
	_wrapped("El humo y el calor fueron demasiado. Aléjate de las llamas y usa el agua con prudencia.")
	var first := MenuStyle.add_button(_box, "Reiniciar", _on_restart)
	var checkpoint := MenuStyle.add_button(_box, "Último punto de control", _on_checkpoint)
	checkpoint.disabled = not SaveSystem.has_save()
	MenuStyle.add_button(_box, "Menú principal", _on_menu)
	_present(first)

func show_victory(summary: Dictionary) -> void:
	_clear()
	Sound.stop_music()
	Sound.play("victory")
	_box.add_child(MenuStyle.label("¡MISIÓN COMPLETADA!", 34, Color("a8d98f")))
	_wrapped("Frontera está a salvo por ahora. Ante un incendio real, aléjate y llama a emergencias.")
	var ending_text := str(summary.get("ending_text", ""))
	if ending_text != "":
		_wrapped(ending_text)
	var seconds := int(float(summary.get("time", 0.0)))
	var lines: Array[String] = [
		"Focos apagados: %d" % int(summary.get("fires_out", 0)),
		"Brotes plantados: %d" % int(summary.get("sprouts", 0)),
		"Agua utilizada: %d" % int(summary.get("water_used", 0)),
		"Semillas recogidas: %d" % int(summary.get("seeds", 0)),
		"Animales rescatados: %d" % int(summary.get("rescued", 0)),
		"Puntos de progreso: %d" % int(summary.get("xp", 0)),
		"Tiempo: %d:%02d" % [floori(float(seconds) / 60.0), seconds % 60],
	]
	for line in lines:
		_box.add_child(MenuStyle.label(line, 17))
	var first := MenuStyle.add_button(_box, "Seguir explorando", _on_continue)
	MenuStyle.add_button(_box, "Menú principal", _on_menu)
	_present(first)

func _wrapped(text: String) -> void:
	var item := MenuStyle.label(text, 15, Color(0.8, 0.78, 0.66, 1.0))
	item.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item.custom_minimum_size = Vector2(430.0, 0.0)
	_box.add_child(item)

func _clear() -> void:
	for child in _box.get_children():
		child.queue_free()

func _present(first: Button) -> void:
	visible = true
	get_tree().paused = true
	first.grab_focus()

func _on_restart() -> void:
	restart_requested.emit()

func _on_checkpoint() -> void:
	checkpoint_requested.emit()

func _on_menu() -> void:
	menu_requested.emit()

func _on_continue() -> void:
	visible = false
	get_tree().paused = false
	continue_requested.emit()
