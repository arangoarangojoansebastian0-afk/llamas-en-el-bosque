class_name Animal
extends CharacterBody2D
## Animal del bosque. Pasea, huye del jugador que corre y del fuego, y puede estar atrapado:
## con E se le ayuda y te sigue hasta el refugio. Origen = patas.

signal rescued(animal: Animal)

enum Species { RABBIT, SQUIRREL, DEER }
enum Mode { WANDER, FLEE, TRAPPED, FOLLOW, SAFE, INJURED }

@export var species: Species = Species.RABBIT
@export var mode: Mode = Mode.WANDER
@export var injured := false
@export var wander_radius := 110.0

var refuge: Refuge = null
var home := Vector2.ZERO
var _dir := 1.0
var _phase := 0.0
var _think := 0.0
var _target := Vector2.ZERO
var _has_target := false
var _flee_dir := Vector2.ZERO
var _flee_time := 0.0
var _reveal := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	add_to_group("observable")
	if injured:
		add_to_group("injured_animal")
		add_to_group("interactable")
	_rng.randomize()
	_phase = _rng.randf() * TAU
	home = global_position
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0 if species != Species.DEER else 6.0
	shape.shape = circle
	shape.position = Vector2(0.0, -4.0)
	add_child(shape)
	_set_mode(mode)

func species_name() -> String:
	match species:
		Species.RABBIT:
			return "conejo"
		Species.SQUIRREL:
			return "ardilla"
		_:
			return "venado"

func get_prompt() -> String:
	if injured:
		return "E · Curar animal herido (Botiquín Animal)"
	return "E · Ayudar (%s atrapado)" % species_name()

func interact(_player: Node) -> void:
	if injured:
		return
	if mode != Mode.TRAPPED:
		return
	_set_mode(Mode.FOLLOW)
	Sound.play("chirp", -4.0)
	GameState.post_message("El %s te sigue. Llévalo al refugio, lejos del fuego." % species_name() if species != Species.SQUIRREL else "La ardilla te sigue. Llévala al refugio, lejos del fuego.")

func heal() -> void:
	if not injured:
		return
	injured = false
	remove_from_group("injured_animal")
	remove_from_group("interactable")
	_set_mode(Mode.SAFE)
	Sound.play("rescue", -3.0)
	GameState.add_stat("animals_healed")
	GameState.post_message("El %s ha sido curado y puede seguir su camino." % species_name() if species != Species.SQUIRREL else "La ardilla ha sido curada y puede seguir su camino.")

func reveal(duration: float) -> void:
	_reveal = duration

## Restaura el estado guardado. Un animal que seguía al jugador vuelve a quedar atrapado.
func restore(saved_mode: int, where: Vector2) -> void:
	global_position = where
	home = where
	if saved_mode == Mode.SAFE:
		_set_mode(Mode.SAFE)
	elif saved_mode == Mode.TRAPPED or saved_mode == Mode.FOLLOW:
		_set_mode(Mode.TRAPPED)
	elif saved_mode == Mode.INJURED:
		injured = true
		_set_mode(Mode.INJURED)
	else:
		_set_mode(Mode.WANDER)

func _set_mode(new_mode: Mode) -> void:
	mode = new_mode
	if mode == Mode.TRAPPED:
		add_to_group("interactable")
	elif is_in_group("interactable"):
		remove_from_group("interactable")
	if mode == Mode.INJURED:
		add_to_group("injured_animal")
		add_to_group("interactable")
	elif mode != Mode.INJURED and is_in_group("injured_animal"):
		remove_from_group("injured_animal")
	velocity = Vector2.ZERO

func _walk_speed() -> float:
	return 45.0 if species == Species.DEER else 38.0

func _run_speed() -> float:
	match species:
		Species.DEER:
			return 150.0
		Species.SQUIRREL:
			return 120.0
		_:
			return 130.0

func _physics_process(delta: float) -> void:
	match mode:
		Mode.WANDER, Mode.SAFE:
			if mode == Mode.WANDER:
				_check_threat()
			_wander(delta)
		Mode.FLEE:
			_flee(delta)
		Mode.FOLLOW:
			_follow(delta)
		Mode.TRAPPED, Mode.INJURED:
			velocity = Vector2.ZERO
	move_and_slide()
	if absf(velocity.x) > 1.0:
		_dir = 1.0 if velocity.x > 0.0 else -1.0
	if velocity.length() > 2.0:
		_phase += delta * 12.0
	if _reveal > 0.0:
		_reveal = maxf(0.0, _reveal - delta)
	queue_redraw()

