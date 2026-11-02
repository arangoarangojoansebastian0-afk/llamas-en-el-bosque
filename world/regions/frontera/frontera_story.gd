class_name FronteraStory
extends Node
## Historia de la región Frontera: conversaciones de los NPC, encadenado de misiones y final.
## Cadena: Un bosque en peligro -> Primeras llamas -> (Rescate + Recuperar) -> El futuro del bosque.

signal fire_b_requested(delay: float)
signal ending_reached(ending_id: String)

var fire_manager: FireManager

var _npcs: Dictionary = {}
var _pending_ending := ""

func _ready() -> void:
	Quests.changed.connect(refresh)
	Quests.quest_completed.connect(_on_quest_completed)
	GameState.stat_changed.connect(_on_stat_changed)

func begin_new_game() -> void:
	Quests.start("bosque_en_peligro")

func bind_npc(npc: Npc) -> void:
	_npcs[npc.npc_id] = npc
	npc.talked.connect(_on_npc_talked)

func bind_clue(clue: Clue) -> void:
	clue.examined.connect(_on_clue_examined)

func bind_animal(animal: Animal) -> void:
	animal.rescued.connect(_on_animal_rescued)

## Actualiza los avisos "!" sobre los NPC con algo nuevo que decir.
func refresh() -> void:
	_set_news("elena", Quests.is_active("bosque_en_peligro") and not Quests.objective_done("bosque_en_peligro", "talk_elena"))
	_set_news("tomas", Quests.is_active("primeras_llamas") and not Quests.objective_done("primeras_llamas", "talk_tomas"))
	_set_news("lucia", (Quests.is_active("rescate") and not Quests.objective_done("rescate", "talk_lucia")) or Quests.is_active("futuro"))

func _set_news(npc_id: String, value: bool) -> void:
	if _npcs.has(npc_id):
		var npc: Npc = _npcs[npc_id]
		npc.has_news = value

# --- Eventos del mundo -------------------------------------------------------

func on_fire_a_started() -> void:
	Quests.start("primeras_llamas")

func on_zone_cleared(zone: String) -> void:
	if zone == "A":
		Quests.add_progress("primeras_llamas", "put_out_a")
	elif zone == "B":
		Quests.add_progress("recuperar", "put_out_b")

func on_cells_changed() -> void:
	if not Quests.is_active("recuperar"):
		return
	if not bool(GameState.flags.get("b_ignited", false)):
		return
	var burned := fire_manager.count_state(FireCell.State.BURNED)
	var recovered := fire_manager.count_state(FireCell.State.RECOVERED)
	if fire_manager.count_dangerous() == 0 and burned == 0 and recovered > 0:
		Quests.set_progress("recuperar", "sprouts", 1)

func _on_clue_examined(_clue: Clue) -> void:
	Quests.add_progress("bosque_en_peligro", "clues")

func _on_animal_rescued(_animal: Animal) -> void:
	GameState.add_stat("rescued")
	Quests.add_progress("rescate", "rescue")

func _on_stat_changed(id: String, _value: int) -> void:
	if id == "seeds":
		_sync_seeds()

func _sync_seeds() -> void:
	Quests.set_progress("recuperar", "seeds", GameState.get_stat("seeds"))

func _on_quest_completed(id: String) -> void:
	match id:
		"primeras_llamas":
			GameState.flags["b_requested"] = true
			Quests.start("rescate")
			Quests.start("recuperar")
			_sync_seeds()
			fire_b_requested.emit(4.0)
		"rescate", "recuperar":
			if Quests.is_done("rescate") and Quests.is_done("recuperar"):
				Quests.start("futuro")
		_:
			pass

# --- Conversaciones ------------------------------------------------------------

func _on_npc_talked(npc: Npc) -> void:
	match npc.npc_id:
		"elena":
			_talk_elena()
		"tomas":
			_talk_tomas()
		"lucia":
			_talk_lucia()
		"mateo":
			_talk_mateo()

func _current_hint() -> String:
	for quest_id in Quests.ORDER:
		var id := str(quest_id)
		if Quests.is_active(id):
			for objective in Quests.objectives(id):
				if not bool(objective["done"]):
					return str(objective["text"])
	return ""

