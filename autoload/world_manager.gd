extends Node
## Fuente única de verdad para regiones, coordenadas globales y descubrimientos.
## Autoload "WorldManager".

signal region_discovered(region_id: String)
signal regions_changed
signal location_discovered(location_id: String)
signal player_position_updated(global_position: Vector2, region_id: String)

const REGION_ORDER: Array[String] = [
	"frontera",
	"sendero",
	"pueblo",
	"montanhas",
	"llanura",
]

## Las coordenadas globales preservan la distribución y puntos de interés del mapa anterior.
## Solo Frontera tiene una escena jugable dentro del proyecto importado.
const REGIONS := {
	"frontera": {
		"name": "Zona de Frontera",
		"scene": "res://world/regions/frontera/frontera.tscn",
		"description": "Bosque inicial con sendero, estanque y refugio.",
		"origin": Vector2(0.0, 0.0),
		"size": Vector2(2400.0, 1400.0),
		"map_color": Color("466b3e"),
		"entry_location": "player_spawn",
	},
	"sendero": {
		"name": "Sendero de la Quebrada",
		"description": "Bosque denso junto al río y las laderas del norte.",
		"origin": Vector2(4200.0, 1400.0),
		"size": Vector2(1600.0, 1000.0),
		"map_color": Color("557d58"),
		"entry_location": "sendero_end",
	},
	"pueblo": {
		"name": "Pueblo El Pinar",
		"description": "Pueblo con tienda y estación de bomberos.",
		"origin": Vector2(2400.0, 1400.0),
		"size": Vector2(1200.0, 800.0),
		"map_color": Color("8b7658"),
		"entry_location": "pueblo_center",
	},
	"montanhas": {
		"name": "Sierras del Norte",
		"description": "Zona montañosa con fauna en peligro y laderas expuestas.",
		"origin": Vector2(0.0, 1400.0),
		"size": Vector2(1800.0, 1600.0),
		"map_color": Color("747b72"),
		"entry_location": "montanhas_start",
	},
	"llanura": {
		"name": "Llanura Quemada",
		"description": "Terreno afectado por el fuego, destinado a la restauración.",
		"origin": Vector2(2400.0, 0.0),
		"size": Vector2(2000.0, 1200.0),
		"map_color": Color("9a7543"),
		"entry_location": "llanura_start",
	},
}

const LOCATION_DEFS := {
	"player_spawn": {
		"name": "Punto de inicio",
		"region": "frontera",
		"local_position": Vector2(160.0, 700.0),
		"type": "spawn",
	},
	"refuge": {
		"name": "Refugio de emergencia",
		"region": "frontera",
		"local_position": Vector2(1440.0, 880.0),
		"type": "safe_zone",
		"quest_id": "rescate",
	},
	"pond": {
		"name": "Pozo de agua",
		"region": "frontera",
		"local_position": Vector2(330.0, 540.0),
		"type": "resource",
	},
	"elena": {
		"name": "Elena, guardabosques",
		"region": "frontera",
		"local_position": Vector2(250.0, 668.0),
		"type": "npc",
		"quest_id": "bosque_en_peligro",
	},
	"mateo": {
		"name": "Mateo, vecino",
		"region": "frontera",
		"local_position": Vector2(470.0, 600.0),
		"type": "npc",
	},
	"tomas": {
		"name": "Tomás, bombero forestal",
		"region": "frontera",
		"local_position": Vector2(1010.0, 690.0),
		"type": "npc",
		"quest_id": "primeras_llamas",
	},
	"lucia": {
		"name": "Dra. Lucía",
		"region": "frontera",
		"local_position": Vector2(1400.0, 560.0),
		"type": "npc",
		"quest_id": "futuro",
	},
	"clue_fogata": {
		"name": "Restos de fogata",
		"region": "frontera",
		"local_position": Vector2(600.0, 780.0),
		"type": "clue",
		"quest_id": "bosque_en_peligro",
	},
	"clue_colilla": {
		"name": "Colilla",
		"region": "frontera",
		"local_position": Vector2(735.0, 700.0),
		"type": "clue",
		"quest_id": "bosque_en_peligro",
	},
	"clue_hierba": {
		"name": "Hierba seca",
		"region": "frontera",
		"local_position": Vector2(860.0, 590.0),
		"type": "clue",
		"quest_id": "bosque_en_peligro",
	},
	"zone_a": {
		"name": "Foco junto al sendero",
		"region": "frontera",
		"local_position": Vector2(1180.0, 650.0),
		"type": "fire_zone",
		"quest_id": "primeras_llamas",
	},
	"zone_b": {
		"name": "Focos del este",
		"region": "frontera",
		"local_position": Vector2(1760.0, 520.0),
		"type": "fire_zone",
		"quest_id": "recuperar",
	},
	"rabbit_rescue": {
		"name": "Conejo atrapado",
		"region": "frontera",
		"local_position": Vector2(1650.0, 420.0),
		"type": "animal",
		"quest_id": "rescate",
	},
	"squirrel_rescue": {
		"name": "Ardilla atrapada",
		"region": "frontera",
		"local_position": Vector2(1950.0, 650.0),
		"type": "animal",
		"quest_id": "rescate",
	},
	"deer_rescue": {
		"name": "Venado atrapado",
		"region": "frontera",
		"local_position": Vector2(1860.0, 410.0),
		"type": "animal",
		"quest_id": "rescate",
	},
	"llanura_start": {
		"name": "Entrada a la Llanura Quemada",
		"region": "llanura",
		"local_position": Vector2(0.0, 600.0),
		"type": "entrance",
		"quest_id": "recuperar",
	},
	"montanhas_start": {
		"name": "Entrada a las Sierras del Norte",
		"region": "montanhas",
		"local_position": Vector2(900.0, 0.0),
		"type": "entrance",
		"quest_id": "rescate",
	},
	"pueblo_center": {
		"name": "Centro de Pueblo El Pinar",
		"region": "pueblo",
		"local_position": Vector2(400.0, 200.0),
		"type": "town_center",
		"quest_id": "primeras_llamas",
	},
	"sendero_end": {
		"name": "Final del Sendero de la Quebrada",
		"region": "sendero",
		"local_position": Vector2(800.0, 500.0),
		"type": "exit",
		"quest_id": "bosque_en_peligro",
	},
}

