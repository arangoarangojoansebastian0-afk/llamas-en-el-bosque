class_name WorldMap
extends CanvasLayer
## Mapa global con coordenadas, navegación de cámara y marcadores del progreso actual.

signal closed
signal travel_requested(region_id: String)


class MapSurface extends Control:
	signal region_selected(region_id: String)
	signal pointer_position_changed(global_position: Vector2)
	signal zoom_changed(value: float)

	var manager: Node
	var zoom_level := 1.0
	var pan_offset := Vector2.ZERO
	var selected_region := "frontera"
	var _dragging := false
	var _drag_start := Vector2.ZERO
	var _pan_start := Vector2.ZERO

	const MIN_ZOOM := 0.65
	const MAX_ZOOM := 3.5

	func _ready() -> void:
		clip_contents = true
		mouse_filter = Control.MOUSE_FILTER_STOP

	func reset_view() -> void:
		zoom_level = 1.0
		pan_offset = Vector2.ZERO
		zoom_changed.emit(zoom_level)
		queue_redraw()

	func change_zoom(factor: float) -> void:
		_zoom_at(zoom_level * factor, size * 0.5)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("17211b"))
		if manager == null:
			return
		var bounds: Rect2 = manager.get_world_bounds()
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			return

		_draw_grid(bounds)
		_draw_regions()
		_draw_locations()
		_draw_player()

	func _draw_grid(bounds: Rect2) -> void:
		var font: Font = ThemeDB.fallback_font
		var scale := _scale_for_map()
		var step := 500 if scale >= 0.13 else 1000
		var grid_color := Color(0.72, 0.78, 0.68, 0.12)
		for x in range(0, int(bounds.end.x) + 1, step):
			var top := _world_to_screen(Vector2(float(x), bounds.position.y))
			var bottom := _world_to_screen(Vector2(float(x), bounds.end.y))
			draw_line(top, bottom, grid_color, 1.0)
			if x > 0:
				draw_string(font, top + Vector2(3.0, 12.0), str(x), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(0.7, 0.76, 0.67, 0.65))
		for y in range(0, int(bounds.end.y) + 1, step):
			var left := _world_to_screen(Vector2(bounds.position.x, float(y)))
			var right := _world_to_screen(Vector2(bounds.end.x, float(y)))
			draw_line(left, right, grid_color, 1.0)
			if y > 0:
				draw_string(font, left + Vector2(4.0, -3.0), str(y), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 9, Color(0.7, 0.76, 0.67, 0.65))

	func _draw_regions() -> void:
		var font: Font = ThemeDB.fallback_font
		for region_id in manager.get_region_ids():
			var info: Dictionary = manager.get_region_info(region_id)
			var world_rect: Rect2 = manager.get_region_bounds(region_id)
			var screen_rect := Rect2(_world_to_screen(world_rect.position), world_rect.size * _scale_for_map())
			var discovered: bool = manager.is_discovered(region_id)
			var region_color: Color = info.get("map_color", Color("53654e"))
			if not discovered:
				region_color = Color(region_color.r * 0.28, region_color.g * 0.3, region_color.b * 0.3, 0.88)
			draw_rect(screen_rect, region_color)
			draw_rect(screen_rect, Color(0.77, 0.79, 0.67, 0.68 if discovered else 0.32), false, 1.4)
			if region_id == manager.get_player_region():
				draw_rect(screen_rect.grow(2.0), Color("e6c879"), false, 2.0)
			if region_id == selected_region:
				draw_rect(screen_rect.grow(4.0), Color("fff0bb"), false, 1.5)
			var name_color := Color("f0e7d1") if discovered else Color(0.75, 0.77, 0.73, 0.68)
			var title := str(info.get("name", region_id))
			if not discovered:
				title += " · sin descubrir"
			var title_size := 13 if _scale_for_map() * zoom_level >= 0.11 else 11
			draw_string(font, screen_rect.position + Vector2(9.0, 21.0), title, HORIZONTAL_ALIGNMENT_LEFT, maxf(90.0, screen_rect.size.x - 18.0), title_size, name_color)

	func _draw_locations() -> void:
		var font: Font = ThemeDB.fallback_font
		for marker in manager.get_map_markers():
			if not bool(marker.get("discovered", false)) or not bool(marker.get("region_discovered", false)):
				continue
			var point: Vector2 = _world_to_screen(marker.get("global_position", Vector2.ZERO))
			var active_quest: bool = bool(marker.get("active_quest", false))
			var marker_color := Color("edbd62") if active_quest else _marker_color(str(marker.get("type", "")))
			if active_quest:
				draw_colored_polygon(
					PackedVector2Array([point + Vector2(0.0, -6.0), point + Vector2(6.0, 0.0), point + Vector2(0.0, 6.0), point + Vector2(-6.0, 0.0)]),
					marker_color
				)
			else:
				draw_circle(point, 4.0, marker_color)
				draw_circle(point, 5.5, Color(0.04, 0.07, 0.05, 0.9), false, 1.0)
			if active_quest or zoom_level >= 1.35:
				draw_string(font, point + Vector2(8.0, -5.0), str(marker.get("name", "")), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color("f1e7d2"))

	func _draw_player() -> void:
		if not manager.has_player_position():
			return
		var point: Vector2 = _world_to_screen(manager.get_player_position())
		draw_circle(point, 8.0, Color(0.18, 0.72, 0.94, 0.22))
		draw_circle(point, 4.5, Color("75ddf4"))
		draw_circle(point, 6.0, Color("0b2630"), false, 1.2)

	func _marker_color(marker_type: String) -> Color:
		match marker_type:
			"npc":
				return Color("d9ca9b")
			"clue":
				return Color("ef9d56")
			"animal":
				return Color("9ad28f")
			"resource":
				return Color("6ec3dd")
			"safe_zone":
				return Color("88c98c")
			"fire_zone":
				return Color("ec7954")
			_:
				return Color("ded7ba")

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			var button_event := event as InputEventMouseButton
			if button_event.button_index == MOUSE_BUTTON_WHEEL_UP and button_event.pressed:
				_zoom_at(zoom_level * 1.15, button_event.position)
				accept_event()
			elif button_event.button_index == MOUSE_BUTTON_WHEEL_DOWN and button_event.pressed:
				_zoom_at(zoom_level / 1.15, button_event.position)
				accept_event()
			elif button_event.button_index == MOUSE_BUTTON_LEFT:
				if button_event.pressed:
					_dragging = true
					_drag_start = button_event.position
					_pan_start = pan_offset
				else:
					var was_click := button_event.position.distance_to(_drag_start) < 6.0
					_dragging = false
					if was_click:
						_select_region(button_event.position)
					accept_event()
		elif event is InputEventMouseMotion:
			var motion := event as InputEventMouseMotion
			if _dragging:
				pan_offset = _pan_start + motion.position - _drag_start
				queue_redraw()
			else:
				var world_position := _screen_to_world(motion.position)
				var bounds: Rect2 = manager.get_world_bounds()
				if bounds.has_point(world_position):
					pointer_position_changed.emit(world_position)

	func _zoom_at(requested_zoom: float, pivot: Vector2) -> void:
		var world_point := _screen_to_world(pivot)
		zoom_level = clampf(requested_zoom, MIN_ZOOM, MAX_ZOOM)
		pan_offset += pivot - _world_to_screen(world_point)
		zoom_changed.emit(zoom_level)
		queue_redraw()

	func _select_region(screen_position: Vector2) -> void:
		var world_position := _screen_to_world(screen_position)
		for region_id in manager.get_region_ids():
			if manager.get_region_bounds(region_id).has_point(world_position):
				selected_region = region_id
				region_selected.emit(region_id)
				queue_redraw()
				return

	func _scale_for_map() -> float:
		var bounds: Rect2 = manager.get_world_bounds()
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			return 0.01
		var available := Vector2(maxf(1.0, size.x - 28.0), maxf(1.0, size.y - 28.0))
		return minf(available.x / bounds.size.x, available.y / bounds.size.y) * zoom_level

	func _world_to_screen(world_position: Vector2) -> Vector2:
		var bounds: Rect2 = manager.get_world_bounds()
		var scale := _scale_for_map()
		var map_size := bounds.size * scale
		var origin := (size - map_size) * 0.5 + pan_offset - bounds.position * scale
		return origin + world_position * scale

	func _screen_to_world(screen_position: Vector2) -> Vector2:
		var bounds: Rect2 = manager.get_world_bounds()
		var scale := _scale_for_map()
		var map_size := bounds.size * scale
		var origin := (size - map_size) * 0.5 + pan_offset - bounds.position * scale
		return (screen_position - origin) / scale