func _talk_elena() -> void:
	var who := "Elena"
	var lines: Array = []
	if Quests.is_active("bosque_en_peligro") and not Quests.objective_done("bosque_en_peligro", "talk_elena"):
		lines.append(Dialogue.say(who, "¡Alto ahí! Soy Elena, guardabosques de la Frontera. No esperaba ver a nadie con este humo en el aire."))
		lines.append(Dialogue.say(who, "Llevamos semanas de sequía. El bosque está tan seco que una sola chispa puede convertirse en un incendio enorme."))
		lines.append(Dialogue.say(who, "Han aparecido focos pequeños junto al sendero y nadie sabe por qué. Necesito que busques indicios: restos de fogatas, colillas, hierba reseca."))
		lines.append(Dialogue.say(who, "Pulsa Espacio para observar tu entorno: lo importante se resaltará. Luego acércate y pulsa E para examinarlo."))
		lines.append(Dialogue.say(who, "Y lleva agua contigo. Hay un estanque aquí cerca y barriles a lo largo del camino. Cuando termines, sigue el sendero al este."))
		Quests.add_progress("bosque_en_peligro", "talk_elena")
	elif Quests.is_active("bosque_en_peligro"):
		var found := Quests.progress("bosque_en_peligro", "clues")
		lines.append(Dialogue.say(who, "Has encontrado %d de 3 indicios. Busca cerca del sendero: una fogata mal apagada, una colilla, hierba muy seca." % found))
		lines.append(Dialogue.say(who, "Recuerda: Espacio para observar, E para examinar."))
	elif Quests.is_done("futuro"):
		lines.append(Dialogue.say(who, "El bosque tiene futuro gracias a ti. Y a quien lo visite le recordaré siempre lo mismo: apagar bien la fogata, no tirar colillas y avisar al 112 ante cualquier humo."))
	else:
		lines.append(Dialogue.say(who, "Tus indicios dejaron claro que casi todos los incendios empiezan por un descuido humano."))
		lines.append(Dialogue.say(who, "Antes de irte de una fogata: apágala con agua, remueve las brasas y comprueba que esté fría al tacto."))
		var hint := _current_hint()
		if hint != "":
			lines.append(Dialogue.say(who, "Ahora mismo, lo importante: %s." % hint))
	Dialogue.start(lines)

func _talk_tomas() -> void:
	var who := "Tomás"
	var lines: Array = []
	if Quests.is_active("primeras_llamas") and not Quests.objective_done("primeras_llamas", "talk_tomas"):
		lines.append(Dialogue.say(who, "¡Por fin ayuda! Ese foco se propaga por la hierba seca. Si lo dejamos, saltará de un matorral a otro."))
		lines.append(Dialogue.say(who, "Apunta a la base de las llamas, no a lo alto. Pulsa Espacio cerca del fuego: cada lanzamiento gasta una unidad de agua."))
		lines.append(Dialogue.say(who, "Mantén la distancia: el calor te quita resistencia y las llamas te queman. Rellena en los barriles del camino con E."))
		lines.append(Dialogue.say(who, "Toma, dos unidades más. Y recuerda: con fuego, la prudencia es lo primero."))
		GameState.add_resource("water", 2)
		Quests.add_progress("primeras_llamas", "talk_tomas")
	elif Quests.is_active("primeras_llamas"):
		lines.append(Dialogue.say(who, "Ve primero a por los focos que más se propagan. ¡Ánimo!"))
	elif Quests.is_done("primeras_llamas"):
		lines.append(Dialogue.say(who, "Buen trabajo. Los cortafuegos, franjas de terreno sin vegetación, ayudan a frenar un incendio."))
		lines.append(Dialogue.say(who, "Si queda algún foco, apágalo. Y si ves a la doctora Lucía, dile que el este también está en riesgo."))
	else:
		lines.append(Dialogue.say(who, "Soy Tomás, bombero forestal. Vigilo este tramo del sendero. Si ves humo, acércate con cuidado, nunca corras sin saber de dónde viene el viento."))
		lines.append(Dialogue.say(who, "Si algo arde, avísame o usa agua en la base. Aquí estaré."))
	Dialogue.start(lines)

