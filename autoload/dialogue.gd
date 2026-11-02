extends CanvasLayer
## Cuadro de diálogo con efecto máquina de escribir y opciones. Autoload "Dialogue".
## Uso: Dialogue.start([Dialogue.say("Elena", "Hola"), ...]). La última línea puede llevar
## "choices": [["Texto", "id"], ...]; al cerrarse se emite finished(id_elegido).

signal finished(choice_id: String)

const CHARS_PER_SECOND := 55.0

var is_open := false

var _lines: Array = []
var _index := 0
var _typing := false
var _chars := 0.0
var _last_blip := 0
var _closed_at := -10000
var _last_choice := ""
var _name_label: Label
var _text_label: Label
var _hint_label: Label
var _choices_box: VBoxContainer

func say(who: String, text: String) -> Dictionary:
	return {"who": who, "text": text}

func _ready() -> void:
	layer = 70
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 90)
	margin.add_theme_constant_override("margin_right", 90)
	margin.add_theme_constant_override("margin_bottom", 26)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_END
	column.add_theme_constant_override("separation", 10)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	_choices_box = VBoxContainer.new()
	_choices_box.add_theme_constant_override("separation", 6)
	_choices_box.size_flags_horizontal = Control.SIZE_SHRINK_END
	column.add_child(_choices_box)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.BG, MenuStyle.BORDER, 2, 18.0))
	column.add_child(panel)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	panel.add_child(inner)
	_name_label = MenuStyle.label("", 18, MenuStyle.ACCENT)
	inner.add_child(_name_label)
	_text_label = MenuStyle.label("", 17)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.custom_minimum_size = Vector2(0.0, 72.0)
	inner.add_child(_text_label)
	_hint_label = MenuStyle.label("E  ▸", 13, Color(0.8, 0.78, 0.6, 0.9))
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inner.add_child(_hint_label)

func start(lines: Array) -> void:
	if is_open or lines.is_empty():
		return
	_lines = lines
	_index = 0
	_last_choice = ""
	is_open = true
	visible = true
	get_tree().paused = true
	_show_line()

func recently_closed() -> bool:
	return Time.get_ticks_msec() - _closed_at < 300

func _show_line() -> void:
	var line: Dictionary = _lines[_index]
	_name_label.text = str(line.get("who", ""))
	_text_label.text = str(line.get("text", ""))
	_text_label.visible_characters = 0
	_chars = 0.0
	_last_blip = 0
	_typing = true
	_hint_label.visible = false
	for child in _choices_box.get_children():
		child.queue_free()

func _process(delta: float) -> void:
	if not is_open or not _typing:
		return
	_chars += delta * CHARS_PER_SECOND
	_text_label.visible_characters = int(_chars)
	if int(_chars) - _last_blip >= 3:
		_last_blip = int(_chars)
		Sound.play("blip%d" % randi_range(1, 3), -10.0, 0.08)
	if int(_chars) >= _text_label.text.length():
		_finish_typing()

func _finish_typing() -> void:
	_typing = false
	_text_label.visible_characters = -1
	var line: Dictionary = _lines[_index]
	var choices: Array = line.get("choices", [])
	if choices.is_empty():
		_hint_label.visible = true
		return
	var first: Button = null
	for choice in choices:
		var label_text: String = choice[0]
		var choice_id: String = choice[1]
		var button := MenuStyle.button(label_text)
		button.custom_minimum_size = Vector2(420.0, 42.0)
		button.pressed.connect(_on_choice.bind(choice_id))
		_choices_box.add_child(button)
		if first == null:
			first = button
	if first != null:
		first.grab_focus()

func _on_choice(choice_id: String) -> void:
	_last_choice = choice_id
	_close()

func _advance() -> void:
	if _typing:
		_finish_typing()
		return
	if _choices_box.get_child_count() > 0:
		return
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_line()

func _close() -> void:
	visible = false
	is_open = false
	_closed_at = Time.get_ticks_msec()
	get_tree().paused = false
	finished.emit(_last_choice)

func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return
	var pressed := event.is_action_pressed("interact") or event.is_action_pressed("action") or event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		pressed = pressed or (click.pressed and click.button_index == MOUSE_BUTTON_LEFT)
	if pressed:
		get_viewport().set_input_as_handled()
		_advance()
