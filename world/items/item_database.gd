class_name ItemDatabase
extends RefCounted
## Base de datos de todos los items del juego: herramientas, suministros y objetos especiales.

const ITEMS := {
	"extinguisher": {
		"name": "Extintor", "desc": "Apaga focos al instante. 5 usos.",
		"price": 80, "category": "tool", "icon": "extinguisher",
	},
	"medkit": {
		"name": "Botiquin", "desc": "Restaura 50 puntos de vida. 3 usos.",
		"price": 60, "category": "tool", "icon": "medkit",
	},
	"lantern": {
		"name": "Linterna", "desc": "Ilumina zonas oscuras. Uso ilimitado.",
		"price": 40, "category": "tool", "icon": "lantern",
	},
	"radio_pro": {
		"name": "Radio profesional", "desc": "Coordina con otros equipos.",
		"price": 100, "category": "tool", "icon": "radio",
	},
	"fire_suit": {
		"name": "Traje ignifugo", "desc": "Reduce dano del fuego 70%. Uso ilimitado.",
		"price": 150, "category": "tool", "icon": "fire_suit",
	},
	"axe": {
		"name": "Hacha forestal", "desc": "Abre caminos y cortafuegos.",
		"price": 70, "category": "tool", "icon": "axe",
	},
	"shovel": {
		"name": "Pala", "desc": "Cubre focos con tierra.",
		"price": 50, "category": "tool", "icon": "shovel",
	},
	"backpack_large": {
		"name": "Mochila grande", "desc": "Capacidad de agua maxima x2.",
		"price": 90, "category": "tool", "icon": "backpack",
	},
	"detector_calor": {
		"name": "Detector de calor", "desc": "Detecta focos a traves del humo y senala zonas secas. 8 usos.",
		"price": 75, "category": "tool", "icon": "detector",
	},
	"kit_reparacion": {
		"name": "Kit de reparacion", "desc": "Repara puentes, torres y estructuras danadas. 2 usos.",
		"price": 85, "category": "tool", "icon": "repair",
	},
	"botiquin_animal": {
		"name": "Botiquin animal", "desc": "Cura heridas a animales rescatados. 4 usos.",
		"price": 70, "category": "tool", "icon": "medkit_animal",
	},
	"radio_com": {
		"name": "Equipo de comunicacion", "desc": "Recibe coordenadas de emergencia y actualizaciones de mision.",
		"price": 110, "category": "tool", "icon": "radio_com",
	},
	"water": {
		"name": "Agua", "desc": "Anade 3 unidades de agua.",
		"price": 15, "category": "supply", "icon": "water",
		"resource_id": "water", "amount": 3,
	},
	"seed": {
		"name": "Semillas nativas", "desc": "Pack de 5 semillas.",
		"price": 20, "category": "supply", "icon": "seed",
		"resource_id": "seed", "amount": 5,
	},
	"supply_box": {
		"name": "Caja de suministros", "desc": "Para comunidades necesitadas.",
		"price": 30, "category": "supply", "icon": "box",
		"resource_id": "supply_box", "amount": 1,
	},
}

static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})

static func get_name(id: String) -> String:
	return str(ITEMS.get(id, {}).get("name", id))

static func get_price(id: String) -> int:
	return int(ITEMS.get(id, {}).get("price", 0))

static func get_category(id: String) -> String:
	return str(ITEMS.get(id, {}).get("category", ""))

static func is_tool(id: String) -> bool:
	return get_category(id) == "tool"

static func all_ids() -> Array[String]:
	var result: Array[String] = []
	for key in ITEMS:
		result.append(str(key))
	return result