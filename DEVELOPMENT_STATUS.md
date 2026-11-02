# Estado de desarrollo: Llamas en el Bosque

## Diagnóstico del proyecto importado

- Se trabajó sobre la copia del proyecto existente; no se sustituyó su arquitectura ni se creó otro juego.
- El proyecto tiene 45 scripts GDScript y 7 escenas TSCN. La escena principal lleva al menú; la región con escena jugable es Zona de Frontera.
- Los autoloads existentes siguen siendo la base de estado, misiones, diálogo, audio, transiciones y guardado.
- El gestor y el mapa antiguos mantenían datos paralelos. Las escenas del minimapa no se podían instanciar por nodos sin `parent`, y sus referencias de script tenían un UID duplicado.
- No existen escenas jugables para Sendero de la Quebrada, Pueblo El Pinar, Sierras del Norte ni Llanura Quemada. Esas regiones sí aparecen en los datos del mapa; no se simula que sean niveles disponibles.

## Fases completadas

### Fase 1: correcciones y compatibilidad
- Corregido el error de compilación `Rect2.ZERO` en el gestor heredado, consolidando los datos en el autoload `WorldManager` y manteniendo adaptadores para las rutas antiguas.
- Reparadas las escenas `minimap.tscn` y `test_minimap.tscn`, la asociación del script y la jerarquía de sus nodos.
- Conectados jugador, minimapa, misiones y el guardado existente sin reemplazar los sistemas del juego.
- Se conserva la compatibilidad con guardados anteriores: si no tienen datos del mapa, las regiones se reconstruyen desde las misiones completadas.

### Fase 2: mapa y minimapa
- **Minimap: nuevo minimapa profesional**:
  - Muestra terreno por región con colores distintos para cada región.
  - Marcadores de regiones descubiertas/ocultas con opacidad reducida.
  - Marcadores de ubicaciones para objetos, NPC, misiones, incendios, entradas/salidas y recursos.
  - Marcador de posición del jugador con indicador de dirección.
  - Leyenda de símbolos en el HUD con colores para tipos.
  - Actualiza automáticamente al descubrir nuevas ubicaciones o cambiar región.
  - Conecta con WorldManager existente: sigue las regiones descubiertas y misiones activas.
  - Permite vinculado completo a la jerarquía del juego (añadido minimap.gd y corregida la escena).

- **Mapa mundial: actualizado con soporte completo para 5 regiones**:
  - Coordenadas globales precisas para todas las regiones (frontera, sendero, pueblo, montañas, llanura).
  - Funcionalidad de selección de región con condición de que esté descubierta y tenga escena.
  - Zoom y desplazamiento para una navegación detallada.
  - Se mantienen las funcionalidades existentes del mapa: descubrimiento por proximidad, desbloqueo por misiones, protección ante escenas ausentes.
  - Los nombres de las regiones, descripciones y ubicaciones de entrada están definidos en el mapeo en WorldManager.
  - Solo Frontera tiene una escena jugable dentro del proyecto importado; las otras siguen pendientes.

## Comprobaciones realizadas

Entorno de validación: Godot `4.7.2.stable.official.ed1daf0bf` para Linux.

- Escaneo headless del editor: salida correcta, sin errores de parseo.
- Carga de scripts: 46 scripts, 0 errores.
- Carga e instanciación de escenas: 7 escenas, 0 errores.
- Pruebas del mapa: posición global, descubrimiento por proximidad, desbloqueo por misión, protección ante escenas ausentes, zoom, desplazamiento, selección de región y lectura de coordenadas.
- Prueba de integración de Frontera: jugador, HUD, minimapa, misión inicial, apertura del mapa y escritura, lectura y restauración de regiones y ubicaciones desde `user://save.json`. Los procesos de prueba headless terminan forzadamente y Godot informa algunos objetos y recursos todavía activos en ese cierre. No aparecieron errores durante las cargas ni las interacciones probadas; no se ha verificado el cierre normal de una sesión gráfica.

## Pendiente de verificación

- Probar la presentación visual y la entrada de ratón en una ejecución gráfica y en las resoluciones de destino.
- Añadir o recuperar las escenas jugables faltantes antes de habilitar viajes a las otras cuatro regiones.
- Probar sonido y exportación en los sistemas operativos de destino.