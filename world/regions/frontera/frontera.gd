extends Node2D
## Región 1: Zona de Frontera. Une los sistemas: jugador, fuego, recursos, NPC, animales,
## misiones, diálogos, HUD, menús y guardado.
## El mundo se renderiza a 640x360 dentro de un SubViewport y se escala con filtro "nearest"
## (aspecto pixel art); la interfaz se dibuja aparte a resolución completa.

const WORLD_RECT := Rect2(0.0, 0.0, 2400.0, 1400.0)
const VIEW_SIZE := Vector2i(640, 360)
const SPAWN := Vector2(160.0, 700.0)
const POND_CENTER := Vector2(330.0, 540.0)
const REFUGE_CENTER := Vector2(1440.0, 880.0)
const ZONE_A_CENTER := Vector2(1180.0, 650.0)
const ZONE_B_CENTER := Vector2(1760.0, 520.0)
const MINIMAP_SCENE: PackedScene = preload("res://scenes/minimap.tscn")

const ENDING_TEXTS := {
	"reforest": "Elegiste reforestar con especies nativas: en pocos años el bosque recuperará su biodiversidad, aunque tardará en volver a ser denso.",
	"prevent": "Elegiste abrir cortafuegos y reforzar la vigilancia: los incendios futuros serán pequeños y controlables, aunque el bosque dañado se recuperará más despacio.",
}

var path_points: Array[Vector2] = [
	Vector2(40.0, 700.0), Vector2(500.0, 720.0), Vector2(800.0, 650.0),
	Vector2(1180.0, 640.0), Vector2(1500.0, 600.0), Vector2(1800.0, 520.0),
	Vector2(2360.0, 470.0)]

var _world: Node2D
var _entities: Node2D
var _player: Player
var _hud: HudView
var _pause_menu: PauseMenu
var _end_screen: EndScreen
var _overlay_layer: CanvasLayer
var _minimap: Control
var _fire_manager: FireManager
var _story: FronteraStory
var _refuge: Refuge
var _b_timer: Timer
var _defeat_timer: Timer
var _victory_timer: Timer
var _audio_timer: Timer
var _fire_cells: Array[FireCell] = []
var _pickups: Array[Pickup] = []
var _clues: Array[Clue] = []
var _animals: Array[Animal] = []
var _npc_list: Array[Npc] = []
var _reserved: Array[Vector2] = []
var _fire_a_started := false
var _fire_b_started := false
var _manual_ignition := false
var _finished := false
var _dead := false
var _elapsed := 0.0
var _ending_id := ""
var _victory_shown := false

func _ready() -> void:
	GameState.reset()
	Quests.reset()
	WorldManager.reset_progress()
	_build_view()
	_build_ambient()
	_build_ground()
	_entities = Node2D.new()
	_entities.y_sort_enabled = true
	_world.add_child(_entities)
	_build_boundaries()
	_reserved.append(SPAWN)
	_build_fire_zones()
	_build_pickups()
	_build_npcs()
	_build_clues()
	_build_animals()
	_build_props()
	_build_decor()
	_build_player()
	_build_ui()
	_build_fire_manager()
	_build_story()
	if SaveSystem.pending_load and SaveSystem.has_save():
		_apply_save(SaveSystem.read())
	else:
		GameState.add_resource("water", 3)
		_story.begin_new_game()
		save_progress()
	SaveSystem.pending_load = false
	WorldManager.regions_changed.connect(save_progress)
	WorldManager.location_discovered.connect(_on_map_location_discovered)
	WorldManager.update_player_position("frontera", _player.position)
	_story.refresh()
	_refresh_hud_quest()
	Quests.changed.connect(_refresh_hud_quest)
	Quests.changed.connect(save_progress)
	Sound.start_loop("forest", -8.0)
	_update_audio()

func _exit_tree() -> void:
	Sound.stop_loop("forest")
	Sound.stop_loop("fire")

func _process(delta: float) -> void:
	if is_instance_valid(_player):
		WorldManager.update_player_position("frontera", _player.position)
	if _dead:
		return
	_elapsed += delta
	if _fire_a_started:
		return
	if _player.global_position.distance_to(ZONE_A_CENTER) < 330.0:
		_fire_a_started = true
		_manual_ignition = true
		_fire_manager.ignite_zone("A", 1)
		_manual_ignition = false
		GameState.post_message("¡Humo al este! Un foco se ha encendido junto al sendero.")
		_story.on_fire_a_started()