var _map_surface: MapSurface
var _region_title: Label
var _region_description: Label
var _region_status: Label
var _location_summary: Label
var _coordinate_label: Label
var _zoom_label: Label
var _travel_button: Button
var _mission_list: VBoxContainer
var _selected_region := "frontera"


func _ready() -> void:
	layer = 55
	process_mode = Node.PROCESS_MODE_ALWAYS
	_selected_region = WorldManager.get_player_region()
	_build_ui()
	_connect_map_signals()
	_update_region_details(_selected_region)
	_update_active_missions()


func _build_ui() -> void:
	var screen := Control.new()
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)

	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.02, 0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	screen.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	screen.add_child(margin)

	var frame := PanelContainer.new()
	frame.add_theme_stylebox_override("panel", MenuStyle.box(MenuStyle.BG, MenuStyle.BORDER, 2, 14.0))
	margin.add_child(frame)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	frame.add_child(content)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)
	header.add_child(MenuStyle.label("MAPA DEL MUNDO", 24, MenuStyle.ACCENT))
	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)
	var close_button := MenuStyle.button("Cerrar")
	close_button.custom_minimum_size = Vector2(112.0, 34.0)
	close_button.pressed.connect(_close)
	header.add_child(close_button)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.custom_minimum_size = Vector2(0.0, 300.0)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(body)

	_map_surface = MapSurface.new()
	_map_surface.name = "MapSurface"
	_map_surface.manager = WorldManager
	_map_surface.selected_region = _selected_region
	_map_surface.custom_minimum_size = Vector2(450.0, 280.0)
	_map_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_map_surface)

	var sidebar := PanelContainer.new()
	sidebar.custom_minimum_size = Vector2(210.0, 0.0)
	sidebar.add_theme_stylebox_override("panel", MenuStyle.box(Color(0.07, 0.11, 0.08, 0.96), MenuStyle.BORDER, 1, 12.0))
	body.add_child(sidebar)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 7)
	sidebar.add_child(details)
	details.add_child(MenuStyle.label("REGIÓN SELECCIONADA", 12, MenuStyle.ACCENT))
	_region_title = MenuStyle.label("", 18, MenuStyle.TEXT)
	_region_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_region_title)
	_region_status = MenuStyle.label("", 12, Color("c4c6b7"))
	_region_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_region_status)
	_region_description = MenuStyle.label("", 13, MenuStyle.TEXT)
	_region_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_region_description)
	_location_summary = MenuStyle.label("", 12, Color("c4c6b7"))
	_location_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_location_summary)
	_travel_button = MenuStyle.button("Viajar")
	_travel_button.custom_minimum_size = Vector2(0.0, 34.0)
	_travel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_travel_button.pressed.connect(_travel_to_selected_region)
	details.add_child(_travel_button)

	details.add_child(MenuStyle.label("MISIONES ACTIVAS", 12, MenuStyle.ACCENT))
	var mission_scroll := ScrollContainer.new()
	mission_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mission_scroll.custom_minimum_size = Vector2(0.0, 70.0)
	details.add_child(mission_scroll)
	_mission_list = VBoxContainer.new()
	_mission_list.name = "MissionList"
	_mission_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mission_scroll.add_child(_mission_list)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 7)
	content.add_child(footer)
	var zoom_out := _control_button("−", Vector2(36.0, 32.0))
	zoom_out.pressed.connect(func() -> void: _map_surface.change_zoom(1.0 / 1.2))
	footer.add_child(zoom_out)
	_zoom_label = MenuStyle.label("100 %", 12, MenuStyle.TEXT)
	_zoom_label.custom_minimum_size = Vector2(54.0, 0.0)
	footer.add_child(_zoom_label)
	var zoom_in := _control_button("+", Vector2(36.0, 32.0))
	zoom_in.pressed.connect(func() -> void: _map_surface.change_zoom(1.2))
	footer.add_child(zoom_in)
	var reset_button := _control_button("Recentrar", Vector2(100.0, 32.0))
	reset_button.pressed.connect(_map_surface.reset_view)
	footer.add_child(reset_button)
	var legend := MenuStyle.label("● jugador   ◆ misión   ● ubicación", 11, Color("c4c6b7"))
	legend.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(legend)
	_coordinate_label = MenuStyle.label("COORD. X 0000 · Y 0000", 12, MenuStyle.ACCENT)
	_coordinate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	footer.add_child(_coordinate_label)


