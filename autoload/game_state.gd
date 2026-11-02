extends Node
## Estado global de la partida: vida, resistencia, recursos, estadísticas, herramientas y monedas.
## Autoload "GameState". No depende de ninguna otra escena.

signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal resource_changed(id: String, amount: int)
signal coins_changed(amount: int)
signal tool_changed(id: String, count: int)
signal message_posted(text: String)
signal stat_changed(id: String, value: int)
signal player_died
signal region_changed(region_id: String)

const MAX_HEALTH := 100.0
const MAX_STAMINA := 100.0
const RESOURCE_LIMITS := {
	"water": 5,
	"water_large": 10,  # cantimplora grande
	"seed": 20,
	"seed_rare": 5,
	"soil_sample": 5,
	"supply_box": 3,
}

# Herramientas: id -> usos restantes (-1 = infinito)
const TOOL_MAX_USES := {
	"extinguisher": 5,
	"medkit": 3,
	"lantern": -1,
	"radio_pro": -1,
	"radio_com": -1,
	"fire_suit": -1,
	"axe": -1,
	"shovel": -1,
	"backpack_large": -1,
	"detector_calor": 8,
	"kit_reparacion": 2,
	"botiquin_animal": 4,
}

var coins := 0
var tools: Dictionary = {}      # id -> usos restantes
var current_region := "frontera"

var health := MAX_HEALTH
var stamina := MAX_STAMINA
var resources: Dictionary = {}   # id (String) -> cantidad (int)
var stats: Dictionary = {}       # estadísticas para la pantalla de victoria
var flags: Dictionary = {}       # banderas de historia/misión

func _enter_tree() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E])
	_add_key_action("action", [KEY_SPACE])
	_add_key_action("run", [KEY_SHIFT])
	_add_key_action("pause", [KEY_ESCAPE])
	_add_key_action("restart", [KEY_R])
	_add_key_action("journal", [KEY_J])
	_add_key_action("inventory", [KEY_I])
	_add_key_action("map", [KEY_M])

func reset() -> void:
	health = MAX_HEALTH
	stamina = MAX_STAMINA
	resources.clear()
	stats.clear()
	flags.clear()
	coins = 0
	tools.clear()
	current_region = "frontera"
	health_changed.emit(health, MAX_HEALTH)
	stamina_changed.emit(stamina, MAX_STAMINA)

func add_coins(amount: int) -> void:
	coins = max(0, coins + amount)
	coins_changed.emit(coins)

func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	return true

func add_tool(id: String) -> void:
	var max_uses: int = int(TOOL_MAX_USES.get(id, 1))
	tools[id] = max_uses
	tool_changed.emit(id, max_uses)
	post_message("Herramienta obtenida: %s" % id.replace("_", " ").capitalize())

func remove_tool(id: String) -> void:
	tools.erase(id)
	tool_changed.emit(id, 0)

func has_tool(id: String) -> bool:
	return tools.has(id) and int(tools.get(id, 0)) != 0

func use_tool(id: String) -> bool:
	if not has_tool(id):
		return false
	var uses: int = int(tools.get(id, 0))
	if uses < 0:
		return true  # infinito
	uses -= 1
	if uses <= 0:
		tools.erase(id)
		tool_changed.emit(id, 0)
	else:
		tools[id] = uses
		tool_changed.emit(id, uses)
	return true

func fire_protection() -> float:
	## Reducción de daño por fuego (0.0 = sin protección, 0.7 = traje ignífugo).
	return 0.7 if has_tool("fire_suit") else 0.0

func set_region(region_id: String) -> void:
	if current_region != region_id:
		current_region = region_id
		region_changed.emit(region_id)

func get_water_limit() -> int:
	## Limite de agua: 10 con mochila grande, 5 por defecto.
	return 10 if has_tool("backpack_large") else 5


func post_message(text: String) -> void:
	message_posted.emit(text)

func damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(0.0, health - amount)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0.0:
		player_died.emit()

func heal(amount: float) -> void:
	health = minf(MAX_HEALTH, health + amount)
	health_changed.emit(health, MAX_HEALTH)

func change_stamina(delta_value: float) -> void:
	var previous := stamina
	stamina = clampf(stamina + delta_value, 0.0, MAX_STAMINA)
	if not is_equal_approx(previous, stamina):
		stamina_changed.emit(stamina, MAX_STAMINA)

## Devuelve cuántas unidades se añadieron realmente (respeta el límite del recurso).
func add_resource(id: String, amount: int = 1) -> int:
	var limit: int = int(RESOURCE_LIMITS.get(id, 999999))
	var before: int = get_resource(id)
	var after: int = mini(limit, before + amount)
	resources[id] = after
	if after != before:
		resource_changed.emit(id, after)
	return after - before

## Devuelve true si había suficiente y lo descontó.
func spend_resource(id: String, amount: int = 1) -> bool:
	if get_resource(id) < amount:
		return false
	resources[id] = get_resource(id) - amount
	resource_changed.emit(id, resources[id])
	return true

func get_resource(id: String) -> int:
	return int(resources.get(id, 0))

func add_stat(id: String, amount: int = 1) -> void:
	stats[id] = get_stat(id) + amount
	stat_changed.emit(id, int(stats[id]))

func get_stat(id: String) -> int:
	return int(stats.get(id, 0))

# --- Guardado ----------------------------------------------------------------

func export_data() -> Dictionary:
	return {
		"health": health,
		"stamina": stamina,
		"resources": resources.duplicate(),
		"stats": stats.duplicate(),
		"flags": flags.duplicate(),
		"coins": coins,
		"tools": tools.duplicate(),
		"current_region": current_region,
	}

func import_data(data: Dictionary) -> void:
	health = float(data.get("health", MAX_HEALTH))
	stamina = float(data.get("stamina", MAX_STAMINA))
	resources.clear()
	stats.clear()
	var saved_resources: Dictionary = data.get("resources", {})
	for key in saved_resources:
		resources[str(key)] = int(saved_resources[key])
	var saved_stats: Dictionary = data.get("stats", {})
	for key in saved_stats:
		stats[str(key)] = int(saved_stats[key])
	flags.clear()
	var saved_flags: Dictionary = data.get("flags", {})
	for key in saved_flags:
		flags[str(key)] = saved_flags[key]
	coins = int(data.get("coins", 0))
	tools.clear()
	var saved_tools: Dictionary = data.get("tools", {})
	for key in saved_tools:
		tools[str(key)] = int(saved_tools[key])
	current_region = str(data.get("current_region", "frontera"))
	health_changed.emit(health, MAX_HEALTH)
	stamina_changed.emit(stamina, MAX_STAMINA)
	for key in resources:
		resource_changed.emit(str(key), int(resources[key]))
	coins_changed.emit(coins)

func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action_name, event)
