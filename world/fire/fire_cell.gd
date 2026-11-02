class_name FireCell
extends Node2D
## Foco de fuego / matorral combustible con ciclo completo de estados:
## UNBURNT -> STARTING (inicio) -> ACTIVE (incendio, se propaga) -> EXTINGUISHING (apagando)
## -> BURNED (extinguido, suelo quemado) -> RECOVERED (el jugador planta un brote).
## Origen del nodo = base del fuego (ordenación por profundidad).

signal state_changed(cell: FireCell, new_state: int)

enum State { UNBURNT, STARTING, ACTIVE, EXTINGUISHING, BURNED, RECOVERED }

@export var zone := ""
@export var radius := 26.0
@export var heat_radius := 64.0
@export var damage_per_second := 14.0
@export var heat_stamina_drain := 22.0
@export var start_duration := 3.0
@export var spread_interval := 7.0
@export var spread_radius := 90.0
@export var max_spreads := 2
@export var spread_chance := 0.6

var state: State = State.UNBURNT
var health := 100.0
var _state_time := 0.0
var _spread_timer := 0.0
var _spreads := 0
var _phase := 0.0
var _tufts: Array[Vector2] = []
var _rng := RandomNumberGenerator.new()
var _flame_particles: CPUParticles2D
var _smoke_particles: CPUParticles2D
var _light: PointLight2D

static var _light_texture: Texture2D = null

func _ready() -> void:
	add_to_group("fire_cell")
	_rng.randomize()
	_phase = _rng.randf() * TAU
	for n in range(8):
		var angle := _rng.randf() * TAU
		var reach := sqrt(_rng.randf()) * radius * 0.9
		_tufts.append(Vector2(cos(angle), sin(angle) * 0.55) * reach)
	_build_effects()
	_apply_state_visuals()

# --- API pública -------------------------------------------------------------

func ignite() -> void:
	if state != State.UNBURNT:
		return
	health = 100.0
	_spreads = 0
	_spread_timer = 0.0
	_set_state(State.STARTING)

func apply_water(power: float) -> void:
	if not is_dangerous():
		return
	health = maxf(0.0, health - power)
	if health <= 0.0:
		_set_state(State.BURNED)
	elif state != State.EXTINGUISHING:
		_set_state(State.EXTINGUISHING)

func recover() -> bool:
	if state != State.BURNED:
		return false
	_set_state(State.RECOVERED)
	return true

func is_dangerous() -> bool:
	return state == State.STARTING or state == State.ACTIVE or state == State.EXTINGUISHING

## Restaura un estado guardado (carga de partida).
func restore(saved_state: int, saved_health: float) -> void:
	health = saved_health
	state = clampi(saved_state, 0, 5) as State
	_state_time = 99.0 if (state == State.BURNED or state == State.RECOVERED) else 0.0
	_apply_state_visuals()
	queue_redraw()

# --- Interacción (solo cuando está quemado: plantar brote) -------------------

func get_prompt() -> String:
	return "E · Plantar brote (1 semilla)"

func interact(_player: Node) -> void:
	if state != State.BURNED:
		return
	if GameState.spend_resource("seed", 1):
		recover()
	else:
		GameState.post_message("Necesitas una semilla. Busca bolsas de semillas junto al sendero.")

# --- Lógica ------------------------------------------------------------------

func _process(delta: float) -> void:
	_state_time += delta
	match state:
		State.STARTING:
			if _state_time >= start_duration:
				_set_state(State.ACTIVE)
		State.ACTIVE:
			_spread_timer += delta
			if _spread_timer >= spread_interval:
				_spread_timer = 0.0
				_try_spread()
		State.EXTINGUISHING:
			health = minf(100.0, health + 6.0 * delta)
			if health >= 100.0:
				_set_state(State.ACTIVE)
		_:
			pass
	if is_dangerous():
		_burn_player(delta)
	_update_effects()
	queue_redraw()

func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	_state_time = 0.0
	_apply_state_visuals()
	if new_state == State.BURNED:
		Sound.play("fire_out", _near_volume())
	elif new_state == State.RECOVERED:
		Sound.play("plant", _near_volume() + 2.0)
	state_changed.emit(self, new_state)

func _near_volume() -> float:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return -10.0
	return -3.0 if global_position.distance_to(player.global_position) < 300.0 else -16.0

func _try_spread() -> void:
	if _spreads >= max_spreads:
		return
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var other := node as FireCell
		if other == null or other == self or other.state != State.UNBURNT:
			continue
		if global_position.distance_to(other.global_position) > spread_radius:
			continue
		if _rng.randf() <= spread_chance:
			other.ignite()
			_spreads += 1
			if _spreads >= max_spreads:
				return

