class_name Player
extends CharacterBody2D
## Protagonista: movimiento, carrera con resistencia, interacción y lanzamiento de agua.
## El origen del nodo está en los pies (necesario para ordenar por profundidad).
## El aspecto es un marcador temporal; el sprite animado se integra en la fase de arte.

signal prompt_changed(text: String)

const WALK_SPEED := 110.0
const RUN_SPEED := 190.0
const RUN_COST := 22.0          # resistencia por segundo al correr
const REGEN_RATE := 14.0        # resistencia por segundo en reposo
const REGEN_DELAY := 0.8        # segundos tras correr antes de recuperar
const EXHAUST_RECOVER := 30.0   # tras agotarse, no corre hasta superar este valor
const HURT_INVULNERABILITY := 0.6
const INTERACT_RANGE := 44.0
const SPLASH_RANGE := 64.0
const SPLASH_POWER := 40.0
const SPLASH_COOLDOWN := 0.35
const OBSERVE_RANGE := 260.0
const OBSERVE_COST := 12.0

var facing := Vector2.DOWN
var is_running := false
var camera: Camera2D
var _regen_timer := 0.0
var _exhausted := false
var _hurt_timer := 0.0
var _walk_phase := 0.0
var _target: Node2D = null
var _prompt := ""
var _splash_timer := 0.0
var _splash_visual := 0.0
var _splash_target := Vector2.ZERO
var _observe_timer := 0.0
var _step_timer := 0.0
var _observe_visual := 0.0

func _ready() -> void:
	add_to_group("player")
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 5.0
	shape.shape = circle
	shape.position = Vector2(0.0, -5.0)
	add_child(shape)
	camera = Camera2D.new()
	camera.position = Vector2(0.0, -14.0)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)

func set_camera_limits(area: Rect2) -> void:
	camera.limit_left = int(area.position.x)
	camera.limit_top = int(area.position.y)
	camera.limit_right = int(area.end.x)
	camera.limit_bottom = int(area.end.y)

func _physics_process(delta: float) -> void:
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	_splash_timer = maxf(0.0, _splash_timer - delta)
	_splash_visual = maxf(0.0, _splash_visual - delta)
	_observe_timer = maxf(0.0, _observe_timer - delta)
	_observe_visual = maxf(0.0, _observe_visual - delta)
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var wants_run := Input.is_action_pressed("run") and direction != Vector2.ZERO
	is_running = wants_run and not _exhausted and GameState.stamina > 0.0
	velocity = direction * (RUN_SPEED if is_running else WALK_SPEED)
	if direction != Vector2.ZERO:
		facing = direction
		_walk_phase += delta * (14.0 if is_running else 9.0)
	move_and_slide()
	_update_footsteps(delta)
	_update_stamina(delta)
	_update_interaction()
	var input_blocked := Dialogue.is_open or Dialogue.recently_closed()
	if Input.is_action_just_pressed("interact") and _target != null and not input_blocked:
		_target.call("interact", self)
	if Input.is_action_just_pressed("action") and not input_blocked:
		_on_action()
	queue_redraw()

func _update_footsteps(delta: float) -> void:
	if velocity.length() < 5.0:
		_step_timer = 0.0
		return
	_step_timer -= delta
	if _step_timer <= 0.0:
		Sound.play("step%d" % randi_range(1, 2), -8.0, 0.1)
		_step_timer = 0.22 if is_running else 0.36

func _update_stamina(delta: float) -> void:
	if is_running:
		GameState.change_stamina(-RUN_COST * delta)
		_regen_timer = REGEN_DELAY
		if GameState.stamina <= 0.0:
			_exhausted = true
		return
	_regen_timer = maxf(0.0, _regen_timer - delta)
	if _regen_timer <= 0.0:
		GameState.change_stamina(REGEN_RATE * delta)
	if _exhausted and GameState.stamina >= EXHAUST_RECOVER:
		_exhausted = false

func _update_interaction() -> void:
	var best: Node2D = null
	var best_distance := INTERACT_RANGE
	for node in get_tree().get_nodes_in_group("interactable"):
		var candidate := node as Node2D
		if candidate == null or not candidate.has_method("interact"):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	_target = best
	var text := ""
	if _target != null and _target.has_method("get_prompt"):
		text = str(_target.call("get_prompt"))
	if text != _prompt:
		_prompt = text
		prompt_changed.emit(text)

## Espacio: lanza agua si hay fuego cerca; si no, observa el entorno.
func _on_action() -> void:
	# Prioridad 1: detector de calor si está equipado (detecta fuego a través de humo)
	if GameState.has_tool("detector_calor"):
		if _detector_scan():
			return
	var fire := _nearest_fire()
	if fire != null:
		# Pala: cubrir fuego con tierra si la tienes
		if GameState.has_tool("shovel"):
			if _cover_with_soil(fire):
				return
		_throw_water(fire)
	else:
		# Hacha: talar árboles secos para crear cortafuegos
		if GameState.has_tool("axe"):
			if _chop_dry_wood():
				return
		_observe()

