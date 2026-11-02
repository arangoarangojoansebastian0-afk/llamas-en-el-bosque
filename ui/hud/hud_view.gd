class_name HudView
extends Control
## HUD: vida, resistencia, agua, semillas, objetivo, indicador de interacción y avisos.

const PANEL_COLOR := Color(0.05, 0.09, 0.07, 0.84)
const BORDER_COLOR := Color(0.59, 0.53, 0.37, 1.0)
const TEXT_COLOR := Color(0.93, 0.89, 0.79, 1.0)

var quest_title := ""
var quest_lines: Array[String] = []
var _prompt := ""
var _notice := ""
var _notice_time := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.message_posted.connect(_on_message)

func bind_player(player: Player) -> void:
	player.prompt_changed.connect(_on_prompt_changed)

func _process(delta: float) -> void:
	_notice_time = maxf(0.0, _notice_time - delta)
	queue_redraw()

func _on_message(text: String) -> void:
	_notice = text
	_notice_time = 4.0

func _on_prompt_changed(text: String) -> void:
	_prompt = text

func _draw() -> void:
	var font := ThemeDB.fallback_font
	_panel(Rect2(12.0, 12.0, 300.0, 108.0))
	_bar(font, Rect2(128.0, 22.0, 172.0, 14.0), GameState.health / GameState.MAX_HEALTH, Color("d1503a"), "VIDA")
	_bar(font, Rect2(128.0, 44.0, 172.0, 14.0), GameState.stamina / GameState.MAX_STAMINA, Color("8fbf4f"), "RESISTENCIA")
	draw_string(font, Vector2(24.0, 79.0), "AGUA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)
	var water := GameState.get_resource("water")
	var water_limit := GameState.get_water_limit()
	for i in range(water_limit):
		var drop := Rect2(128.0 + float(i) * 18.0, 66.0, 12.0, 16.0)
		if i < water:
			draw_rect(drop, Color("5fb4dc"))
			draw_rect(Rect2(drop.position.x + 2.0, drop.position.y + 2.0, 3.0, 5.0), Color("b8e6f7"))
		else:
			draw_rect(drop, Color(0.5, 0.6, 0.65, 0.6), false, 1.0)
	draw_string(font, Vector2(24.0, 106.0), "SEMILLAS", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)
	draw_string(font, Vector2(128.0, 106.0), "x %d" % GameState.get_resource("seed"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a8d98f"))

	# Monedas
	draw_circle(Vector2(252.0, 99.0), 7.0, Color("f0c830"))
	draw_string(font, Vector2(248.0, 104.0), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("3a2010"))
	draw_string(font, Vector2(262.0, 106.0), "%d" % GameState.coins, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f0c830"))

	# Indicadores de herramientas equipadas
	var tool_x := 12.0
	var tool_y := 126.0
	var tool_icons: Array[String] = []
	if GameState.has_tool("fire_suit"): tool_icons.append("TRAJE")
	if GameState.has_tool("extinguisher"): tool_icons.append("EXT.x%d" % max(0, int(GameState.tools.get("extinguisher", 0))))
	if GameState.has_tool("lantern"): tool_icons.append("LINTERNA")
	if GameState.has_tool("radio_pro"): tool_icons.append("RADIO")
	if GameState.has_tool("radio_com"): tool_icons.append("COM")
	if GameState.has_tool("axe"): tool_icons.append("HACHA")
	if GameState.has_tool("shovel"): tool_icons.append("PALA")
	if GameState.has_tool("detector_calor"): tool_icons.append("DET.x%d" % max(0, int(GameState.tools.get("detector_calor", 0))))
	if GameState.has_tool("kit_reparacion"): tool_icons.append("KIT.x%d" % max(0, int(GameState.tools.get("kit_reparacion", 0))))
	if GameState.has_tool("botiquin_animal"): tool_icons.append("BOT.ANIMAL")
	if GameState.has_tool("backpack_large"): tool_icons.append("MOCHILA+")
	if tool_icons.size() > 0:
		var tools_panel_w := 300.0
		_panel(Rect2(12.0, 120.0, tools_panel_w, 22.0))
		var t_str := "  ".join(tool_icons)
		draw_string(font, Vector2(18.0, 134.0), t_str, HORIZONTAL_ALIGNMENT_LEFT, int(tools_panel_w - 12.0), 10, Color("c8e8c0"))

	if quest_title != "":
		var body := "\n".join(quest_lines)
		var body_size := font.get_multiline_string_size(body, HORIZONTAL_ALIGNMENT_LEFT, 318.0, 12)
		_panel(Rect2(size.x - 352.0, 12.0, 340.0, 44.0 + body_size.y))
		draw_string(font, Vector2(size.x - 340.0, 31.0), quest_title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, 318.0, 12, Color("ffdf9a"))
		if body != "":
			draw_multiline_string(font, Vector2(size.x - 340.0, 50.0), body, HORIZONTAL_ALIGNMENT_LEFT, 318.0, 12, -1, TEXT_COLOR)

	if _prompt != "":
		var text_size := font.get_string_size(_prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15)
		var box := Rect2((size.x - text_size.x) * 0.5 - 14.0, size.y - 104.0, text_size.x + 28.0, 30.0)
		_panel(box)
		draw_string(font, Vector2(box.position.x + 14.0, box.position.y + 20.0), _prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ffdf9a"))

	if _notice_time > 0.0:
		var alpha := minf(1.0, _notice_time)
		var notice_size := font.get_string_size(_notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
		var notice_box := Rect2(12.0, size.y - 52.0, notice_size.x + 28.0, 32.0)
		draw_rect(notice_box, Color(0.05, 0.09, 0.07, 0.85 * alpha))
		draw_string(font, Vector2(26.0, size.y - 31.0), _notice, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.93, 0.89, 0.79, alpha))

	draw_string(font, Vector2(size.x - 472.0, size.y - 12.0), "WASD mover  Shift correr  E interactuar  Espacio agua/observar  J diario  I mochila  M mapa  ESC pausa", HORIZONTAL_ALIGNMENT_RIGHT, 460.0, 11, Color(0.85, 0.85, 0.75, 0.8))

func _panel(area: Rect2) -> void:
	draw_rect(area, PANEL_COLOR)
	draw_rect(area, BORDER_COLOR, false, 1.0)

func _bar(font: Font, area: Rect2, ratio: float, fill: Color, caption: String) -> void:
	draw_string(font, Vector2(24.0, area.position.y + 11.0), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, TEXT_COLOR)
	draw_rect(area, Color(0.0, 0.0, 0.0, 0.55))
	draw_rect(Rect2(area.position, Vector2(area.size.x * clampf(ratio, 0.0, 1.0), area.size.y)), fill)
	draw_rect(Rect2(area.position, Vector2(area.size.x * clampf(ratio, 0.0, 1.0), 3.0)), fill.lightened(0.25))
	draw_rect(area, BORDER_COLOR, false, 1.0)