func _control_button(text: String, minimum_size: Vector2) -> Button:
	var button := MenuStyle.button(text)
	button.custom_minimum_size = minimum_size
	return button


func _connect_map_signals() -> void:
	_map_surface.region_selected.connect(_on_region_selected)
	_map_surface.pointer_position_changed.connect(_on_pointer_position_changed)
	_map_surface.zoom_changed.connect(_on_zoom_changed)
	WorldManager.regions_changed.connect(_refresh_map)
	WorldManager.location_discovered.connect(_on_location_discovered)
	WorldManager.player_position_updated.connect(_on_player_position_updated)
	Quests.changed.connect(_refresh_map)


func _refresh_map() -> void:
	if not is_instance_valid(_map_surface):
		return
	_map_surface.queue_redraw()
	_update_region_details(_selected_region)
	_update_active_missions()


func _on_region_selected(region_id: String) -> void:
	_selected_region = region_id
	_update_region_details(region_id)


func _update_region_details(region_id: String) -> void:
	var info: Dictionary = WorldManager.get_region_info(region_id)
	if info.is_empty():
		return
	var discovered: bool = WorldManager.is_discovered(region_id)
	_region_title.text = str(info.get("name", region_id))
	if not discovered:
		_region_status.text = "Sin descubrir · avanza en las misiones para conocerla."
		_region_description.text = "Las ubicaciones y los detalles se revelarán al explorar."
	else:
		var status := "Región actual" if region_id == WorldManager.get_player_region() else "Región descubierta"
		if not WorldManager.can_travel_to_region(region_id) and region_id != WorldManager.get_player_region():
			status += " · escena jugable no incluida"
		_region_status.text = status
		_region_description.text = str(info.get("description", ""))
	var known_location_names: Array[String] = []
	for marker in WorldManager.get_map_markers():
		if str(marker.get("region", "")) == region_id and bool(marker.get("discovered", false)):
			known_location_names.append(str(marker.get("name", "")))
	if not discovered:
		_location_summary.text = "Ubicaciones ocultas"
	elif known_location_names.is_empty():
		_location_summary.text = "Aún no se conocen ubicaciones."
	else:
		var visible_names: Array[String] = []
		for i in range(mini(known_location_names.size(), 4)):
			visible_names.append(known_location_names[i])
		if known_location_names.size() > 4:
			visible_names.append("+%d más" % (known_location_names.size() - 4))
		_location_summary.text = "Lugares: " + " · ".join(visible_names)
	_travel_button.visible = discovered and region_id != WorldManager.get_player_region() and WorldManager.can_travel_to_region(region_id)
	_map_surface.selected_region = region_id
	_map_surface.queue_redraw()