## Detector de calor: detecta focos a través del humo y señala zonas secas.
func _detector_scan() -> bool:
	if not GameState.use_tool("detector_calor"):
		return false
	_observe_timer = 2.0
	_observe_visual = 0.8
	Sound.play("observe", -4.0)
	GameState.change_stamina(-8.0)
	var found := 0
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var cell := node as FireCell
		if cell == null:
			continue
		if global_position.distance_to(cell.global_position) <= 300.0:
			cell.reveal(5.0)
			found += 1
	if found > 0:
		GameState.post_message("Detector: %d focos activos cercanos." % found)
	else:
		GameState.post_message("Detector: no se detectan focos en un radio de 300m.")
	return true

## Pala: cubre un foco de fuego con tierra, reduciendo su intensidad.
func _cover_with_soil(fire: FireCell) -> bool:
	if not GameState.has_tool("shovel"):
		return false
	if global_position.distance_to(fire.global_position) > SPLASH_RANGE + 20.0:
		return false
	if not fire.is_dangerous():
		return false
	if not GameState.use_tool("shovel"):
		GameState.post_message("Pala sin usos.")
		return false
	_splash_timer = SPLASH_COOLDOWN
	_splash_visual = 0.25
	_splash_target = to_local(fire.global_position)
	facing = (fire.global_position - global_position).normalized()
	Sound.play("splash", -3.0, 0.08)
	GameState.add_stat("soil_used")
	fire.apply_water(30.0)  # la tierra apaga como 30 puntos de fuego
	GameState.post_message("Cubres el foco con tierra. El fuego cede.")
	return true

## Hacha: tala árboles secos para crear cortafuegos y obtiene madera.
func _chop_dry_wood() -> bool:
	var target := _nearest_dry_wood()
	if target == null:
		return false
	if global_position.distance_to(target.global_position) > INTERACT_RANGE + 10.0:
		return false
	if not GameState.use_tool("axe"):
		GameState.post_message("Hacha sin usos.")
		return false
	_observe_timer = 0.5
	_observe_visual = 0.3
	Sound.play("splash", -5.0, 0.1)
	target.chop(self)
	GameState.add_resource("wood", 1)
	GameState.add_stat("wood_chopped")
	GameState.post_message("Talas un árbol seco. Cortafuego abierto.")
	return true

