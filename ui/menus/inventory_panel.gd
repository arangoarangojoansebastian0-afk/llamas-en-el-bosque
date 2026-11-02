class_name InventoryPanel
extends OverlayPanel
## Inventario expandido: monedas, herramientas con usos, recursos y habilidades.

func _init() -> void:
	title_text = "Mochila e inventario"
	close_action = "inventory"

func _build(box: VBoxContainer) -> void:
	# Monedas
	box.add_child(MenuStyle.label("Monedas: %d" % GameState.coins, 18, Color("f0c830")))

	box.add_child(MenuStyle.label("Recursos", 20, MenuStyle.ACCENT))
	var water_limit := GameState.get_water_limit()
	box.add_child(MenuStyle.label("Agua: %d / %d" % [GameState.get_resource("water"), water_limit], 16))
	box.add_child(MenuStyle.label("Semillas nativas: %d" % GameState.get_resource("seed"), 16))
	if GameState.get_resource("seed_rare") > 0:
		box.add_child(MenuStyle.label("Semillas raras: %d" % GameState.get_resource("seed_rare"), 16, Color("a8f88f")))
	if GameState.get_resource("supply_box") > 0:
		box.add_child(MenuStyle.label("Cajas de suministros: %d" % GameState.get_resource("supply_box"), 16))
	box.add_child(MenuStyle.label("XP obtenida: %d" % GameState.get_stat("xp"), 16, Color("a8d98f")))

	# Herramientas
	box.add_child(MenuStyle.label("Herramientas", 20, MenuStyle.ACCENT))
	var has_any_tool := false
	for tool_id in GameState.TOOL_MAX_USES.keys():
		if not GameState.has_tool(tool_id):
			continue
		has_any_tool = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		box.add_child(row)
		var uses := int(GameState.tools.get(tool_id, 0))
		var uses_text := "Ilimitado" if uses < 0 else ("Usos: %d" % uses)
		var name_text := ItemDatabase.get_name(tool_id)
		row.add_child(MenuStyle.label("%s  [%s]" % [name_text, uses_text], 15))
		if tool_id == "medkit":
			var use_btn := MenuStyle.button("Usar botiquin")
			use_btn.custom_minimum_size = Vector2(160.0, 36.0)
			use_btn.pressed.connect(func(): _use_medkit())
			row.add_child(use_btn)
	if not has_any_tool:
		box.add_child(MenuStyle.label("(sin herramientas: busca o compra en tiendas)", 14, Color(0.6, 0.6, 0.5)))

	# Habilidades
	box.add_child(MenuStyle.label("Habilidades", 20, MenuStyle.ACCENT))
	var skills: Array[String] = [
		"Control del fuego: Espacio cerca del fuego lanza agua.",
		"Observacion: Espacio sin fuego resalta indicios y animales.",
		"Rescate: E sobre un animal atrapado lo guia al refugio.",
		"Reforestacion: E sobre suelo quemado planta un brote (1 semilla).",
	]
	if GameState.has_tool("extinguisher"):
		skills.append("Extintor: E cerca del fuego lo apaga al instante (5 usos).")
	if GameState.has_tool("lantern"):
		skills.append("Linterna: Ilumina zonas oscuras o bajo humo denso.")
	if GameState.has_tool("fire_suit"):
		skills.append("Traje ignifugo: Reduce el dano del fuego en un 70%.")
	for skill in skills:
		var line := MenuStyle.label("  * " + skill, 13)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(500.0, 0.0)
		box.add_child(line)

func _use_medkit() -> void:
	if not GameState.use_tool("medkit"):
		GameState.post_message("No tienes botiquin.")
		return
	GameState.heal(50.0)
	Sound.play("pickup", -2.0)
	GameState.post_message("+50 vida (botiquin usado)")
