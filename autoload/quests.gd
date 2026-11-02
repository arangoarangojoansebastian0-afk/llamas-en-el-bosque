extends Node
## Sistema de misiones: definiciones, progreso, recompensas y guardado.
## Autoload "Quests". Las misiones son datos; la lógica de historia vive en la región.

signal quest_started(id: String)
signal quest_completed(id: String)
signal changed

const ORDER := ["bosque_en_peligro", "primeras_llamas", "rescate", "recuperar", "futuro"]

const DEFS := {
	"bosque_en_peligro": {
		"title": "Un bosque en peligro",
		"summary": "Elena, la guardabosques, necesita saber qué provocó los primeros focos junto al sendero.",
		"objectives": [
			{"id": "talk_elena", "text": "Habla con Elena, la guardabosques", "target": 1},
			{"id": "clues", "text": "Examina indicios de incendio (Espacio observa)", "target": 3},
		],
		"reward": {"xp": 100, "water": 1},
	},
	"primeras_llamas": {
		"title": "Primeras llamas",
		"summary": "Un foco se ha encendido junto al sendero. Tomás, el bombero forestal, coordina la emergencia.",
		"objectives": [
			{"id": "talk_tomas", "text": "Habla con Tomás, el bombero forestal", "target": 1},
			{"id": "put_out_a", "text": "Apaga los focos junto al sendero", "target": 1},
		],
		"reward": {"xp": 150, "water": 2},
	},
	"rescate": {
		"title": "Rescate en el bosque",
		"summary": "Los animales huyen del fuego y algunos han quedado atrapados al este.",
		"objectives": [
			{"id": "talk_lucia", "text": "Habla con la Dra. Lucía, investigadora", "target": 1},
			{"id": "rescue", "text": "Guía a los animales atrapados hasta el refugio", "target": 3},
		],
		"reward": {"xp": 200},
	},
	"recuperar": {
		"title": "Recuperar la naturaleza",
		"summary": "Con el fuego controlado, hay que devolver la vegetación al suelo quemado.",
		"objectives": [
			{"id": "put_out_b", "text": "Apaga los focos del este", "target": 1},
			{"id": "seeds", "text": "Recoge semillas de especies nativas", "target": 6},
			{"id": "sprouts", "text": "Planta brotes en todo el suelo quemado", "target": 1},
		],
		"reward": {"xp": 200},
	},
	"futuro": {
		"title": "El futuro del bosque",
		"summary": "La Dra. Lucía quiere decidir contigo cómo proteger el bosque a partir de ahora.",
		"objectives": [
			{"id": "decide", "text": "Decide con la Dra. Lucía cómo proteger el bosque", "target": 1},
		],
		"reward": {"xp": 300},
	},
}

var _state: Dictionary = {}   # id -> {"done": bool, "progress": {objetivo: int}}

func reset() -> void:
	_state.clear()
	changed.emit()

func is_started(id: String) -> bool:
	return _state.has(id)

func is_done(id: String) -> bool:
	if not _state.has(id):
		return false
	var entry: Dictionary = _state[id]
	return bool(entry["done"])

func is_active(id: String) -> bool:
	return is_started(id) and not is_done(id)

func get_title(id: String) -> String:
	return str(DEFS[id]["title"]) if DEFS.has(id) else ""

func get_summary(id: String) -> String:
	return str(DEFS[id]["summary"]) if DEFS.has(id) else ""

func target(id: String, objective: String) -> int:
	if not DEFS.has(id):
		return 0
	for item in DEFS[id]["objectives"]:
		if str(item["id"]) == objective:
			return int(item["target"])
	return 0

func progress(id: String, objective: String) -> int:
	if not _state.has(id):
		return 0
	var entry: Dictionary = _state[id]
	var values: Dictionary = entry["progress"]
	return int(values.get(objective, 0))

func objective_done(id: String, objective: String) -> bool:
	return progress(id, objective) >= target(id, objective)

## Lista de objetivos con su estado: [{text, done, progress, target}].
func objectives(id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if not DEFS.has(id):
		return result
	for item in DEFS[id]["objectives"]:
		var objective_id := str(item["id"])
		result.append({
			"text": str(item["text"]),
			"done": objective_done(id, objective_id),
			"progress": progress(id, objective_id),
			"target": int(item["target"]),
		})
	return result

func start(id: String) -> void:
	if _state.has(id) or not DEFS.has(id):
		return
	var values := {}
	for item in DEFS[id]["objectives"]:
		values[str(item["id"])] = 0
	_state[id] = {"done": false, "progress": values}
	GameState.post_message("Nueva misión: %s" % get_title(id))
	Sound.play("quest_start")
	quest_started.emit(id)
	changed.emit()

func add_progress(id: String, objective: String, amount: int = 1) -> void:
	set_progress(id, objective, progress(id, objective) + amount)

func set_progress(id: String, objective: String, value: int) -> void:
	if not is_active(id):
		return
	var limit := target(id, objective)
	var clamped := clampi(value, 0, limit)
	var entry: Dictionary = _state[id]
	var values: Dictionary = entry["progress"]
	if int(values.get(objective, 0)) == clamped:
		return
	values[objective] = clamped
	if clamped >= limit:
		GameState.post_message("Objetivo cumplido")
		if not _all_done(id):
			Sound.play("objective")
	changed.emit()
	_check_complete(id)

func _all_done(id: String) -> bool:
	for item in objectives(id):
		if not bool(item["done"]):
			return false
	return true

func _check_complete(id: String) -> void:
	if not _all_done(id):
		return
	var entry: Dictionary = _state[id]
	entry["done"] = true
	var reward: Dictionary = DEFS[id]["reward"]
	var xp := int(reward.get("xp", 0))
	if xp > 0:
		GameState.add_stat("xp", xp)
	var water := int(reward.get("water", 0))
	if water > 0:
		GameState.add_resource("water", water)
	GameState.post_message("Misión completada: %s (+%d puntos)" % [get_title(id), xp])
	Sound.play("quest_complete")
	changed.emit()
	quest_completed.emit(id)

# --- Guardado ----------------------------------------------------------------

func export_data() -> Dictionary:
	return _state.duplicate(true)

func import_data(data: Dictionary) -> void:
	_state.clear()
	for key in data:
		var entry: Dictionary = data[key]
		var values: Dictionary = entry.get("progress", {})
		var restored := {}
		for objective in values:
			restored[str(objective)] = int(values[objective])
		_state[str(key)] = {"done": bool(entry.get("done", false)), "progress": restored}
