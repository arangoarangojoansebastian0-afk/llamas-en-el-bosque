extends Node2D

# Llamas en el Bosque — ilustración procedural reproducible, sin recursos externos.
const WORLD_SIZE := Vector2(1800.0, 1200.0)
const VIEW_SIZE := Vector2(960.0, 540.0)
const PLAYER_SPEED := 220.0
const INTERACT_RADIUS := 96.0
var tree_points: Array[Vector2] = []
var fires: Array[Vector2] = []
var reported_fires: Array[bool] = []
var radio_pos := Vector2.ZERO
var has_radio := false
var trail_points: Array[Vector2] = []
var player_pos := Vector2(140, 500)
var spawn_position := Vector2(140, 500)
var camera_pos := Vector2(480, 270)
var fire_health: Array[float] = []
var elapsed := 0.0
var extinguished := 0
var mode := "menu" # menu, instructions, playing, paused, won
var message := "Sigue el sendero y localiza los focos de humo."
var facing := Vector2.DOWN
var walk_phase := 0.0
var last_interaction := -10.0
var shrubs: Array[Vector2] = []
var flower_patches: Array[Vector2] = []
var stones: Array[Vector2] = []
var fallen_logs: Array[Vector2] = []
var fallen_log_angles: Array[float] = []

func _enter_tree() -> void:
	_add_key_action("move_up", [KEY_W, KEY_UP])
	_add_key_action("move_down", [KEY_S, KEY_DOWN])
	_add_key_action("move_left", [KEY_A, KEY_LEFT])
	_add_key_action("move_right", [KEY_D, KEY_RIGHT])
	_add_key_action("interact", [KEY_E, KEY_SPACE])
	_add_key_action("restart", [KEY_R])
	_add_key_action("report", [KEY_Q])

func _ready() -> void:
	get_window().title = "Llamas en el Bosque · Sendero de la quebrada"
	_generate_map()
	_generate_decorations()
	player_pos = spawn_position
	camera_pos = player_pos
	queue_redraw()
func _process(delta: float) -> void:
	elapsed += delta
	if mode == "playing":
		var direction := Vector2.ZERO
		if Input.is_action_pressed("move_up"): direction.y -= 1
		if Input.is_action_pressed("move_down"): direction.y += 1
		if Input.is_action_pressed("move_left"): direction.x -= 1
		if Input.is_action_pressed("move_right"): direction.x += 1
		if direction.length_squared() > 0.0:
			direction = direction.normalized()
			facing = direction
			player_pos += direction * PLAYER_SPEED * delta
			walk_phase += delta * 10.0
		player_pos.x = clampf(player_pos.x, 34.0, WORLD_SIZE.x - 34.0)
		player_pos.y = clampf(player_pos.y, 112.0, WORLD_SIZE.y - 34.0)
		camera_pos = camera_pos.lerp(player_pos, minf(1.0, delta * 4.0))
		var camera_view := get_viewport_rect().size
		if camera_view.x < WORLD_SIZE.x: camera_pos.x = clampf(camera_pos.x, camera_view.x * 0.5, WORLD_SIZE.x - camera_view.x * 0.5)
		else: camera_pos.x = WORLD_SIZE.x * 0.5
		if camera_view.y < WORLD_SIZE.y: camera_pos.y = clampf(camera_pos.y, camera_view.y * 0.5, WORLD_SIZE.y - camera_view.y * 0.5)
		else: camera_pos.y = WORLD_SIZE.y * 0.5
		if Input.is_action_just_pressed("report"):
			_report_nearest_fire()
		if Input.is_action_just_pressed("interact"):
			_try_extinguish()
		if extinguished == fires.size():
			mode = "won"
			message = "Los tres focos están controlados."
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		if mode == "playing": mode = "paused"
		elif mode == "paused": mode = "playing"
		elif mode == "instructions": mode = "menu"
	elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
		if mode == "menu": _start_game()
		elif mode == "instructions": mode = "menu"
		elif mode == "paused": mode = "playing"
		elif mode == "won": _start_game()
	elif event.keycode == KEY_R and mode == "won":
		_start_game()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var screen_size := get_viewport_rect().size
		var p := Vector2(event.position.x * 960.0 / screen_size.x, event.position.y * 540.0 / screen_size.y)
		if mode == "menu":
			if Rect2(363, 325, 234, 54).has_point(p): _start_game()
			elif Rect2(363, 391, 234, 43).has_point(p): mode = "instructions"
		elif mode == "instructions" and Rect2(363, 428, 234, 43).has_point(p): mode = "menu"
		elif mode == "paused":
			if Rect2(363, 315, 234, 50).has_point(p): mode = "playing"
			elif Rect2(363, 375, 234, 46).has_point(p): mode = "menu"
		elif mode == "won" and Rect2(363, 390, 234, 48).has_point(p): _start_game()

