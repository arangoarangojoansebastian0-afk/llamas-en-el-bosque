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
	if tool_id == "kit_reparacion":
			var repair_btn := MenuStyle.button("Reparar estructura")
				repair_btn.custom_minimum_size = Vector2(160.0, 36.0)
			repair_btn.pressed.connect(func(): _use_repair_kit())
			row.add_child(repair_btn)
		if tool_id == "botiquin_animal":
			var animal_btn := MenuStyle.button("Curar animal")
				animal_btn.custom_minimum_size = Vector2(160.0, 36.0)
			animal_btn.pressed.connect(func(): _use_animal_medkit())
			row.add_child(animal_btn)
		if tool_id == "lantern":
			var lantern_btn := MenuStyle.button("Encender linterna")
			lantern_btn.custom_minimum_size = Vector2(160.0, 36.0)
			lantern_btn.pressed.connect(func(): _toggle_lantern())
			row.add_child(lantern_btn)
		if tool_id == "radio_pro" or tool_id == "radio_com":
			var radio_btn := MenuStyle.button("Usar radio")
			radio_btn.custom_minimum_size = Vector2(160.0, 36.0)
			radio_btn.pressed.connect(func(): _use_radio())
			row.add_child(radio_btn)
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

func _use_repair_kit() -> void:
	if not GameState.use_tool("kit_reparacion"):
		GameState.post_message("No tienes kit de reparación.")
		return
	GameState.post_message("Kit de reparación equipado. Acércate a una estructura dañada.")

func _use_animal_medkit() -> void:
	if not GameState.use_tool("botiquin_animal"):
		GameState.post_message("No tienes botiquín animal.")
		return
	GameState.post_message("Botiquín animal equipado. Acércate a un animal herido.")

func _toggle_lantern() -> void:
	if not GameState.has_tool("lantern"):
		GameState.post_message("No tienes linterna.")
		return
	GameState.post_message("Linterna: usa la acción (espacio) para encender/apagar.")

func _use_radio() -> void:
	if not (GameState.has_tool("radio_pro") or GameState.has_tool("radio_com")):
		GameState.post_message("No tienes equipo de comunicación.")
		return
	GameState.post_message("Radio: usa la acción (espacio) para transmitir.")