const QUEST_REGION_UNLOCKS := {
	"bosque_en_peligro": "sendero",
	"primeras_llamas": "pueblo",
	"rescate": "montanhas",
	"recuperar": "llanura",
}
const LOCATION_DISCOVERY_RADIUS := 110.0

var discovered_regions: Array[String] = ["frontera"]
var discovered_locations: Array[String] = ["player_spawn", "refuge", "pond"]
var pending_spawn_region := ""
var player_region := "frontera"
var player_local_position := Vector2.ZERO
var _has_player_position := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Quests.quest_completed.connect(_on_quest_completed)


func reset_progress() -> void:
	discovered_regions = ["frontera"]
	discovered_locations = ["player_spawn", "refuge", "pond"]
	player_region = "frontera"
	player_local_position = Vector2.ZERO
	_has_player_position = false
	pending_spawn_region = ""
	regions_changed.emit()


func get_regions() -> Dictionary:
	return REGIONS


func get_region_ids() -> Array[String]:
	return REGION_ORDER.duplicate()


func get_region_info(region_id: String) -> Dictionary:
	return REGIONS.get(region_id, {})


func get_region_name(region_id: String) -> String:
	return str(REGIONS.get(region_id, {}).get("name", region_id))


func get_region_bounds(region_id: String) -> Rect2:
	var region: Dictionary = REGIONS.get(region_id, {})
	if region.is_empty():
		return Rect2()
	return Rect2(region.get("origin", Vector2.ZERO), region.get("size", Vector2.ZERO))


func get_world_bounds() -> Rect2:
	var bounds := Rect2()
	var first_region := true
	for region_id in REGION_ORDER:
		var region_bounds := get_region_bounds(region_id)
		if first_region:
			bounds = region_bounds
			first_region = false
		else:
			bounds = bounds.merge(region_bounds)
	return bounds


func get_world_size() -> Vector2:
	return get_world_bounds().size


func to_global_map_position(region_id: String, local_position: Vector2) -> Vector2:
	var region: Dictionary = REGIONS.get(region_id, {})
	return region.get("origin", Vector2.ZERO) + local_position


func update_player_position(region_id: String, local_position: Vector2) -> void:
	if not REGIONS.has(region_id):
		return
	player_region = region_id
	player_local_position = local_position
	_has_player_position = true
	if GameState.current_region != region_id:
		GameState.set_region(region_id)
	var global_position := to_global_map_position(region_id, local_position)
	_discover_nearby_locations(region_id, local_position)
	player_position_updated.emit(global_position, region_id)


func get_player_region() -> String:
	return player_region


func get_player_position() -> Vector2:
	return to_global_map_position(player_region, player_local_position)


func has_player_position() -> bool:
	return _has_player_position


func is_discovered(region_id: String) -> bool:
	return region_id in discovered_regions


func discover_region(region_id: String, notify: bool = true) -> void:
	if not REGIONS.has(region_id) or is_discovered(region_id):
		return
	discovered_regions.append(region_id)
	var entry_id := str(REGIONS[region_id].get("entry_location", ""))
	if entry_id != "":
		discover_location(entry_id)
	region_discovered.emit(region_id)
	regions_changed.emit()
	if notify:
		GameState.post_message("Nueva zona descubierta: %s" % get_region_name(region_id))


func is_location_discovered(location_id: String) -> bool:
	return location_id in discovered_locations