func _start_game() -> void:
	_generate_map()
	_generate_decorations()
	player_pos = spawn_position
	camera_pos = player_pos
	extinguished = 0
	message = "Sigue los puntos naranjas del mapa. Acércate a un foco y pulsa E."
	mode = "playing"
func _try_extinguish() -> void:
	if not has_radio and player_pos.distance_to(radio_pos) < 64.0:
		has_radio = true
		message = "Radio recogido. Pulsa Q para avisar de un foco."
		return
	var closest := -1
	var distance := INF
	for i in range(fires.size()):
		if fire_health[i] <= 0.0: continue
		var d: float = player_pos.distance_to(fires[i])
		if d < distance:
			distance = d
			closest = i
	if closest >= 0 and distance < INTERACT_RADIUS:
		fire_health[closest] = 0.0
		extinguished += 1
		last_interaction = elapsed
		message = "Foco controlado. Ante un incendio real, aléjate y avisa a emergencias."
	else:
		message = "Acércate al humo hasta ver el indicador «E · CONTROLAR»."

func _report_nearest_fire() -> void:
	if not has_radio:
		message = "Busca el radio junto al sendero para poder avisar."
		return
	var closest := -1
	var distance := INF
	for i in range(fires.size()):
		if fire_health[i] <= 0.0 or reported_fires[i]: continue
		var d: float = player_pos.distance_to(fires[i])
		if d < distance:
			distance = d
			closest = i
	if closest >= 0:
		reported_fires[closest] = true
		message = "Foco reportado por radio. En una emergencia real, avisa a las autoridades."
	else:
		message = "No hay focos nuevos para reportar."
func _draw() -> void:
	var view := get_viewport_rect().size
	var camera := Vector2(view.x * 0.5, view.y * 0.5)
	draw_set_transform(camera - camera_pos)
	_draw_world()
	draw_set_transform(Vector2.ZERO)
	var ui_scale := Vector2(view.x / 960.0, view.y / 540.0)
	draw_set_transform(Vector2.ZERO, 0.0, ui_scale)
	var ui_view := Vector2(960.0, 540.0)
	_draw_hud(ui_view)
	if mode == "menu": _draw_menu(ui_view)
	elif mode == "instructions": _draw_instructions(ui_view)
	elif mode == "paused": _draw_pause(ui_view)
	elif mode == "won": _draw_victory(ui_view)
	draw_set_transform(Vector2.ZERO)
func _draw_world() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("344a35"))
	# Ground texture is deterministic and sparse to keep drawing inexpensive.
	for x in range(25, 1800, 47):
		for y in range(105, 1200, 43):
			var seed := sin(float(x) * 12.9898 + float(y) * 78.233)
			var p := Vector2(float(x) + fposmod(seed * 91.0, 26.0), float(y) + fposmod(seed * 47.0, 19.0))
			var tint := Color("788052") if seed > 0 else Color("263d31")
			draw_line(p, p + Vector2(2.0, 1.0), tint, 1.0)
	# Meandering ochre trail with a soft edge, inset and center track.
	var trail := PackedVector2Array(trail_points)
	draw_polyline(trail, Color("26372d"), 92.0, true)
	draw_polyline(trail, Color("776748"), 78.0, true)
	draw_polyline(trail, Color("a18a62"), 3.0, true)
	_draw_understory()
	# Cool creek and small stepping stones give orientation in the southern forest.
	var creek := PackedVector2Array([Vector2(0, 1080), Vector2(220, 1040), Vector2(390, 1080), Vector2(580, 1060), Vector2(760, 1110), Vector2(960, 1080), Vector2(1160, 1120), Vector2(1430, 1070), Vector2(1800, 1100)])
	draw_polyline(creek, Color("243b36"), 34.0, true)
	draw_polyline(creek, Color("638d83"), 13.0, true)
	for i in range(tree_points.size()):
		_draw_tree(tree_points[i], i)
	_draw_landmarks()
	for i in range(fires.size()):
		if fire_health[i] > 0.0: _draw_fire(fires[i], elapsed + float(i) * 1.7)
		else: _draw_scorch(fires[i])
	if not has_radio: _draw_radio(radio_pos)
	_draw_player(player_pos)
	# Safe border landmarks and map edge cues.
	for x in range(0, 1800, 96):
		draw_line(Vector2(x, 98), Vector2(x + 8, 98), Color("c1a66d"), 2.0)