func _nearest_dry_wood() -> Node2D:
	var best: Node2D = null
	var best_distance := INTERACT_RANGE + 10.0
	for node in get_tree().get_nodes_in_group("dry_wood"):
		var candidate := node as Node2D
		if candidate == null or not candidate.has_method("chop"):
			continue
		var distance := global_position.distance_to(candidate.global_position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best

func _throw_water(fire: FireCell) -> void:
	if _splash_timer > 0.0:
		return
	# Extintor: gasta un uso y aplica poder mayor
	if GameState.has_tool("extinguisher"):
		GameState.use_tool("extinguisher")
		_splash_timer = SPLASH_COOLDOWN
		_splash_visual = 0.22
		Sound.play("splash", 0.0, 0.05)
		_splash_target = to_local(fire.global_position)
		facing = (fire.global_position - global_position).normalized()
		GameState.add_stat("water_used")
		fire.apply_water(200.0)  # extintor apaga de un uso
		return
	if not GameState.spend_resource("water", 1):
		GameState.post_message("Sin agua. Rellena la cantimplora en un estanque o barril (E).")
		return
	_splash_timer = SPLASH_COOLDOWN
	_splash_visual = 0.22
	Sound.play("splash", -3.0, 0.08)
	_splash_target = to_local(fire.global_position)
	facing = (fire.global_position - global_position).normalized()
	GameState.add_stat("water_used")
	fire.apply_water(SPLASH_POWER)

## Observación ambiental: resalta indicios y animales atrapados cercanos.
func _observe() -> void:
	if _observe_timer > 0.0:
		return
	if GameState.stamina < OBSERVE_COST:
		GameState.post_message("Estás demasiado cansado para concentrarte.")
		return
	_observe_timer = 1.5
	_observe_visual = 0.6
	Sound.play("observe", -4.0)
	GameState.change_stamina(-OBSERVE_COST)
	var found := 0
	for node in get_tree().get_nodes_in_group("observable"):
		var item := node as Node2D
		if item == null or not item.has_method("reveal"):
			continue
		if global_position.distance_to(item.global_position) <= OBSERVE_RANGE:
			item.call("reveal", 4.0)
			found += 1
	if found > 0:
		GameState.post_message("Observas tu entorno: hay %d cosas importantes cerca." % found)
	else:
		GameState.post_message("No percibes nada importante cerca.")

func _nearest_fire() -> FireCell:
	var best: FireCell = null
	var best_distance := SPLASH_RANGE
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var cell := node as FireCell
		if cell == null or not cell.is_dangerous():
			continue
		var distance := global_position.distance_to(cell.global_position)
		if distance < best_distance:
			best_distance = distance
			best = cell
	return best

func take_damage(amount: float) -> void:
	if _hurt_timer > 0.0:
		return
	_hurt_timer = HURT_INVULNERABILITY
	Sound.play("hurt", -2.0)
	GameState.damage(amount)

var _last_scorch_msec := -10000

func _scorch_sound_cooling() -> bool:
	var now := Time.get_ticks_msec()
	if now - _last_scorch_msec < 700:
		return true
	_last_scorch_msec = now
	return false

## Daño continuo (fuego): no usa invulnerabilidad, solo parpadeo visual.
func scorch(amount: float) -> void:
	var protection := GameState.fire_protection()
	var real_amount := amount * (1.0 - protection)
	if _hurt_timer <= 0.0 and not _scorch_sound_cooling():
		Sound.play("hurt", -6.0)
	GameState.damage(real_amount)
	_hurt_timer = maxf(_hurt_timer, 0.12)

func _draw() -> void:
	var moving := velocity.length() > 1.0
	var swing := sin(_walk_phase) * 2.5 if moving else 0.0
	var hurt := _hurt_timer > 0.0
	var torso := Color("e0a458") if hurt else Color("4f8a7a")
	var skin := Color("e0b088")
	draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(10.0, 4.0)), Color(0.0, 0.0, 0.0, 0.3))
	# piernas y botas
	draw_rect(Rect2(-5.0, -9.0 + swing, 4.0, 9.0 - swing), Color("3a3f4a"))
	draw_rect(Rect2(1.0, -9.0 - swing, 4.0, 9.0 + swing), Color("323641"))
	draw_rect(Rect2(-5.0, -3.0, 4.0, 3.0), Color("2a2420"))
	draw_rect(Rect2(1.0, -3.0, 4.0, 3.0), Color("2a2420"))
	# mochila (detrás si mira arriba, lateral en otro caso)
	var pack_x := -11.0 if facing.x >= 0.0 else 7.0
	if facing.y < -0.3:
		draw_rect(Rect2(-6.0, -20.0, 12.0, 11.0), Color("8a5a36"))
	else:
		draw_rect(Rect2(pack_x, -20.0, 4.0, 11.0), Color("8a5a36"))
		draw_rect(Rect2(pack_x, -20.0, 4.0, 2.0), Color("a8744a"))
	# torso con luz a la izquierda y sombra a la derecha
	draw_rect(Rect2(-7.0, -21.0, 14.0, 13.0), torso)
	draw_rect(Rect2(3.0, -21.0, 4.0, 13.0), torso.darkened(0.22))
	draw_rect(Rect2(-7.0, -10.0, 14.0, 2.0), Color("3b2a1c"))
	draw_rect(Rect2(-7.0, -21.0, 14.0, 2.0), torso.lightened(0.18))
	# brazos
	draw_rect(Rect2(-10.0, -20.0 - swing * 0.5, 3.0, 10.0), torso.darkened(0.08))
	draw_rect(Rect2(7.0, -20.0 + swing * 0.5, 3.0, 10.0), torso.darkened(0.25))
	draw_rect(Rect2(-10.0, -10.0 - swing * 0.5, 3.0, 3.0), skin)
	draw_rect(Rect2(7.0, -10.0 + swing * 0.5, 3.0, 3.0), skin.darkened(0.15))
	# cabeza, pañuelo y sombrero
	draw_rect(Rect2(-5.0, -30.0, 10.0, 9.0), skin)
	draw_rect(Rect2(-5.0, -22.0, 10.0, 2.0), Color("c4503a"))
	draw_rect(Rect2(-8.0, -32.0, 16.0, 3.0), Color("d1a34f"))
	draw_rect(Rect2(-5.0, -37.0, 10.0, 5.0), Color("bd8743"))
	draw_rect(Rect2(-5.0, -33.0, 10.0, 1.0), Color("7a3b2a"))
	if facing.y > -0.3:
		var eye_shift := 1.5 * signf(facing.x) if absf(facing.x) > 0.3 else 0.0
		draw_rect(Rect2(-3.0 + eye_shift, -27.0, 2.0, 2.0), Color("36291f"))
		draw_rect(Rect2(1.0 + eye_shift, -27.0, 2.0, 2.0), Color("36291f"))
	if _splash_visual > 0.0:
		for k in range(1, 7):
			var fraction := float(k) / 6.0
			var drop := Vector2(0.0, -14.0).lerp(_splash_target, fraction)
			drop.y -= 10.0 * sin(PI * fraction)
			draw_rect(Rect2(drop.x - 1.5, drop.y - 1.5, 3.0, 3.0), Color("8fd3f4"))
	if _observe_visual > 0.0:
		var progress := 1.0 - _observe_visual / 0.6
		draw_arc(Vector2(0.0, -14.0), progress * OBSERVE_RANGE, 0.0, TAU, 64, Color(1.0, 1.0, 0.7, 0.55 * (1.0 - progress)), 2.0)
