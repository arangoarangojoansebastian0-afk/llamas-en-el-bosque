# Estado de desarrollo: Llamas en el Bosque

## Diagnóstico del proyecto importado

- Se trabajó sobre la copia del proyecto existente; no se sustituyó su arquitectura ni se creó otro juego.
- El proyecto tiene 45 scripts GDScript y 6 escenas TSCN. La escena principal lleva al menú; la región con escena jugable es Zona de Frontera.
- Los autoloads existentes siguen siendo la base de estado, misiones, diálogo, audio, transiciones y guardado.
- El gestor y el mapa antiguos mantenían datos paralelos. Las escenas del minimapa no se podían instanciar por nodos sin `parent`, y sus referencias de script tenían un UID duplicado.
- No existen escenas jugables para Sendero de la Quebrada, Pueblo El Pinar, Sierras del Norte ni Llanura Quemada. Esas regiones sí aparecen en los datos del mapa; no se simula que sean niveles disponibles.

## Fase 1: correcciones y compatibilidad

- Corregido el error de compilación `Rect2.ZERO` en el gestor heredado, consolidando los datos en el autoload `WorldManager` y manteniendo adaptadores para las rutas antiguas.
- Reparadas las escenas `minimap.tscn` y `test_minimap.tscn`, la asociación del script y la jerarquía de sus nodos.
- Conectados jugador, minimapa, misiones y el guardado existente sin reemplazar los sistemas del juego.
- Se conserva la compatibilidad con guardados anteriores: si no tienen datos del mapa, las regiones se reconstruyen desde las misiones completadas.

## Fase 2: mapa y minimapa

- El mapa global contiene las cinco regiones con posiciones y límites en coordenadas globales.
- Permite seleccionar regiones, acercar y alejar con la rueda o los botones, arrastrar el mapa y recentrarlo.
- Muestra coordenadas globales, posición del jugador, ubicaciones descubiertas y marcadores vinculados a misiones activas.
- Las ubicaciones se revelan al acercarse; las misiones completadas revelan nuevas regiones.
- El minimapa reutiliza esos mismos datos y sigue la posición del jugador.
- El mapa evita transiciones rotas: no ofrece viaje a regiones que no tengan una escena existente.

## Comprobaciones realizadas

Entorno de validación: Godot `4.7.2.stable.official.ed1daf0bf` para Linux.

- Escaneo headless del editor: salida correcta, sin errores de parseo.
- Carga de scripts: 45 scripts, 0 errores.
- Carga e instanciación de escenas: 6 escenas, 0 errores.
- Pruebas del mapa: posición global, descubrimiento por proximidad, desbloqueo por misión, protección ante escenas ausentes, zoom, desplazamiento, selección de región y lectura de coordenadas.
- Prueba de integración de Frontera: jugador, HUD, minimapa, misión inicial, apertura del mapa y escritura, lectura y restauración de regiones y ubicaciones desde `user://save.json`.

Los procesos de prueba headless terminan forzadamente y Godot informa algunos objetos y recursos todavía activos en ese cierre. No aparecieron errores durante las cargas ni las interacciones probadas; no se ha verificado el cierre normal de una sesión gráfica.

## Pendiente de verificación

- Probar la presentación visual y la entrada de ratón en una ejecución gráfica y en las resoluciones de destino.
- Añadir o recuperar las escenas jugables faltantes antes de habilitar viajes a las otras cuatro regiones.
- Probar sonido y exportación en los sistemas operativos de destino.