func _generate_map() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	trail_points.clear()
	tree_points.clear()
	fires.clear()
	fire_health.clear()
	reported_fires.clear()
	var route_y := rng.randf_range(220.0, 980.0)
	for i in range(13):
		route_y = clampf(route_y + rng.randf_range(-115.0, 115.0), 155.0, WORLD_SIZE.y - 150.0)
		var route_x := -35.0 + float(i) * 155.0
		trail_points.append(Vector2(route_x, route_y))
	spawn_position = Vector2(120.0, trail_points[1].y)
	radio_pos = spawn_position + Vector2(74.0, -12.0)
	has_radio = false
	for i in range(3):
		var route_index := clampi(2 + i * 4 + rng.randi_range(-1, 1), 1, trail_points.size() - 2)
		var focus := trail_points[route_index] + Vector2(rng.randf_range(-48.0, 48.0), rng.randf_range(-75.0, 75.0))
		fires.append(Vector2(clampf(focus.x, 80.0, WORLD_SIZE.x - 80.0), clampf(focus.y, 150.0, WORLD_SIZE.y - 120.0)))
		fire_health.append(100.0)
		reported_fires.append(false)
	for i in range(70):
		var tree := Vector2(rng.randf_range(45.0, WORLD_SIZE.x - 45.0), rng.randf_range(145.0, WORLD_SIZE.y - 45.0))
		var near_fire := false
		for fire in fires:
			if tree.distance_to(fire) < 115.0: near_fire = true
		if not near_fire and tree.distance_to(spawn_position) > 100.0 and tree.distance_to(radio_pos) > 50.0 and not _near_trail(tree, 75.0):
			tree_points.append(tree)
func _generate_decorations() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	shrubs.clear()
	flower_patches.clear()
	stones.clear()
	fallen_logs.clear()
	fallen_log_angles.clear()
	for i in range(155):
		var p := Vector2(rng.randf_range(35.0, WORLD_SIZE.x - 35.0), rng.randf_range(125.0, WORLD_SIZE.y - 35.0))
		if not _near_trail(p, 66.0): shrubs.append(p)
	for i in range(58):
		var p := Vector2(rng.randf_range(30.0, WORLD_SIZE.x - 30.0), rng.randf_range(125.0, WORLD_SIZE.y - 30.0))
		if not _near_trail(p, 58.0): flower_patches.append(p)
	for i in range(34):
		var p := Vector2(rng.randf_range(35.0, WORLD_SIZE.x - 35.0), rng.randf_range(125.0, WORLD_SIZE.y - 35.0))
		if not _near_trail(p, 58.0): stones.append(p)
	for i in range(22):
		var p := Vector2(rng.randf_range(45.0, WORLD_SIZE.x - 45.0), rng.randf_range(125.0, WORLD_SIZE.y - 45.0))
		if not _near_trail(p, 60.0):
			fallen_logs.append(p)
			fallen_log_angles.append(rng.randf_range(-0.7, 0.7))

func _near_trail(point: Vector2, margin: float) -> bool:
	for i in range(trail_points.size() - 1):
		var a: Vector2 = trail_points[i]
		var b: Vector2 = trail_points[i + 1]
		var segment := b - a
		var t := clampf((point - a).dot(segment) / segment.length_squared(), 0.0, 1.0)
		if point.distance_to(a + segment * t) < margin: return true
	return false

func _draw_understory() -> void:
	for i in range(shrubs.size()):
		var p: Vector2 = shrubs[i]
		var scale := 0.8 + float(i % 4) * 0.12
		_draw_ellipse(p + Vector2(1, 5), Vector2(13, 5) * scale, Color(0.05, 0.09, 0.06, 0.25))
		var leaf_color := Color("486345") if i % 3 == 0 else Color("3c5b3f")
		draw_circle(p + Vector2(-7, 0) * scale, 8.0 * scale, leaf_color.darkened(0.08))
		draw_circle(p + Vector2(1, -3) * scale, 10.0 * scale, leaf_color)
		draw_circle(p + Vector2(8, 1) * scale, 7.0 * scale, leaf_color.lightened(0.06))
	for i in range(stones.size()):
		_draw_boulder(stones[i], 5.0 + float(i % 4) * 1.2)
	for i in range(fallen_logs.size()):
		var p: Vector2 = fallen_logs[i]
		var axis := Vector2(1, 0).rotated(fallen_log_angles[i])
		var length := 24.0 + float(i % 5) * 5.0
		draw_line(p - axis * length * 0.5 + Vector2(1, 3), p + axis * length * 0.5 + Vector2(1, 3), Color(0.05, 0.08, 0.06, 0.35), 9.0, true)
		draw_line(p - axis * length * 0.5, p + axis * length * 0.5, Color("73573b"), 7.0, true)
		draw_line(p - axis * length * 0.42 - Vector2(0, 1), p + axis * length * 0.42 - Vector2(0, 1), Color("98704a"), 2.0, true)
		draw_circle(p + axis * length * 0.5, 3.0, Color("b28a5b"))
	for i in range(flower_patches.size()):
		var p: Vector2 = flower_patches[i]
		for j in range(3):
			var bloom := p + Vector2(float(j - 1) * 5.0, float((i + j) % 3) * 2.0)
			draw_line(bloom + Vector2(0, 4), bloom + Vector2(0, -2), Color("647846"), 1.5)
			var petal := Color("d7c783") if i % 2 == 0 else Color("c88f79")
			draw_circle(bloom + Vector2(0, -3), 2.2, petal)
			draw_circle(bloom + Vector2(2, -4), 1.4, Color("eee0ac"))