func _check_threat() -> void:
	var threat := Vector2.ZERO
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		var distance := global_position.distance_to(player.global_position)
		if distance < 36.0 or (distance < 84.0 and player.is_running):
			threat += global_position - player.global_position
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var cell := node as FireCell
		if cell != null and cell.is_dangerous() and global_position.distance_to(cell.global_position) < 120.0:
			threat += global_position - cell.global_position
	if threat != Vector2.ZERO:
		_flee_dir = threat.normalized()
		_flee_time = 1.8
		_set_mode(Mode.FLEE)

func _wander(delta: float) -> void:
	_think -= delta
	if _think <= 0.0:
		_think = _rng.randf_range(1.5, 4.0)
		_has_target = _rng.randf() < 0.55
		if _has_target:
			_target = home + Vector2(_rng.randf_range(-1.0, 1.0), _rng.randf_range(-1.0, 1.0)) * wander_radius
	if _has_target:
		var to_target := _target - global_position
		if to_target.length() < 4.0:
			_has_target = false
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * _walk_speed()
	else:
		velocity = Vector2.ZERO

func _flee(delta: float) -> void:
	_flee_time -= delta
	velocity = _flee_dir * _run_speed()
	if _flee_time <= 0.0:
		home = global_position
		_set_mode(Mode.WANDER)

func _follow(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		velocity = Vector2.ZERO
		return
	var behind := player.global_position - player.facing.normalized() * 26.0
	var distance_to_player := global_position.distance_to(player.global_position)
	if distance_to_player > 260.0:
		global_position = behind
	var to_target := behind - global_position
	if to_target.length() > 6.0:
		velocity = to_target.normalized() * 105.0
	else:
		velocity = Vector2.ZERO
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var cell := node as FireCell
		if cell != null and cell.is_dangerous():
			var away := global_position - cell.global_position
			if away.length() < 60.0:
				velocity += away.normalized() * 90.0
	if refuge != null and refuge.contains(global_position):
		home = refuge.global_position + Vector2(_rng.randf_range(-40.0, 40.0), _rng.randf_range(-20.0, 20.0))
		wander_radius = 50.0
		_set_mode(Mode.SAFE)
		GameState.post_message("¡A salvo! El %s está en el refugio." % species_name() if species != Species.SQUIRREL else "¡A salvo! La ardilla está en el refugio.")
		Sound.play("rescue", -2.0)
		rescued.emit(self)

# --- Dibujo ------------------------------------------------------------------

func _draw() -> void:
	var dir := _dir
	var moving := velocity.length() > 5.0
	var hop := -absf(sin(_phase)) * (1.0 if species == Species.DEER else 2.5) if moving else 0.0
	var top := -48.0 if species == Species.DEER else -22.0
	var shadow_w := 14.0 if species == Species.DEER else 8.0
	draw_colored_polygon(Geo.ellipse_points(Vector2.ZERO, Vector2(shadow_w, 3.5)), Color(0.0, 0.0, 0.0, 0.28))
	match species:
		Species.RABBIT:
			_draw_rabbit(dir, hop)
		Species.SQUIRREL:
			_draw_squirrel(dir, hop)
		Species.DEER:
			_draw_deer(dir, hop)
	if mode == Mode.TRAPPED:
		var blink := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 160.0)
		draw_rect(Rect2(-2.0, top - 10.0, 4.0, 7.0), Color(0.9, 0.25, 0.2, 0.5 + 0.5 * blink))
		draw_rect(Rect2(-2.0, top - 2.0, 4.0, 3.0), Color(0.9, 0.25, 0.2, 0.5 + 0.5 * blink))
	elif injured:
		var blink := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) / 200.0)
		draw_rect(Rect2(-2.0, top - 10.0, 4.0, 7.0), Color(0.2, 0.6, 0.9, 0.5 + 0.5 * blink))
		draw_rect(Rect2(-2.0, top - 2.0, 4.0, 3.0), Color(0.2, 0.6, 0.9, 0.5 + 0.5 * blink))
	if _reveal > 0.0:
		var pulse := 1.0 + 0.2 * sin(float(Time.get_ticks_msec()) / 150.0)
		draw_arc(Vector2(0.0, top * 0.5), 18.0 * pulse, 0.0, TAU, 32, Color(1.0, 0.9, 0.4, minf(1.0, _reveal)), 2.0)