func _update_active_missions() -> void:
	if not is_instance_valid(_mission_list):
		return
	for child in _mission_list.get_children():
		child.queue_free()
	var active_count := 0
	for quest_value in Quests.ORDER:
		var quest_id := str(quest_value)
		if not Quests.is_active(quest_id):
			continue
		active_count += 1
		var objectives: Array = Quests.objectives(quest_id)
		var next_objective := ""
		for objective in objectives:
			if not bool(objective.get("done", false)):
				next_objective = str(objective.get("text", ""))
				break
		var mission_text := Quests.get_title(quest_id)
		if next_objective != "":
			mission_text += "\n· " + next_objective
		var mission_label := MenuStyle.label(mission_text, 11, MenuStyle.TEXT)
		mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_mission_list.add_child(mission_label)
	if active_count == 0:
		_mission_list.add_child(MenuStyle.label("No hay misiones activas.", 11, Color("c4c6b7")))


func _on_pointer_position_changed(global_position: Vector2) -> void:
	_coordinate_label.text = "COORD. X %04d · Y %04d" % [roundi(global_position.x), roundi(global_position.y)]


func _on_zoom_changed(value: float) -> void:
	_zoom_label.text = "%d %%" % roundi(value * 100.0)


func _on_player_position_updated(_global_position: Vector2, _region_id: String) -> void:
	_map_surface.queue_redraw()

func _on_location_discovered(_location_id: String) -> void:
	_refresh_map()

func _travel_to_selected_region() -> void:
	if not WorldManager.can_travel_to_region(_selected_region):
		return
	travel_requested.emit(_selected_region)
	WorldManager.go_to_region(_selected_region)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("map"):
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if is_instance_valid(get_tree()):
		get_tree().paused = false
	closed.emit()
	queue_free()