func _draw_tree(p: Vector2, idx: int) -> void:
	var seed := float(idx)
	var radius := 25.0 + fposmod(seed * 17.0, 11.0)
	var canopy: Color = [Color("244b39"), Color("315b3d"), Color("3b6240"), Color("526b43"), Color("345643")][idx % 5]
	# Trunk and roots peek out from under individually lobed canopy clusters.
	_draw_ellipse(p + Vector2(2, 17), Vector2(radius * 0.72, 10), Color(0.08, 0.13, 0.10, 0.34))
	draw_rect(Rect2(p + Vector2(-5, -2), Vector2(10, 25)), Color("73563a"))
	draw_line(p + Vector2(-4, 18), p + Vector2(-13, 26), Color("8b6943"), 4.0, true)
	draw_line(p + Vector2(4, 18), p + Vector2(12, 26), Color("8b6943"), 4.0, true)
	draw_circle(p + Vector2(0, -3), radius, Color("172e28"))
	draw_circle(p + Vector2(-12, -9), radius * 0.61, canopy.darkened(0.12))
	draw_circle(p + Vector2(10, -13), radius * 0.66, canopy)
	draw_circle(p + Vector2(-1, -18), radius * 0.53, canopy.lightened(0.06))
	draw_arc(p + Vector2(-1, -18), radius * 0.47, 3.55, 5.65, 18, Color(0.72, 0.77, 0.49, 0.24), 2.0)
	# A few mossy fern fronds vary at each trunk.
	if idx % 3 != 1:
		_draw_fern(p + Vector2(-radius * 0.7, 18), 0.75 + fposmod(seed, 3.0) * 0.12)
	if idx % 4 == 0: _draw_boulder(p + Vector2(radius + 12, 12), 9.0 + fposmod(seed, 4.0))

func _draw_fern(p: Vector2, s: float) -> void:
	var c := Color("718454")
	for side in [-1.0, 1.0]:
		var tip := p + Vector2(side * 13.0 * s, -14.0 * s)
		draw_line(p, tip, Color("405d39"), 2.0)
		for k in range(1, 5):
			var t := float(k) / 5.0
			var stem := p.lerp(tip, t)
			var leaf := Vector2(side * 8.0 * s * (1.0 - t * 0.35), -4.0 * s)
			draw_line(stem, stem + leaf, c, 2.0)

func _draw_boulder(p: Vector2, r: float) -> void:
	_draw_ellipse(p + Vector2(2, 5), Vector2(r + 2, r * 0.62), Color(0.03, 0.07, 0.05, 0.3))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-r, 2), p + Vector2(-r * 0.65, -r * 0.65), p + Vector2(r * 0.2, -r), p + Vector2(r, -r * 0.2), p + Vector2(r * 0.75, r * 0.5), p + Vector2(-r * 0.8, r * 0.6)]), Color("777b68"))
	draw_line(p + Vector2(-r * 0.45, -r * 0.45), p + Vector2(r * 0.1, -r * 0.72), Color("a3a18a"), 2.0)