func _burn_player(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance < radius:
		player.scorch(damage_per_second * _intensity() * delta)
	elif distance < heat_radius:
		GameState.change_stamina(-heat_stamina_drain * delta)

func _intensity() -> float:
	match state:
		State.STARTING:
			return 0.3 + 0.7 * clampf(_state_time / start_duration, 0.0, 1.0)
		State.EXTINGUISHING:
			return 0.25 + 0.75 * (health / 100.0)
		State.ACTIVE:
			return 1.0
		_:
			return 0.0

# --- Efectos -----------------------------------------------------------------

func _build_effects() -> void:
	_flame_particles = CPUParticles2D.new()
	_flame_particles.position = Vector2(0.0, -4.0)
	_flame_particles.emitting = false
	_flame_particles.amount = 22
	_flame_particles.lifetime = 0.8
	_flame_particles.direction = Vector2(0.0, -1.0)
	_flame_particles.spread = 25.0
	_flame_particles.gravity = Vector2(0.0, -40.0)
	_flame_particles.initial_velocity_min = 14.0
	_flame_particles.initial_velocity_max = 34.0
	_flame_particles.scale_amount_min = 2.0
	_flame_particles.scale_amount_max = 4.0
	_flame_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	_flame_particles.emission_sphere_radius = radius * 0.6
	_flame_particles.color_ramp = Geo.ramp3(Color("ffd166"), Color("ef6a3a"), Color(0.3, 0.1, 0.1, 0.0))
	add_child(_flame_particles)

	_smoke_particles = CPUParticles2D.new()
	_smoke_particles.position = Vector2(0.0, -24.0)
	_smoke_particles.emitting = false
	_smoke_particles.amount = 14
	_smoke_particles.lifetime = 2.4
	_smoke_particles.direction = Vector2(0.0, -1.0)
	_smoke_particles.spread = 18.0
	_smoke_particles.gravity = Vector2(8.0, -14.0)
	_smoke_particles.initial_velocity_min = 8.0
	_smoke_particles.initial_velocity_max = 18.0
	_smoke_particles.scale_amount_min = 3.0
	_smoke_particles.scale_amount_max = 6.0
	_smoke_particles.color_ramp = Geo.ramp3(Color(0.22, 0.22, 0.22, 0.55), Color(0.3, 0.3, 0.3, 0.35), Color(0.4, 0.4, 0.4, 0.0))
	add_child(_smoke_particles)

	_light = PointLight2D.new()
	_light.position = Vector2(0.0, -12.0)
	_light.texture = _get_light_texture()
	_light.color = Color("ff9a3c")
	_light.texture_scale = 2.4
	_light.energy = 0.0
	add_child(_light)

static func _get_light_texture() -> Texture2D:
	if _light_texture == null:
		var gradient := Gradient.new()
		gradient.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
		gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 128
		texture.height = 128
		texture.fill = GradientTexture2D.FILL_RADIAL
		texture.fill_from = Vector2(0.5, 0.5)
		texture.fill_to = Vector2(1.0, 0.5)
		_light_texture = texture
	return _light_texture

func _apply_state_visuals() -> void:
	var burning := is_dangerous()
	_flame_particles.emitting = burning
	_smoke_particles.emitting = burning or state == State.BURNED
	if state == State.BURNED:
		add_to_group("interactable")
	elif is_in_group("interactable"):
		remove_from_group("interactable")
	queue_redraw()

func _update_effects() -> void:
	if is_dangerous():
		var t := float(Time.get_ticks_msec()) / 1000.0
		_light.energy = _intensity() * (0.95 + 0.1 * sin(t * 13.0 + _phase))
	else:
		_light.energy = 0.0
	if state == State.BURNED and _state_time > 12.0 and _smoke_particles.emitting:
		_smoke_particles.emitting = false

# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	match state:
		State.UNBURNT:
			_draw_dry_brush()
		State.STARTING, State.ACTIVE, State.EXTINGUISHING:
			_draw_scorch(0.6)
			_draw_flames()
		State.BURNED:
			_draw_scorch(1.0)
			_draw_embers()
		State.RECOVERED:
			_draw_scorch(0.35)
			_draw_sapling()

func _draw_scorch(strength: float) -> void:
	draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(radius, radius * 0.55)), Color(0.1, 0.08, 0.07, 0.85 * strength))

func _draw_dry_brush() -> void:
	for tuft in _tufts:
		draw_line(tuft, tuft + Vector2(-2.0, -7.0), Color("b8a35a"), 1.5)
		draw_line(tuft, tuft + Vector2(1.0, -9.0), Color("cdb86a"), 1.5)
		draw_line(tuft, tuft + Vector2(3.0, -6.0), Color("9c8a48"), 1.5)

func _draw_flames() -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	var amount := _intensity()
	for k in range(5):
		var fk := float(k)
		var x := (fk - 2.0) * radius * 0.42
		var sway := sin(t * 7.0 + fk * 1.9 + _phase)
		var h := (16.0 + 12.0 * (0.5 + 0.5 * sway) + 6.0 * (2.0 - absf(fk - 2.0))) * amount
		var w := radius * 0.55 * (0.5 + 0.5 * amount)
		_flame_rect(x, w, h, Color("d94a2b"))
		_flame_rect(x, w * 0.66, h * 0.72, Color("f28a30"))
		_flame_rect(x, w * 0.32, h * 0.45, Color("ffd76a"))

func _flame_rect(x: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(floorf(x - w * 0.5), -floorf(h), floorf(w), floorf(h)), color)

func _draw_embers() -> void:
	var glow := clampf(1.0 - _state_time / 14.0, 0.0, 1.0)
	var t := float(Time.get_ticks_msec()) / 1000.0
	for n in range(_tufts.size()):
		var tuft := _tufts[n]
		draw_line(tuft, tuft + Vector2(2.0, -5.0), Color("2a2623"), 2.0)
		var flicker := 0.5 + 0.5 * sin(t * 5.0 + float(n) * 2.3)
		draw_rect(Rect2(tuft.x - 1.0, tuft.y - 1.0, 2.0, 2.0), Color(1.0, 0.45, 0.15, glow * flicker))

func _draw_sapling() -> void:
	var grow := clampf(_state_time / 4.0, 0.0, 1.0)
	for tuft in _tufts:
		draw_rect(Rect2(tuft.x, tuft.y - 4.0 * grow, 2.0, 4.0 * grow), Color("6fbf5a"))
	var stem := floorf(16.0 * grow)
	draw_rect(Rect2(-1.0, -stem, 3.0, stem), Color("7a5232"))
	draw_rect(Rect2(-6.0, -stem - 3.0, 6.0, 4.0 * grow), Color("5fae4e"))
	draw_rect(Rect2(2.0, -stem - 5.0, 6.0, 4.0 * grow), Color("7ccf5f"))
