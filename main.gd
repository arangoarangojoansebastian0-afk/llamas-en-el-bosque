// Edición de limpieza de espacios y variables innecesarias
// Conservar la lógica principal de generación de mapa y estados
// Eliminar scripts de interfaz no utilizados de un ejemplo de "main.gd" heredado

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