func discover_location(location_id: String) -> void:
	if not LOCATION_DEFS.has(location_id) or is_location_discovered(location_id):
		return
	discovered_locations.append(location_id)
	location_discovered.emit(location_id)
	regions_changed.emit()
	GameState.post_message("Ubicación descubierta: %s" % LOCATION_DEFS[location_id]["name"])


func get_location_info(location_id: String) -> Dictionary:
	if not LOCATION_DEFS.has(location_id):
		return {}
	var info: Dictionary = LOCATION_DEFS[location_id].duplicate(true)
	var region_id := str(info.get("region", "frontera"))
	var global_position := to_global_map_position(region_id, info.get("local_position", Vector2.ZERO))
	info["id"] = location_id
	info["position"] = global_position
	info["global_position"] = global_position
	info["discovered"] = is_location_discovered(location_id)
	info["region_discovered"] = is_discovered(region_id)
	var quest_id := str(info.get("quest_id", ""))
	info["active_quest"] = quest_id != "" and Quests.is_active(quest_id)
	return info


func get_map_markers() -> Array[Dictionary]:
	var markers: Array[Dictionary] = []
	for location_id in LOCATION_DEFS:
		markers.append(get_location_info(str(location_id)))
	return markers


## Alias legado conservado para los scripts del minimapa importado.
func get_map_markets() -> Array[Dictionary]:
	return get_map_markers()


func get_scene_path(region_id: String) -> String:
	return str(REGIONS.get(region_id, {}).get("scene", ""))


func can_travel_to_region(region_id: String) -> bool:
	var scene_path := get_scene_path(region_id)
	return scene_path != "" and ResourceLoader.exists(scene_path)


func go_to_region(region_id: String) -> void:
	if not REGIONS.has(region_id):
		return
	if not is_discovered(region_id):
		GameState.post_message("Esa región todavía no se ha descubierto.")
		return
	if not can_travel_to_region(region_id):
		GameState.post_message("La escena jugable de %s aún no está incluida." % get_region_name(region_id))
		return
	GameState.set_region(region_id)
	pending_spawn_region = region_id
	Transition.go_to(get_scene_path(region_id))


func set_player_region(region_id: String) -> void:
	if not REGIONS.has(region_id):
		return
	player_region = region_id
	GameState.set_region(region_id)


func all_region_ids() -> Array[String]:
	return get_region_ids()


func export_data() -> Dictionary:
	return {
		"discovered_regions": discovered_regions.duplicate(),
		"discovered_locations": discovered_locations.duplicate(),
		"player_region": player_region,
		"player_local_position": [player_local_position.x, player_local_position.y],
	}


func import_data(data: Dictionary) -> void:
	discovered_regions.clear()
	var region_data: Array = data.get("discovered_regions", data.get("discovered", ["frontera"]))
	for value in region_data:
		var region_id := str(value)
		if REGIONS.has(region_id) and not region_id in discovered_regions:
			discovered_regions.append(region_id)
	if not "frontera" in discovered_regions:
		discovered_regions.push_front("frontera")

	discovered_locations.clear()
	var location_data: Array = data.get("discovered_locations", ["player_spawn", "refuge", "pond"])
	for value in location_data:
		var location_id := str(value)
		if LOCATION_DEFS.has(location_id) and not location_id in discovered_locations:
			discovered_locations.append(location_id)

	player_region = str(data.get("player_region", data.get("current_region", GameState.current_region)))
	if not REGIONS.has(player_region):
		player_region = "frontera"
	var saved_position: Variant = data.get("player_local_position", [])
	if saved_position is Array and saved_position.size() == 2:
		player_local_position = Vector2(float(saved_position[0]), float(saved_position[1]))
		_has_player_position = true
	else:
		player_local_position = Vector2.ZERO
		_has_player_position = false

	_sync_completed_quest_discoveries()
	regions_changed.emit()


func _sync_completed_quest_discoveries() -> void:
	for quest_id in QUEST_REGION_UNLOCKS:
		if Quests.is_done(str(quest_id)):
			var region_id := str(QUEST_REGION_UNLOCKS[quest_id])
			if not is_discovered(region_id):
				discovered_regions.append(region_id)
				var entry_id := str(REGIONS[region_id].get("entry_location", ""))
				if entry_id != "" and not is_location_discovered(entry_id):
					discovered_locations.append(entry_id)


func _on_quest_completed(quest_id: String) -> void:
	if QUEST_REGION_UNLOCKS.has(quest_id):
		discover_region(str(QUEST_REGION_UNLOCKS[quest_id]))


func _discover_nearby_locations(region_id: String, local_position: Vector2) -> void:
	for location_id in LOCATION_DEFS:
		var info: Dictionary = LOCATION_DEFS[location_id]
		if str(info.get("region", "")) != region_id or is_location_discovered(str(location_id)):
			continue
		var target: Vector2 = info.get("local_position", Vector2.ZERO)
		if local_position.distance_to(target) <= LOCATION_DISCOVERY_RADIUS:
			discover_location(str(location_id))