func _unhandled_input(event: InputEvent) -> void:
	if _dead or _pause_menu.visible or Dialogue.is_open:
		return
	if event.is_action_pressed("pause"):
		_pause_menu.toggle()
	elif event.is_action_pressed("journal"):
		_open_overlay(JournalPanel.new())
	elif event.is_action_pressed("inventory"):
		_open_overlay(InventoryPanel.new())
	elif event.is_action_pressed("map"):
		_open_world_map()

func _open_world_map() -> void:
	get_tree().paused = true
	var wm := WorldMap.new()
	_overlay_layer.add_child(wm)

func _open_overlay(panel: OverlayPanel) -> void:
	get_tree().paused = true
	_overlay_layer.add_child(panel)
	panel.closed.connect(_on_overlay_closed)

func _on_overlay_closed() -> void:
	get_tree().paused = false

# --- Construcción del mundo ----------------------------------------------------

func _build_view() -> void:
	var viewport := SubViewport.new()
	viewport.size = VIEW_SIZE
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	_world = Node2D.new()
	viewport.add_child(_world)
	var layer := CanvasLayer.new()
	layer.layer = -5
	add_child(layer)
	var screen := TextureRect.new()
	screen.texture = viewport.get_texture()
	screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	screen.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _build_ambient() -> void:
	var tint := CanvasModulate.new()
	tint.color = Color(0.92, 0.9, 0.94)
	_world.add_child(tint)

func _build_ground() -> void:
	var ground := ForestGround.new()
	ground.world_rect = WORLD_RECT
	ground.path_points = path_points
	ground.pond_center = POND_CENTER
	_world.add_child(ground)
	_refuge = Refuge.new()
	_refuge.position = REFUGE_CENTER
	_world.add_child(_refuge)
	_reserved.append(REFUGE_CENTER)

func _build_boundaries() -> void:
	var body := StaticBody2D.new()
	_world.add_child(body)
	var t := 80.0
	var w := WORLD_RECT.size.x
	var h := WORLD_RECT.size.y
	var walls: Array[Rect2] = [
		Rect2(-t, -t, w + 2.0 * t, t), Rect2(-t, h, w + 2.0 * t, t),
		Rect2(-t, 0.0, t, h), Rect2(w, 0.0, t, h)]
	for wall in walls:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = wall.size
		shape.shape = rect
		shape.position = wall.get_center()
		body.add_child(shape)

func _build_fire_zones() -> void:
	_add_fire_zone("A", ZONE_A_CENTER, PackedVector2Array([
		Vector2(-52.0, -22.0), Vector2(14.0, -42.0), Vector2(36.0, 28.0), Vector2(-32.0, 50.0)]))
	_add_fire_zone("B", ZONE_B_CENTER, PackedVector2Array([
		Vector2(-42.0, -22.0), Vector2(28.0, -32.0), Vector2(8.0, 36.0)]))

func _add_fire_zone(zone: String, center: Vector2, offsets: PackedVector2Array) -> void:
	for offset in offsets:
		var cell := FireCell.new()
		cell.zone = zone
		cell.position = center + offset
		_entities.add_child(cell)
		_fire_cells.append(cell)
		_reserved.append(cell.position)

func _build_pickups() -> void:
	var refill := "E · Rellenar cantimplora"
	_add_pickup("water", 5, "Agua", POND_CENTER + Vector2(0.0, 72.0), false, "E · Llenar cantimplora (estanque)")
	_add_pickup("water", 5, "Agua", Vector2(1040.0, 745.0), false, refill + " (barril)")
	_add_pickup("water", 5, "Agua", Vector2(1560.0, 690.0), false, refill + " (barril)")
	var seeds: Array[Vector2] = [
		Vector2(430.0, 740.0), Vector2(640.0, 590.0), Vector2(760.0, 760.0), Vector2(940.0, 560.0),
		Vector2(1330.0, 720.0), Vector2(1480.0, 520.0), Vector2(1620.0, 620.0), Vector2(1900.0, 570.0)]
	for seed_position in seeds:
		_add_pickup("seed", 1, "Semilla", seed_position, true, "")

