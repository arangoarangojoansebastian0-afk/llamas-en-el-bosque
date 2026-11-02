class_name FireManager
extends Node
## Coordina los focos de la escena: encendido por zonas, conteos y aviso de zona despejada.

signal fire_started(cell: FireCell)
signal cell_changed(cell: FireCell, new_state: int)
signal zone_cleared(zone: String)

var _cleared: Dictionary = {}

## Conecta todos los FireCell que ya estén en el árbol.
func register_all() -> void:
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var cell := node as FireCell
		if cell != null and not cell.state_changed.is_connected(_on_cell_state_changed):
			cell.state_changed.connect(_on_cell_state_changed)

func cells_in_zone(zone: String) -> Array[FireCell]:
	var result: Array[FireCell] = []
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var cell := node as FireCell
		if cell != null and cell.zone == zone:
			result.append(cell)
	return result

func ignite_zone(zone: String, count: int = 1) -> void:
	var started := 0
	for cell: FireCell in cells_in_zone(zone):
		if started >= count:
			break
		if cell.state == FireCell.State.UNBURNT:
			cell.ignite()
			started += 1

func count_dangerous() -> int:
	var total := 0
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var cell := node as FireCell
		if cell != null and cell.is_dangerous():
			total += 1
	return total

func count_state(wanted: int) -> int:
	var total := 0
	for node in get_tree().get_nodes_in_group("fire_cell"):
		var cell := node as FireCell
		if cell != null and int(cell.state) == wanted:
			total += 1
	return total

func _on_cell_state_changed(cell: FireCell, new_state: int) -> void:
	if new_state == FireCell.State.STARTING:
		fire_started.emit(cell)
	cell_changed.emit(cell, new_state)
	if new_state == FireCell.State.BURNED:
		_check_zone(cell.zone)

func _check_zone(zone: String) -> void:
	if _cleared.has(zone):
		return
	for cell: FireCell in cells_in_zone(zone):
		if cell.is_dangerous():
			return
	_cleared[zone] = true
	zone_cleared.emit(zone)