func _talk_lucia() -> void:
	var who := "Dra. Lucía"
	var lines: Array = []
	if Quests.is_active("futuro"):
		lines.append(Dialogue.say(who, "Lo lograste. El fuego está apagado, los animales a salvo y el suelo empieza a reverdecer."))
		lines.append(Dialogue.say(who, "Pero esto volverá a pasar si no cambiamos algo. Este año solo podemos financiar un plan. ¿Cuál eliges?"))
		lines.append({
			"who": who,
			"text": "Tu decisión marcará el futuro del bosque.",
			"choices": [
				["Reforestar con especies nativas", "reforest"],
				["Abrir cortafuegos y reforzar la vigilancia", "prevent"],
			],
		})
		Dialogue.finished.connect(_on_decision, CONNECT_ONE_SHOT)
	elif Quests.is_active("rescate") and not Quests.objective_done("rescate", "talk_lucia"):
		lines.append(Dialogue.say(who, "Soy Lucía, investigadora ambiental. Estudio cómo se recupera la fauna después de un incendio. Gracias por ayudar."))
		lines.append(Dialogue.say(who, "Los animales huyen del humo, pero los más lentos o los que se enredan en las zarzas quedan atrapados. Hay un conejo, una ardilla y un venado al este."))
		lines.append(Dialogue.say(who, "Acércate despacio: correr los asusta. Con Espacio los verás resaltados. Pulsa E para ayudarlos y guíalos hasta el refugio, el claro con el cartel al sur del sendero."))
		lines.append(Dialogue.say(who, "Mantenlos lejos de las llamas. Si te alejas mucho, te alcanzarán."))
		Quests.add_progress("rescate", "talk_lucia")
	elif Quests.is_active("rescate"):
		var left := Quests.target("rescate", "rescue") - Quests.progress("rescate", "rescue")
		lines.append(Dialogue.say(who, "Quedan %d animales por poner a salvo. Usa Espacio para localizarlos y E para ayudarlos." % left))
	elif Quests.is_active("recuperar"):
		lines.append(Dialogue.say(who, "Los animales están a salvo, gracias. Ahora el suelo quemado necesita vegetación."))
		lines.append(Dialogue.say(who, "Recoge semillas de especies nativas y plántalas en el suelo quemado con E. Cada brote ayuda a frenar la erosión y a devolver el hogar a la fauna."))
	elif Quests.is_done("futuro"):
		lines.append(Dialogue.say(who, "Gracias por todo. El bosque está en buenas manos."))
	else:
		lines.append(Dialogue.say(who, "Soy Lucía, investigadora ambiental. Estudio cómo se recupera la fauna tras los incendios."))
		lines.append(Dialogue.say(who, "Un incendio no solo quema árboles: destruye refugios y alimento. Cuando termines con el fuego del sendero, ven a verme."))
	Dialogue.start(lines)

func _on_decision(choice: String) -> void:
	if choice == "":
		return
	_pending_ending = choice
	GameState.flags["ending"] = choice
	var who := "Dra. Lucía"
	var lines: Array = []
	if choice == "reforest":
		lines.append(Dialogue.say(who, "Buena decisión. Plantaremos pinos, encinas y arbustos nativos: resisten mejor el fuego y alimentan a la fauna."))
		lines.append(Dialogue.say(who, "Tardará años, pero el bosque volverá a ser un hogar para todos."))
	else:
		lines.append(Dialogue.say(who, "Sensato. Con cortafuegos y vigilantes, un foco no llegará a ser un gran incendio."))
		lines.append(Dialogue.say(who, "El bosque dañado tardará más en recuperarse, pero estará más protegido que nunca."))
	Quests.add_progress("futuro", "decide")
	Dialogue.start(lines)
	Dialogue.finished.connect(_on_ending_dialogue_done, CONNECT_ONE_SHOT)

func _on_ending_dialogue_done(_choice: String) -> void:
	ending_reached.emit(_pending_ending)

func _talk_mateo() -> void:
	var who := "Mateo"
	var lines: Array = []
	if not bool(GameState.flags.get("mateo_gift", false)):
		lines.append(Dialogue.say(who, "Vivo cerca del estanque desde hace cuarenta años. Hoy vi a unos campistas marcharse sin apagar su fogata."))
		lines.append(Dialogue.say(who, "Si buscas pistas, mira por el sendero. Y toma estas semillas de encina que guardaba: seguro que les das mejor uso que yo."))
		GameState.flags["mateo_gift"] = true
		GameState.add_resource("seed", 2)
		GameState.add_stat("seeds", 2)
		GameState.post_message("+2 Semilla")
	else:
		lines.append(Dialogue.say(who, "Cuida el bosque, forastero. Es lo único que tenemos."))
	Dialogue.start(lines)