func _add_pickup(id: String, amount: int, label: String, where: Vector2, one_shot: bool, prompt: String) -> void:
	var pickup := Pickup.new()
	pickup.resource_id = id
	pickup.amount = amount
	pickup.label = label
	pickup.one_shot = one_shot
	pickup.prompt_text = prompt
	pickup.position = where
	_entities.add_child(pickup)
	_pickups.append(pickup)
	_reserved.append(where)

func _build_npcs() -> void:
	_add_npc("elena", "Elena", "ranger", Vector2(250.0, 668.0), false)
	_add_npc("mateo", "Mateo", "villager", Vector2(470.0, 600.0), true)
	_add_npc("tomas", "Tomás", "firefighter", Vector2(1010.0, 690.0), false)
	_add_npc("lucia", "Dra. Lucía", "researcher", Vector2(1400.0, 560.0), true)

func _add_npc(id: String, display: String, role: String, where: Vector2, face_left: bool) -> void:
	var npc := Npc.new()
	npc.npc_id = id
	npc.display_name = display
	npc.role = role
	npc.facing_left = face_left
	npc.position = where
	_entities.add_child(npc)
	_npc_list.append(npc)
	_reserved.append(where)

func _build_clues() -> void:
	_add_clue("fogata", "campfire", "restos de fogata", Vector2(600.0, 780.0),
		"Restos de una fogata. Las brasas aún están tibias: alguien se marchó sin apagarla del todo. Una fogata se apaga con agua, se remueve y se comprueba con la mano hasta que esté fría.")
	_add_clue("colilla", "cigarette", "una colilla", Vector2(735.0, 700.0),
		"Una colilla junto a la hierba seca. Nunca se deben tirar colillas en el monte: un cigarrillo mal apagado puede iniciar un incendio.")
	_add_clue("hierba", "dry_grass", "hierba seca", Vector2(860.0, 590.0),
		"Hierba amarilla y quebradiza. Con la sequía, la vegetación seca es combustible: el fuego se propaga muy rápido por ella.")

func _add_clue(id: String, kind: String, title: String, where: Vector2, text: String) -> void:
	var clue := Clue.new()
	clue.clue_id = id
	clue.kind = kind
	clue.title = title
	clue.text = text
	clue.position = where
	_entities.add_child(clue)
	_clues.append(clue)
	_reserved.append(where)

func _build_animals() -> void:
	# Atrapados (misión de rescate): conejo, ardilla y venado al este.
	_add_animal(Animal.Species.RABBIT, Animal.Mode.TRAPPED, Vector2(1650.0, 420.0))
	_add_animal(Animal.Species.SQUIRREL, Animal.Mode.TRAPPED, Vector2(1950.0, 650.0))
	_add_animal(Animal.Species.DEER, Animal.Mode.TRAPPED, Vector2(1860.0, 410.0))
	# Fauna ambiental: pasea y huye del jugador que corre o del fuego.
	_add_animal(Animal.Species.RABBIT, Animal.Mode.WANDER, Vector2(300.0, 840.0))
	_add_animal(Animal.Species.RABBIT, Animal.Mode.WANDER, Vector2(1200.0, 900.0))
	_add_animal(Animal.Species.SQUIRREL, Animal.Mode.WANDER, Vector2(520.0, 470.0))
	_add_animal(Animal.Species.SQUIRREL, Animal.Mode.WANDER, Vector2(1380.0, 430.0))
	_add_animal(Animal.Species.DEER, Animal.Mode.WANDER, Vector2(1250.0, 990.0))
	_add_animal(Animal.Species.DEER, Animal.Mode.WANDER, Vector2(2100.0, 900.0))

func _add_animal(species: Animal.Species, mode: Animal.Mode, where: Vector2) -> void:
	var animal := Animal.new()
	animal.species = species
	animal.mode = mode
	animal.position = where
	animal.refuge = _refuge
	_entities.add_child(animal)
	_animals.append(animal)
	_reserved.append(where)

