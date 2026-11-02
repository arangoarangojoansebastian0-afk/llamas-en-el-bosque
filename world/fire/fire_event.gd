class_name FireEvent
extends RefCounted
## Describe un evento de incendio: una serie de zonas que se encienden de forma coordinada.

enum Intensity { SMALL = 1, MEDIUM = 2, LARGE = 3 }

var zone_id := ""
var intensity: Intensity = Intensity.SMALL
var ignite_count := 1       # cuantos focos encender al inicio
var spread_boost := 1.0     # multiplicador de velocidad de propagacion

static func small(zone: String) -> FireEvent:
	var ev := FireEvent.new()
	ev.zone_id = zone
	ev.intensity = Intensity.SMALL
	ev.ignite_count = 1
	ev.spread_boost = 1.0
	return ev

static func medium(zone: String) -> FireEvent:
	var ev := FireEvent.new()
	ev.zone_id = zone
	ev.intensity = Intensity.MEDIUM
	ev.ignite_count = 2
	ev.spread_boost = 1.4
	return ev

static func large(zone: String) -> FireEvent:
	var ev := FireEvent.new()
	ev.zone_id = zone
	ev.intensity = Intensity.LARGE
	ev.ignite_count = 3
	ev.spread_boost = 2.0
	return ev