func _draw_rabbit(dir: float, hop: float) -> void:
	var fur := Color("b8a48c")
	draw_colored_polygon(Geo.ellipse_points(Vector2(0.0, -6.0 + hop), Vector2(7.0, 5.0), 14), fur)
	draw_colored_polygon(Geo.ellipse_points(Vector2(dir * 1.0, -4.0 + hop), Vector2(5.0, 3.0), 12), fur.lightened(0.2))
	draw_colored_polygon(Geo.ellipse_points(Vector2(dir * 6.0, -10.0 + hop), Vector2(4.0, 3.5), 12), fur.lightened(0.08))
	draw_rect(Geo.flip_rect(4.0, -18.0 + hop, 2.0, 7.0, dir), fur)
	draw_rect(Geo.flip_rect(7.0, -17.0 + hop, 2.0, 6.0, dir), fur.darkened(0.1))
	draw_rect(Geo.flip_rect(4.5, -17.0 + hop, 1.0, 5.0, dir), Color("e8a0a8"))
	draw_rect(Geo.flip_rect(8.0, -11.0 + hop, 1.0, 1.0, dir), Color("2a2420"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-dir * 7.0, -6.0 + hop), Vector2(2.5, 2.5), 8), Color("f4f1de"))
	draw_rect(Rect2(-4.0, -2.0, 3.0, 2.0), fur.darkened(0.2))
	draw_rect(Rect2(2.0, -2.0, 3.0, 2.0), fur.darkened(0.2))

func _draw_squirrel(dir: float, hop: float) -> void:
	var fur := Color("b8683a")
	draw_colored_polygon(Geo.ellipse_points(Vector2(-dir * 7.0, -12.0 + hop), Vector2(4.0, 8.0), 12), Color("c97a45"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(-dir * 7.0, -17.0 + hop), Vector2(3.0, 4.0), 10), Color("e8b074"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(0.0, -6.0 + hop), Vector2(5.0, 4.5), 12), fur)
	draw_colored_polygon(Geo.ellipse_points(Vector2(dir * 1.0, -4.0 + hop), Vector2(3.5, 2.5), 10), Color("e8c9a0"))
	draw_colored_polygon(Geo.ellipse_points(Vector2(dir * 5.0, -10.0 + hop), Vector2(3.5, 3.0), 10), fur.lightened(0.1))
	draw_rect(Geo.flip_rect(4.0, -15.0 + hop, 2.0, 3.0, dir), fur.darkened(0.15))
	draw_rect(Geo.flip_rect(6.5, -11.0 + hop, 1.0, 1.0, dir), Color("2a2420"))
	draw_rect(Rect2(-3.0, -2.0, 2.0, 2.0), fur.darkened(0.25))
	draw_rect(Rect2(2.0, -2.0, 2.0, 2.0), fur.darkened(0.25))

func _draw_deer(dir: float, hop: float) -> void:
	var fur := Color("a8794a")
	var swing := sin(_phase) * 2.0 if velocity.length() > 5.0 else 0.0
	draw_rect(Rect2(-10.0, -12.0, 3.0, 12.0 + swing), fur.darkened(0.25))
	draw_rect(Rect2(-5.0, -12.0, 3.0, 12.0 - swing), fur.darkened(0.15))
	draw_rect(Rect2(5.0, -12.0, 3.0, 12.0 + swing), fur.darkened(0.25))
	draw_rect(Rect2(9.0, -12.0, 3.0, 12.0 - swing), fur.darkened(0.15))
	draw_colored_polygon(Geo.ellipse_points(Vector2(0.0, -18.0 + hop), Vector2(14.0, 7.0), 16), fur)
	draw_colored_polygon(Geo.ellipse_points(Vector2(0.0, -15.0 + hop), Vector2(11.0, 4.0), 14), fur.lightened(0.22))
	for i in range(4):
		draw_rect(Rect2(-8.0 + float(i) * 5.0, -22.0 + hop + float(i % 2) * 2.0, 2.0, 2.0), Color("f2e8cf"))
	draw_rect(Geo.flip_rect(8.0, -32.0 + hop, 4.0, 14.0, dir), fur)
	draw_colored_polygon(Geo.ellipse_points(Vector2(dir * 14.0, -33.0 + hop), Vector2(5.5, 3.5), 12), fur.lightened(0.05))
	draw_rect(Geo.flip_rect(16.0, -34.0 + hop, 1.0, 1.0, dir), Color("2a2420"))
	draw_line(Vector2(dir * 12.0, -36.0 + hop), Vector2(dir * 9.0, -45.0 + hop), Color("d9c9a0"), 2.0)
	draw_line(Vector2(dir * 10.5, -41.0 + hop), Vector2(dir * 14.0, -44.0 + hop), Color("d9c9a0"), 1.0)
	draw_colored_polygon(Geo.ellipse_points(Vector2(-dir * 14.0, -19.0 + hop), Vector2(2.5, 3.0), 8), Color("f4f1de"))
