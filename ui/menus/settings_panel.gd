class_name SettingsPanel
extends OverlayPanel
## Configuración: volúmenes (general, música, efectos) y pantalla completa.

func _init() -> void:
	title_text = "Configuración"

func _build(box: VBoxContainer) -> void:
	_add_slider(box, "Volumen general", GameSettings.master_volume, _on_master_changed)
	_add_slider(box, "Música", GameSettings.music_volume, _on_music_changed)
	_add_slider(box, "Efectos y ambiente", GameSettings.sfx_volume, _on_sfx_changed)
	var check := CheckButton.new()
	check.text = "Pantalla completa"
	check.button_pressed = GameSettings.fullscreen
	check.toggled.connect(_on_fullscreen_toggled)
	box.add_child(check)

func _add_slider(box: VBoxContainer, caption: String, value: float, callback: Callable) -> void:
	box.add_child(MenuStyle.label(caption, 16))
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = value
	slider.custom_minimum_size = Vector2(300.0, 28.0)
	slider.value_changed.connect(callback)
	box.add_child(slider)

func _on_master_changed(value: float) -> void:
	GameSettings.master_volume = value
	GameSettings.apply()

func _on_music_changed(value: float) -> void:
	GameSettings.music_volume = value
	GameSettings.apply()

func _on_sfx_changed(value: float) -> void:
	GameSettings.sfx_volume = value
	GameSettings.apply()

func _on_fullscreen_toggled(pressed: bool) -> void:
	GameSettings.fullscreen = pressed
	GameSettings.apply()

func close() -> void:
	GameSettings.save_settings()
	super.close()