func _draw_landmarks() -> void:
	# Ranger post, sign and flower patches mark the start of the trail.
	_draw_boulder(Vector2(390, 286), 8.0)
	draw_rect(Rect2(424, 238, 8, 42), Color("73513a"))
	draw_rect(Rect2(403, 235, 50, 19), Color("d4bd83"))
	draw_rect(Rect2(407, 239, 42, 11), Color("566648"))
	draw_string(ThemeDB.fallback_font, Vector2(410, 248), "SENDERO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("f0e4bf"))
	for f in [Vector2(245, 520), Vector2(255, 528), Vector2(267, 517), Vector2(950, 850), Vector2(965, 855), Vector2(952, 864), Vector2(1540, 390)]:
		draw_line(f + Vector2(0, 4), f + Vector2(0, -3), Color("526744"), 2.0)
		draw_circle(f + Vector2(0, -4), 3.0, Color("d4c486"))
		draw_circle(f + Vector2(2, -5), 2.0, Color("d98f72"))

func _draw_fire(p: Vector2, t: float) -> void:
	var flicker := sin(t * 7.4) * 2.8 + cos(t * 4.3) * 1.3
	# Low-cost layered halos, ember bed, animated flame silhouettes and rising smoke.
	draw_circle(p, 56.0 + sin(t * 2.0) * 3.0, Color(0.95, 0.3, 0.08, 0.07))
	draw_circle(p, 36.0, Color(0.95, 0.42, 0.1, 0.12))
	_draw_ellipse(p + Vector2(0, 15), Vector2(26, 12), Color("322a22"))
	for i in range(5):
		var x := float(i - 2) * 9.0
		var height := 26.0 + fposmod(float(i) * 13.0 + t * 4.0, 10.0) + flicker
		var flame := PackedVector2Array([p + Vector2(x - 8, 16), p + Vector2(x - 5, 2), p + Vector2(x - 2, -height * 0.57), p + Vector2(x + sin(t * 5.0 + float(i)) * 4.0, -height), p + Vector2(x + 5, -height * 0.48), p + Vector2(x + 9, 16)])
		draw_colored_polygon(flame, Color("b63e1e") if i % 2 == 0 else Color("dc5a24"))
		draw_colored_polygon(PackedVector2Array([p + Vector2(x - 4, 14), p + Vector2(x - 1, -height * 0.4), p + Vector2(x + 1, -height * 0.72), p + Vector2(x + 5, 13)]), Color("f4a13b"))
		draw_circle(p + Vector2(x + sin(t * 3.0 + i) * 14.0, -height - fposmod(t * 8.0 + i * 9.0, 25.0)), 2.0, Color(1.0, 0.66, 0.24, 0.75))
	for i in range(3):
		var drift := sin(t * 1.2 + float(i) * 2.0) * 6.0
		var smoke_pos := p + Vector2(drift, -37.0 - fposmod(t * 13.0 + float(i) * 16.0, 58.0))
		draw_circle(smoke_pos, 7.0 + float(i), Color(0.42, 0.45, 0.39, 0.16 - float(i) * 0.025))
	draw_circle(p + Vector2(0, 9), 6.0, Color("ffe28a"))
	# Danger ring stays readable without obscuring the world.
	draw_arc(p, 43.0, 0, TAU, 36, Color(0.98, 0.56, 0.22, 0.56), 1.5)

func _draw_scorch(p: Vector2) -> void:
	_draw_ellipse(p + Vector2(0, 9), Vector2(33, 18), Color("37362c"))
	_draw_ellipse(p + Vector2(-3, 5), Vector2(22, 11), Color("4d4937"))
	for i in range(6):
		var x := float(i - 3) * 8.0
		draw_line(p + Vector2(x, 6), p + Vector2(x + 2, -8 - fposmod(float(i) * 7.0, 11.0)), Color("514336"), 3.0)
	draw_circle(p + Vector2(-10, 2), 2.0, Color("826747"))

func _draw_radio(p: Vector2) -> void:
	_draw_ellipse(p + Vector2(0, 8), Vector2(12, 4), Color(0.04, 0.07, 0.05, 0.45))
	draw_rect(Rect2(p + Vector2(-9, -5), Vector2(18, 12)), Color("a88a50"))
	draw_rect(Rect2(p + Vector2(-6, -2), Vector2(12, 6)), Color("384b3a"))
	draw_line(p + Vector2(4, -5), p + Vector2(8, -15), Color("d6c080"), 2.0)
	draw_circle(p + Vector2(8, -16), 2.0, Color("df7550"))

func _draw_player(p: Vector2) -> void:
	var bob := sin(walk_phase) * 1.5 if Input.is_action_pressed("move_up") or Input.is_action_pressed("move_down") or Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right") else 0.0
	var q := p + Vector2(0, bob)
	_draw_ellipse(q + Vector2(0, 16), Vector2(17, 8), Color(0.04, 0.08, 0.07, 0.5))
	# Backpack silhouette, legs, coat and head; facing controls the readable face.
	var step := sin(walk_phase) * 3.0 if bob != 0.0 else 0.0
	draw_rect(Rect2(q + Vector2(-10, 12 + step), Vector2(7, 9)), Color("343832"))
	draw_rect(Rect2(q + Vector2(3, 12 - step), Vector2(7, 9)), Color("343832"))
	draw_rect(Rect2(q + Vector2(-12, -2), Vector2(24, 19)), Color("497c70"))
	draw_rect(Rect2(q + Vector2(-10, 1), Vector2(20, 12)), Color("73917a"))
	draw_rect(Rect2(q + Vector2(7, 1), Vector2(6, 10)), Color("9b6840"))
	draw_circle(q + Vector2(0, -7), 10.0, Color("d7a879"))
	draw_rect(Rect2(q + Vector2(-11, -13), Vector2(22, 5)), Color("d1a34f"))
	draw_rect(Rect2(q + Vector2(-7, -18), Vector2(15, 7)), Color("bd8743"))
	var eye_dir := Vector2(signf(facing.x), 0) if absf(facing.x) > absf(facing.y) else Vector2(0, signf(facing.y))
	if facing.y >= 0: draw_circle(q + Vector2(3, -5), 1.4, Color("36291f"))
	elif facing.y < 0: draw_circle(q + Vector2(-3, -8), 1.0, Color("7c5439"))
	if player_pos.distance_to(_nearest_live_fire()) < INTERACT_RADIUS and mode == "playing":
		draw_arc(q + Vector2(0, 1), 20, PI, TAU, 24, Color("ecd98e"), 2.0)

func _nearest_live_fire() -> Vector2:
	var result := Vector2(-10000, -10000)
	var nearest := INF
	for i in range(fires.size()):
		if fire_health[i] <= 0.0: continue
		var d: float = player_pos.distance_to(fires[i])
		if d < nearest:
			nearest = d
			result = fires[i]
	return result

func _draw_hud(view: Vector2) -> void:
	if mode == "menu" or mode == "instructions": return
	# Compact field journal HUD with hand-drawn edges and restrained palette.
	draw_rect(Rect2(0, 0, view.x, 83), Color(0.055, 0.09, 0.075, 0.94))
	draw_line(Vector2(0, 83), Vector2(view.x, 83), Color("97865e"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(22, 30), "LLAMAS EN EL BOSQUE", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("e8dfc2"))
	draw_string(ThemeDB.fallback_font, Vector2(22, 56), "SENDERO DE LA QUEBRADA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("9dab83"))
	draw_string(ThemeDB.fallback_font, Vector2(690, 29), "FOCOS CONTROLADOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("aebc99"))
	for i in range(fires.size()):
		var color := Color("d7a445") if fire_health[i] <= 0.0 else Color("d05b35")
		draw_circle(Vector2(857 + i * 22, 25), 6, color)
		draw_circle(Vector2(857 + i * 22, 25), 2.3, Color("f2d38b") if fire_health[i] <= 0.0 else Color("f3a453"))
	draw_string(ThemeDB.fallback_font, Vector2(912, 31), "%d / 3" % extinguished, HORIZONTAL_ALIGNMENT_RIGHT, 38, 14, Color("eee4cb"))
	draw_string(ThemeDB.fallback_font, Vector2(690, 56), "OBJETIVO  ·  Reporta y controla los tres focos", HORIZONTAL_ALIGNMENT_LEFT, 250, 11, Color("e5d6ad"))
	draw_string(ThemeDB.fallback_font, Vector2(690, 74), "RADIO  ·  " + ("LISTO (Q avisa)" if has_radio else "BUSCA EL EQUIPO (E)"), HORIZONTAL_ALIGNMENT_LEFT, 250, 10, Color("c8bf91"))
	# Bottom message ribbon and controls.
	draw_rect(Rect2(0, view.y - 53, view.x, 53), Color(0.055, 0.09, 0.075, 0.91))
	draw_line(Vector2(0, view.y - 53), Vector2(view.x, view.y - 53), Color("776c50"), 1.0)
	draw_string(ThemeDB.fallback_font, Vector2(20, view.y - 29), message, HORIZONTAL_ALIGNMENT_LEFT, 575, 13, Color("eee4ca"))
	draw_string(ThemeDB.fallback_font, Vector2(view.x - 340, view.y - 28), "WASD mover   E recoger/controlar   Q reportar   ESC pausa", HORIZONTAL_ALIGNMENT_RIGHT, 322, 11, Color("aab49a"))
	var fire := _nearest_live_fire()
	if mode == "playing" and fire.x > -1000 and player_pos.distance_to(fire) < INTERACT_RADIUS:
		var screen_p := fire - camera_pos + view * 0.5
		if screen_p.y > 95 and screen_p.y < view.y - 65:
			draw_rect(Rect2(screen_p.x - 65, screen_p.y - 75, 130, 25), Color(0.08, 0.12, 0.09, 0.9))
			draw_string(ThemeDB.fallback_font, screen_p + Vector2(-52, -58), "E  ·  CONTROLAR", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ffdf9a"))

	_draw_minimap(view)
func _draw_menu(view: Vector2) -> void:
	_draw_scrim(view, 0.42)
	# Framed title card, centered over the illustrated forest.
	draw_rect(Rect2(246, 92, 468, 356), Color(0.055, 0.09, 0.075, 0.9))
	draw_rect(Rect2(253, 99, 454, 342), Color(0.055, 0.09, 0.075, 0.0), false, 1.5)
	_centered_line("UNA HISTORIA DEL BOSQUE", 158, 430, 12, Color("c0bd91"))
	_centered_line("LLAMAS EN EL", 211, 430, 31, Color("eee4c8"))
	_centered_line("BOSQUE", 250, 430, 37, Color("d6ad62"))
	draw_line(Vector2(373, 269), Vector2(587, 269), Color("88764f"), 1.0)
	_centered_line("El sendero de la quebrada", 298, 430, 15, Color("c6c9a7"))
	_draw_button(Rect2(363, 325, 234, 54), "COMENZAR", true)
	_draw_button(Rect2(363, 391, 234, 43), "CÓMO JUGAR", false)
	_centered_line("Una aventura educativa sobre prevención y cuidado del bosque", 474, 820, 11, Color("ddd9c2"))

func _draw_instructions(view: Vector2) -> void:
	_draw_scrim(view, 0.55)
	draw_rect(Rect2(225, 82, 510, 374), Color(0.055, 0.09, 0.075, 0.96))
	_centered_line("CUADERNO DE CAMPO", 128, 470, 14, Color("d4b96f"))
	_centered_line("El sendero de la quebrada", 174, 470, 23, Color("eee4c8"))
	draw_string(ThemeDB.fallback_font, Vector2(275, 220), "WASD o flechas", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d7c990"))
	draw_string(ThemeDB.fallback_font, Vector2(445, 220), "Recorre el bosque", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e3e2ce"))
	draw_string(ThemeDB.fallback_font, Vector2(275, 256), "E o espacio", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d7c990"))
	draw_string(ThemeDB.fallback_font, Vector2(445, 256), "Recoge el radio o controla un foco", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e3e2ce"))
	draw_string(ThemeDB.fallback_font, Vector2(275, 292), "Q / ESC", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d7c990"))
	draw_string(ThemeDB.fallback_font, Vector2(445, 292), "Q avisa; ESC pausa o reanuda", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("e3e2ce"))
	draw_string(ThemeDB.fallback_font, Vector2(275, 318), "MAPA", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("d7c990"))
	draw_string(ThemeDB.fallback_font, Vector2(445, 318), "Naranja: pendiente · verde: avisado · claro: tú", HORIZONTAL_ALIGNMENT_LEFT, 240, 12, Color("e3e2ce"))
	draw_line(Vector2(275, 337), Vector2(685, 337), Color("756d51"), 1.0)
	_centered_line("En un incendio real: aléjate, avisa a emergencias", 357, 440, 13, Color("e9d9ad"))
	_centered_line("y sigue las indicaciones de las autoridades.", 377, 440, 13, Color("e9d9ad"))
	_draw_button(Rect2(363, 402, 234, 43), "VOLVER", false)

func _draw_pause(view: Vector2) -> void:
	_draw_scrim(view, 0.62)
	draw_rect(Rect2(300, 174, 360, 250), Color(0.055, 0.09, 0.075, 0.96))
	_centered_line("PAUSA", 223, 320, 27, Color("eee4c8"))
	_centered_line("El bosque espera. Tómate un respiro.", 254, 320, 12, Color("bdc5a8"))
	_draw_button(Rect2(363, 286, 234, 50), "REANUDAR", true)
	_draw_button(Rect2(363, 350, 234, 46), "VOLVER AL MENÚ", false)

func _draw_victory(view: Vector2) -> void:
	_draw_scrim(view, 0.58)
	draw_rect(Rect2(250, 118, 460, 326), Color(0.055, 0.09, 0.075, 0.96))
	_centered_line("MISIÓN COMPLETADA", 165, 420, 26, Color("e5ca78"))
	_centered_line("El sendero vuelve a estar en calma.", 207, 420, 15, Color("eee4c8"))
	_centered_line("FOCOS CONTROLADOS     %d / 3" % extinguished, 252, 420, 14, Color("bed09e"))
	draw_line(Vector2(296, 274), Vector2(664, 274), Color("756d51"), 1.0)
	_centered_line("La prevención y el aviso temprano ayudan", 306, 420, 13, Color("e8dfc2"))
	_centered_line("a proteger vidas y ecosistemas.", 326, 420, 13, Color("e8dfc2"))
	_draw_button(Rect2(363, 352, 234, 48), "JUGAR DE NUEVO", true)
	_centered_line("En una emergencia real, aléjate y llama a emergencias.", 424, 460, 11, Color("b4bd9e"))

func _centered_line(text: String, y: float, width: float, size: int, color: Color) -> void:
	var center_x := 480.0
	draw_string(ThemeDB.fallback_font, Vector2(center_x - width * 0.5, y), text, HORIZONTAL_ALIGNMENT_CENTER, width, size, color)

func _draw_minimap(view: Vector2) -> void:
	var panel := Rect2(view.x - 150.0, 92.0, 138.0, 91.0)
	draw_rect(panel, Color(0.055, 0.09, 0.075, 0.92))
	draw_rect(Rect2(panel.position + Vector2(1, 1), panel.size - Vector2(2, 2)), Color(0.3, 0.39, 0.29, 0.35), false, 1.0)
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(7, 13), "MAPA DEL SENDERO", HORIZONTAL_ALIGNMENT_LEFT, 124, 9, Color("d7c990"))
	var path_points := PackedVector2Array()
	for point_value in trail_points:
		var point: Vector2 = point_value
		path_points.append(panel.position + Vector2(7.0 + point.x / WORLD_SIZE.x * 124.0, 20.0 + point.y / WORLD_SIZE.y * 54.0))
	draw_polyline(path_points, Color("927c56"), 2.0, true)
	for i in range(fires.size()):
		var marker: Vector2 = panel.position + Vector2(7.0 + fires[i].x / WORLD_SIZE.x * 124.0, 20.0 + fires[i].y / WORLD_SIZE.y * 54.0)
		var marker_color: Color = Color("e7bd67") if fire_health[i] <= 0.0 else Color("75ad8b") if reported_fires[i] else Color("e46a38")
		draw_circle(marker, 4.2, Color("171f18"))
		draw_circle(marker, 2.8, marker_color)
	var player_marker: Vector2 = panel.position + Vector2(7.0 + player_pos.x / WORLD_SIZE.x * 124.0, 20.0 + player_pos.y / WORLD_SIZE.y * 54.0)
	draw_circle(player_marker, 4.0, Color("f0e7c7"))
	draw_circle(player_marker, 2.0, Color("527d73"))
	if not has_radio:
		var radio_marker: Vector2 = panel.position + Vector2(7.0 + radio_pos.x / WORLD_SIZE.x * 124.0, 20.0 + radio_pos.y / WORLD_SIZE.y * 54.0)
		draw_rect(Rect2(radio_marker - Vector2(2, 2), Vector2(4, 4)), Color("8fc2b1"))
		draw_rect(Rect2(panel.position + Vector2(105, 80), Vector2(4, 4)), Color("8fc2b1"))
		draw_string(ThemeDB.fallback_font, panel.position + Vector2(111, 85), "radio", HORIZONTAL_ALIGNMENT_LEFT, 26, 7, Color("c2c9ac"))
	draw_circle(panel.position + Vector2(12, 82), 2.4, Color("e46a38"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(18, 85), "focos", HORIZONTAL_ALIGNMENT_LEFT, 40, 8, Color("c2c9ac"))
	draw_circle(panel.position + Vector2(72, 82), 2.4, Color("f0e7c7"))
	draw_string(ThemeDB.fallback_font, panel.position + Vector2(78, 85), "tú", HORIZONTAL_ALIGNMENT_LEFT, 30, 8, Color("c2c9ac"))

func _draw_scrim(view: Vector2, alpha: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.025, 0.055, 0.045, alpha))

func _draw_button(rect: Rect2, label: String, primary: bool) -> void:
	var base := Color("887644") if primary else Color("344e3b")
	draw_rect(rect, base)
	draw_rect(Rect2(rect.position + Vector2(3, 3), rect.size - Vector2(6, 6)), Color(0.1, 0.14, 0.1, 0.28), false, 1.0)
	draw_line(rect.position + Vector2(7, 5), rect.position + Vector2(rect.size.x - 7, 5), Color(0.88, 0.81, 0.61, 0.35), 1.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(8, rect.size.y * 0.5 + 5), label, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x - 16, 14, Color("f1e9d2"))

func _add_key_action(action_name: String, keys: Array) -> void:
	if not InputMap.has_action(action_name): InputMap.add_action(action_name)
	for key in keys:
		var event := InputEventKey.new()
		event.keycode = key
		if not InputMap.action_has_event(action_name, event): InputMap.action_add_event(action_name, event)


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