func _build_props() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5112026
	var placed: Array[Vector2] = []
	var attempts := 0
	while placed.size() < 150 and attempts < 3000:
		attempts += 1
		var p := Vector2(rng.randf_range(70.0, WORLD_RECT.size.x - 70.0), rng.randf_range(90.0, WORLD_RECT.size.y - 40.0))
		if Geo.distance_to_polyline(p, path_points) < 62.0:
			continue
		if p.distance_to(POND_CENTER) < 130.0 or p.distance_to(REFUGE_CENTER) < 120.0:
			continue
		if _too_close(p, _reserved, 80.0) or _too_close(p, placed, 52.0):
			continue
		placed.append(p)
		var roll := rng.randf()
		var kind: Prop.Kind = Prop.Kind.PINE
		if roll >= 0.9:
			kind = Prop.Kind.DEAD
		elif roll >= 0.8:
			kind = Prop.Kind.ROCK
		elif roll >= 0.5:
			kind = Prop.Kind.BROADLEAF
		var prop := Prop.new()
		prop.kind = kind
		prop.scale_factor = rng.randf_range(0.85, 1.2)
		prop.tone_shift = rng.randf_range(-0.08, 0.08)
		prop.position = p
		_entities.add_child(prop)

func _build_decor() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 424242
	for i in range(14):
		var angle := TAU * float(i) / 14.0
		var edge := POND_CENTER + Vector2(cos(angle) * 108.0, sin(angle) * 68.0)
		_add_decor(Decor.Kind.REEDS, edge, rng.randi_range(0, 2))
	var count := 0
	var attempts := 0
	while count < 260 and attempts < 2000:
		attempts += 1
		var p := Vector2(rng.randf_range(30.0, WORLD_RECT.size.x - 30.0), rng.randf_range(40.0, WORLD_RECT.size.y - 20.0))
		if Geo.distance_to_polyline(p, path_points) < 40.0:
			continue
		if p.distance_to(POND_CENTER) < 118.0 or p.distance_to(REFUGE_CENTER) < 100.0 or _too_close(p, _reserved, 34.0):
			continue
		var roll := rng.randf()
		var kind: Decor.Kind = Decor.Kind.FLOWERS
		if roll < 0.35:
			kind = Decor.Kind.BUSH
		elif roll < 0.8:
			kind = Decor.Kind.FLOWERS
		elif roll < 0.92:
			kind = Decor.Kind.MUSHROOMS
		else:
			kind = Decor.Kind.LOG
		_add_decor(kind, p, rng.randi_range(0, 2))
		count += 1

func _add_decor(kind: Decor.Kind, where: Vector2, variant: int) -> void:
	var item := Decor.new()
	item.kind = kind
	item.variant = variant
	item.position = where
	_entities.add_child(item)

func _too_close(point: Vector2, points: Array[Vector2], min_distance: float) -> bool:
	for other in points:
		if point.distance_to(other) < min_distance:
			return true
	return false

func _build_player() -> void:
	_player = Player.new()
	_player.position = SPAWN
	_entities.add_child(_player)
	_player.set_camera_limits(WORLD_RECT)
	_player.add_child(_make_ambient_particles())

func _make_ambient_particles() -> CPUParticles2D:
	var motes := CPUParticles2D.new()
	motes.position = Vector2(0.0, -30.0)
	motes.amount = 36
	motes.lifetime = 7.0
	motes.preprocess = 7.0
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(340.0, 200.0)
	motes.direction = Vector2(1.0, 0.3)
	motes.spread = 60.0
	motes.gravity = Vector2(4.0, 3.0)
	motes.initial_velocity_min = 3.0
	motes.initial_velocity_max = 10.0
	motes.scale_amount_min = 1.0
	motes.scale_amount_max = 2.0
	motes.color_ramp = Geo.ramp3(Color(1.0, 0.95, 0.7, 0.0), Color(1.0, 0.95, 0.7, 0.7), Color(1.0, 0.95, 0.7, 0.0))
	return motes

func _build_ui() -> void:
	var vignette_layer := CanvasLayer.new()
	vignette_layer.layer = 5
	add_child(vignette_layer)
	vignette_layer.add_child(_make_vignette())
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	_hud = HudView.new()
	hud_layer.add_child(_hud)
	_hud.bind_player(_player)
	_minimap = MINIMAP_SCENE.instantiate() as Control
	_minimap.position = Vector2(12.0, 150.0)
	hud_layer.add_child(_minimap)
	_overlay_layer = CanvasLayer.new()
	_overlay_layer.layer = 40
	_overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_overlay_layer)
	_pause_menu = PauseMenu.new()
	add_child(_pause_menu)
	_pause_menu.restart_requested.connect(_on_restart)
	_pause_menu.menu_requested.connect(_on_menu_from_pause)
	_end_screen = EndScreen.new()
	add_child(_end_screen)
	_end_screen.restart_requested.connect(_on_restart)
	_end_screen.checkpoint_requested.connect(_on_checkpoint)
	_end_screen.menu_requested.connect(_on_menu)
	_end_screen.continue_requested.connect(_on_continue_playing)

