extends Node
## Gestor de audio: efectos, música con fundido cruzado y bucles de ambiente. Autoload "Sound".
## Los archivos están en res://assets/audio/{sfx,music,ambience}/. Si falta uno, simplemente no suena.

const MUSIC_DB := -9.0
const FADE_TIME := 2.0
const SFX_VOICES := 10

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _active_music: AudioStreamPlayer = null
var _music_current := ""
var _loops: Dictionary = {}
var _fades: Dictionary = {}
var _cache: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for bus_name in ["Music", "SFX", "Ambience"]:
		_ensure_bus(bus_name)
	for i in range(SFX_VOICES):
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		_sfx_players.append(voice)
	_music_a = _make_music_player()
	_music_b = _make_music_player()
	GameSettings.apply()

func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")

func _make_music_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = "Music"
	player.volume_db = -60.0
	add_child(player)
	return player

func _get_stream(relative: String, loop: bool) -> AudioStream:
	var path := "res://assets/audio/%s.wav" % relative
	if not _cache.has(path):
		_cache[path] = load(path) as AudioStream if ResourceLoader.exists(path) else null
	var stream: AudioStream = _cache[path]
	if stream is AudioStreamWAV and loop:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = wav.data.size() >> 1
	return stream

# --- Efectos ---------------------------------------------------------------------

func play(sound_name: String, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	var stream := _get_stream("sfx/" + sound_name, false)
	if stream == null:
		return
	var voice := _free_voice()
	voice.stream = stream
	voice.volume_db = volume_db
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()

func play_click() -> void:
	play("click", -4.0)

func _free_voice() -> AudioStreamPlayer:
	for voice in _sfx_players:
		if not voice.playing:
			return voice
	return _sfx_players[0]

# --- Música ----------------------------------------------------------------------

func play_music(track: String) -> void:
	if track == _music_current:
		return
	var stream := _get_stream("music/" + track, true)
	if stream == null:
		return
	_music_current = track
	var next := _music_b if _active_music == _music_a else _music_a
	var previous := _active_music
	next.stream = stream
	next.volume_db = -60.0
	next.play()
	_fade(next, MUSIC_DB, false)
	if previous != null and previous.playing:
		_fade(previous, -60.0, true)
	_active_music = next

func stop_music() -> void:
	_music_current = ""
	if _active_music != null:
		_fade(_active_music, -60.0, true)
		_active_music = null

func _fade(player: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	if _fades.has(player):
		var old: Tween = _fades[player]
		old.kill()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, FADE_TIME)
	if stop_after:
		tween.tween_callback(player.stop)
	_fades[player] = tween

# --- Bucles de ambiente ----------------------------------------------------------

func start_loop(loop_name: String, volume_db: float = 0.0) -> void:
	if not _loops.has(loop_name):
		var stream := _get_stream("ambience/" + loop_name, true)
		if stream == null:
			return
		var player := AudioStreamPlayer.new()
		player.bus = "Ambience"
		player.stream = stream
		add_child(player)
		_loops[loop_name] = player
	set_loop_volume(loop_name, volume_db)

func set_loop_volume(loop_name: String, volume_db: float) -> void:
	if not _loops.has(loop_name):
		return
	var player: AudioStreamPlayer = _loops[loop_name]
	if volume_db <= -50.0:
		if player.playing:
			player.stop()
		return
	player.volume_db = volume_db
	if not player.playing:
		player.play()

func stop_loop(loop_name: String) -> void:
	if not _loops.has(loop_name):
		return
	var player: AudioStreamPlayer = _loops[loop_name]
	player.stop()

func stop_all_loops() -> void:
	for loop_name in _loops:
		stop_loop(str(loop_name))