func _make_vignette() -> TextureRect:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, 0.0))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.55))
	gradient.add_point(0.62, Color(0.0, 0.0, 0.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.width = 256
	texture.height = 256
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

func _build_fire_manager() -> void:
	_fire_manager = FireManager.new()
	add_child(_fire_manager)
	_fire_manager.register_all()
	_fire_manager.cell_changed.connect(_on_cell_changed)
	_fire_manager.zone_cleared.connect(_on_zone_cleared)
	_b_timer = _make_timer(4.0, _on_b_timer)
	_defeat_timer = _make_timer(0.9, _on_defeat_timer)
	_victory_timer = _make_timer(2.0, _on_victory_timer)
	_audio_timer = _make_timer(0.5, _update_audio)
	_audio_timer.one_shot = false
	_audio_timer.start()

func _build_story() -> void:
	_story = FronteraStory.new()
	_story.fire_manager = _fire_manager
	add_child(_story)
	for npc in _npc_list:
		_story.bind_npc(npc)
	for clue in _clues:
		_story.bind_clue(clue)
	for animal in _animals:
		_story.bind_animal(animal)
	_story.fire_b_requested.connect(_on_fire_b_requested)
	_story.ending_reached.connect(_on_ending_reached)
	GameState.player_died.connect(_on_player_died)

func _make_timer(wait: float, callback: Callable) -> Timer:
	var timer := Timer.new()
	timer.wait_time = wait
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(callback)
	return timer

# --- Audio dinámico ------------------------------------------------------------

func _update_audio() -> void:
	if _dead or _victory_shown:
		return
	var nearest := 100000.0
	var active := 0
	for cell in _fire_cells:
		if cell.is_dangerous():
			active += 1
			nearest = minf(nearest, cell.global_position.distance_to(_player.global_position))
	var following := false
	for animal in _animals:
		if animal.mode == Animal.Mode.FOLLOW:
			following = true
	var track := "calm"
	if active > 0:
		track = "fire" if nearest < 260.0 else "tense"
	elif following:
		track = "rescue"
	Sound.play_music(track)
	var fire_db := -80.0
	if active > 0:
		fire_db = lerpf(-4.0, -40.0, clampf(nearest / 520.0, 0.0, 1.0))
	Sound.start_loop("fire", fire_db)

# --- HUD de misión -------------------------------------------------------------

func _refresh_hud_quest() -> void:
	for quest_id in Quests.ORDER:
		var id := str(quest_id)
		if not Quests.is_active(id):
			continue
		var lines: Array[String] = []
		for objective in Quests.objectives(id):
			var mark := "[x] " if bool(objective["done"]) else "[ ] "
			var suffix := ""
			if int(objective["target"]) > 1:
				suffix = " (%d/%d)" % [int(objective["progress"]), int(objective["target"])]
			lines.append(mark + str(objective["text"]) + suffix)
		_hud.quest_title = Quests.get_title(id)
		_hud.quest_lines = lines
		return
	_hud.quest_title = "Historia completada" if Quests.is_done("futuro") else "Explora la Frontera"
	_hud.quest_lines = []

# --- Guardado ------------------------------------------------------------------

func save_progress() -> void:
	if _dead:
		return
	var cell_data: Array = []
	for cell in _fire_cells:
		cell_data.append([int(cell.state), cell.health])
	var pickup_data: Array = []
	for pickup in _pickups:
		pickup_data.append(pickup.is_taken())
	var clue_data: Array = []
	for clue in _clues:
		clue_data.append(clue.is_examined())
	var animal_data: Array = []
	for animal in _animals:
		animal_data.append([int(animal.mode), animal.position.x, animal.position.y])
	var data := GameState.export_data()
	data["quests"] = Quests.export_data()
	data["player"] = [_player.position.x, _player.position.y]
	data["cells"] = cell_data
	data["pickups"] = pickup_data
	data["clues"] = clue_data
	data["animals"] = animal_data
	data["world_map"] = WorldManager.export_data()
	data["a"] = _fire_a_started
	data["b"] = _fire_b_started
	data["finished"] = _finished
	data["elapsed"] = _elapsed
	SaveSystem.write(data)


func _on_map_location_discovered(_location_id: String) -> void:
	save_progress()


func _apply_save(data: Dictionary) -> void:
	GameState.import_data(data)
	var quest_data: Dictionary = data.get("quests", {})
	Quests.import_data(quest_data)
	var world_map_data: Dictionary = data.get("world_map", data.get("world", {}))
	WorldManager.import_data(world_map_data)
	var position_data: Array = data.get("player", [])
	if position_data.size() == 2:
		_player.position = Vector2(float(position_data[0]), float(position_data[1]))
		_player.camera.reset_smoothing()
	var cell_data: Array = data.get("cells", [])
	for i in range(mini(cell_data.size(), _fire_cells.size())):
		var entry: Array = cell_data[i]
		_fire_cells[i].restore(int(entry[0]), float(entry[1]))
	var pickup_data: Array = data.get("pickups", [])
	for i in range(mini(pickup_data.size(), _pickups.size())):
		if bool(pickup_data[i]):
			_pickups[i].mark_taken()
	var clue_data: Array = data.get("clues", [])
	for i in range(mini(clue_data.size(), _clues.size())):
		if bool(clue_data[i]):
			_clues[i].mark_examined()
	var animal_data: Array = data.get("animals", [])
	for i in range(mini(animal_data.size(), _animals.size())):
		var entry: Array = animal_data[i]
		_animals[i].restore(int(entry[0]), Vector2(float(entry[1]), float(entry[2])))
	_fire_a_started = bool(data.get("a", false))
	_fire_b_started = bool(data.get("b", false))
	_finished = bool(data.get("finished", false))
	_elapsed = float(data.get("elapsed", 0.0))
	if bool(GameState.flags.get("b_requested", false)) and not _fire_b_started:
		_b_timer.start()

# --- Eventos -------------------------------------------------------------------

func _on_fire_b_requested(delay: float) -> void:
	_b_timer.stop()
	_b_timer.wait_time = delay
	_b_timer.start()

func _on_b_timer() -> void:
	_fire_b_started = true
	GameState.flags["b_ignited"] = true
	_manual_ignition = true
	_fire_manager.ignite_zone("B", 1)
	_manual_ignition = false
	GameState.post_message("Otro foco más al este. ¡El humo no cesa!")

func _on_cell_changed(_cell: FireCell, new_state: int) -> void:
	if new_state == FireCell.State.STARTING and not _manual_ignition:
		GameState.post_message("¡El fuego se está propagando!")
	elif new_state == FireCell.State.BURNED:
		GameState.add_stat("fires_out")
		GameState.post_message("Foco extinguido.")
	elif new_state == FireCell.State.RECOVERED:
		GameState.add_stat("sprouts")
		GameState.post_message("Brote plantado: la vegetación vuelve.")
	_story.on_cells_changed()
	if new_state == FireCell.State.BURNED or new_state == FireCell.State.RECOVERED:
		save_progress()

func _on_zone_cleared(zone: String) -> void:
	GameState.post_message("Zona %s despejada. Planta brotes en el suelo quemado." % zone)
	_story.on_zone_cleared(zone)

func _on_ending_reached(ending_id: String) -> void:
	_ending_id = ending_id
	_finished = true
	_victory_timer.start()

func _on_player_died() -> void:
	_dead = true
	_player.set_physics_process(false)
	_defeat_timer.start()

func _on_defeat_timer() -> void:
	_end_screen.show_defeat()

func _on_victory_timer() -> void:
	_victory_shown = true
	save_progress()
	_end_screen.show_victory({
		"fires_out": GameState.get_stat("fires_out"),
		"sprouts": GameState.get_stat("sprouts"),
		"water_used": GameState.get_stat("water_used"),
		"seeds": GameState.get_stat("seeds"),
		"rescued": GameState.get_stat("rescued"),
		"xp": GameState.get_stat("xp"),
		"ending_text": str(ENDING_TEXTS.get(_ending_id, "")),
		"time": _elapsed,
	})

func _on_continue_playing() -> void:
	_victory_shown = false
	_update_audio()

func _on_restart() -> void:
	SaveSystem.pending_load = false
	Transition.reload()

func _on_checkpoint() -> void:
	SaveSystem.pending_load = true
	Transition.reload()

func _on_menu_from_pause() -> void:
	save_progress()
	Transition.go_to(Transition.MENU_SCENE)

func _on_menu() -> void:
	Transition.go_to(Transition.MENU_SCENE)
