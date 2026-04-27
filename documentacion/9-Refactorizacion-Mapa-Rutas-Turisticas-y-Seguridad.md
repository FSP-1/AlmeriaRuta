# Refactorización del Mapa, Rutas Turísticas y Seguridad — Descripción técnica

Última actualización: 2026-04-27

Este documento detalla el refactor realizado sobre el subsistema de mapa y rutas turísticas, los motivos técnicos, los cambios implementados y los pasos de validación.

## Objetivos

- Mejorar la precisión del buscador de rutas turísticas en autobús (evitar soluciones que solo usan 2 paradas o sugerencias que van en dirección contraria).
- Forzar que los tramos en bus respeten la secuencia real de paradas de la línea.
- Usar OSRM únicamente para tramos a pie (y conducción del bus donde aplique), garantizando trazados reales en la calle.
- Separar responsabilidades (servicios de OSRM, construcción de polilíneas, ViewModel, vistas) para pruebas y mantenimiento.
- Añadir trazas de debug reproducibles y documentadas.

## Resumen de la solución

- Se rehizo el algoritmo de planificación: ahora modela cada `Stop` como un nodo y expande estados que incluyen la línea, dirección y `indexInLine`. Esto evita zig-zags y combinatoria innecesaria.
- Los tramos de bus avanzan por una parada a la vez (one-hop transitions). Los transbordos están limitados por un umbral mínimo de paradas antes de permitir otro transbordo y aplican una penalización por transbordo.
- OSRM se usa para calcular rutas peatonales (usuario→parada_subida y última_parada→destino) y para tramos de bus cuando se desea la ruta por calle; en la representación visual los puntos de bus respetan la secuencia de paradas.
- Se añadieron servicios dedicados: `OsrmRoutingService`, `StopLoaderService`, `BusRoutePolylineBuilder`. `MapViewModel` oraquesta y es inyectable para tests.

## Diseño del nuevo algoritmo (alto nivel)

- Estado (Node) extendido con: `stopId`, `lineId` (opcional si venimos andando), `reversed` (dirección de la línea), `indexInLine`, `totalMinutes`, `busStopsTaken`.
- Clave de estado: `(stopId, lineId?, reversed?, indexInLine, transfersUsed)` — esto evita perder información de dónde exactamente del recorrido estamos.
- Transiciones:
  - Caminar hasta cualquier parada candidata (coste: minutos caminando por distancia real).
  - Subir a bus en una parada y avanzar una parada (one-hop). Repetir hasta bajarse.
  - Permitir transbordo sólo si `busStopsTaken >= minBusLegStopsBeforeTransfer`.
- Evaluación y podado:
  - Rechazar tramos cuyo recorrido (suma de distancias entre paradas) / distancia en línea recta > `detourRatioThreshold` (por ejemplo 2.5).
  - Aplicar `transferPenaltyMinutes` para preferir menos transbordos.
  - Comparar con caminata directa y exigir un ahorro mínimo (`minSavingMinutes`) para mostrar opción en bus.

## Parámetros y heurísticas (valores usados)

- `estimateBusRideMinutes = 2` minutos por parada.
- `transferPenaltyMinutes = 8` minutos por transbordo.
- `minBusLegStopsBeforeTransfer = 2` (no permitir cambiar tras 0–1 paradas para evitar zig-zags).
- `detourRatioThreshold = 2.5`.
- `minSavingMinutes = 2` (umbral para considerar que la ruta en bus compensa frente a caminar).

Estos parámetros están centralizados en `lib/features/map/tourism/utils/tourist_bus_route_planner_helpers.dart` y pueden ajustarse para tuning.

## Implementación: archivos clave (resumen)

- `lib/features/map/tourism/utils/tourist_bus_route_planner_core.dart`
  - Nuevo modelo de estados, lógica de expansión y `_reconstructSegments` robusto.

- `lib/features/map/tourism/utils/tourist_bus_route_planner_helpers.dart`
  - Heurísticas: `estimateWalkingMinutes`, `estimateBusRideMinutes`, `isBusWorthIt`.

- `lib/features/map/services/osrm_routing_service.dart`
  - Encapsula llamadas a OSRM, parseo, manejo de fallback y cálculo de minutos.

- `lib/features/map/services/bus_route_polyline_builder.dart`
  - Construye polilíneas compuestas por tres partes: `walkToBoard`, `busRoute` (puntos de parada en orden) y `walkToPlace`.

- `lib/features/map/viewmodels/map_viewmodel.dart`
  - Orquesta la llamada al planner y la construcción de las polilíneas; ahora expone `touristWalkToBoardRoute`, `touristBusRoute`, `touristWalkToPlaceRoute`.

- `lib/features/map/views/map_layers_builder.dart`
  - Renderiza tres polilíneas con estilos distintos y dibuja paradas intermedias como marcadores pequeños. Boarding y destino con marcadores mayores.

- `lib/features/map/tourism/widgets/tourist_bus_route_sheet.dart`
  - Muestra `plan.routeStops` completo (lista numerada) y resumen de minutos/ahorro.

## Visualización y UX

- Tres polilíneas visuales:
  - `walkToBoard`: estilo punteado/amarillo
  - `busRoute`: línea continua azul con grosor mayor
  - `walkToPlace`: verde
- Marcadores:
  - Paradas intermedias: pequeños puntos grises
  - Parada de subida (boarding) y parada de bajada (alight): marcadores destacados con etiquetas
- Si la caminata directa es corta (< ~12 min por defecto) se muestra sugerencia de caminar y no se obliga al usuario a seleccionar paradas.

## Trazas de debug y reproducción

Se añadieron `debugPrint` en puntos clave para reproducir casos:

- Inicio de planificación:
  - Tag: `[TouristBusRoutePlanner]` — imprimiendo `place`, `destStop`, `segments`, `segmentStops`, `totalStops`.
- Aplicación de plan en `MapViewModel`:
  - Tag: `[MapViewModel] Applying tourist plan` — imprime `place`, `segments`, `routeStops.length`, `polylinePoints`, `busPoints`, `walkToBoardPoints`, `walkToPlacePoints`.

Ejemplo (logs):

```
[TouristBusRoutePlanner] place=Playa del Zapillo destStop=Av.Cabo De Gata 166-Al segments=1 segmentStops=[9] totalStops=9
[MapViewModel] Applying tourist plan: place=Playa del Zapillo segments=2 routeStops=4 polylinePoints=139 busPoints=4 walkToBoardPoints=109 walkToPlacePoints=26
```

Para probar un caso problemático localmente:

1. `flutter run -d <device>` en `V2/almeriarutav02`.
2. Abrir la pantalla del mapa y seleccionar un `TuristicPlace` conocido (ej. `Playa del Zapillo`).
3. Observar la salida de la consola para las trazas anteriores.

Si las `routeStops` no incluyen las paradas intermedias, buscar en la traza `_reconstructSegments` y verificar el `boardingStopId` para cada segmento.

## Pruebas y validación automatizada

- `flutter analyze` se debe ejecutar sobre los ficheros cambiados. En CI se añadió un job que ejecuta `flutter analyze` y `flutter test` para las carpetas `lib/features/map` y `test`.

- Casos de validación manual sugeridos:
  - Origen cercano + destino lejano en la misma línea (ruta en bus directo)
  - Origen cercano + destino cercano (caminar vs bus)
  - Caso que antes sugería zig-zag (líneas con intersecciones múltiples) y validar que ahora se elige ruta ordenada por índiceInLine
  - OSRM con fallo simulando timeout (chequear fallback a segmento en línea recta)

## Rendimiento y consideraciones

- Observación: al construir polilíneas largas con muchas peticiones OSRM se detectaron avisos de UI (skipped frames). Recomendaciones:
  - Ejecutar llamadas OSRM y construcción de puntos en un isolate o en background (compute) para no bloquear el hilo UI.
  - Cachear respuestas OSRM por par de coordenadas por 10–30 minutos.
  - Limitar concurrent requests a 3–4 cuando se ensamblan múltiples tramos.

## Notas de migración y rollback

- Cambios no destructivos: se mantuvo la API pública de `TouristBusRoutePlan` para evitar romper llamadas existentes; los consumidores que esperan una `List<LatLng>` pueden seguir usándolo a través de `BusRoutePolylineBuilder.buildCombined()`.
- Para rollback: restaurar `tourist_bus_route_planner_core.dart` desde el commit anterior y actualizar `MapViewModel` para volver al antiguo flujo.

## Próximos pasos y mejoras posibles

- Añadir métricas de A/B para comparar tiempo real usuario (clics / aceptación de ruta) entre heurísticas (transferPenalty, detourRatio).
- Permitit profiles diferenciales por línea (por ejemplo tramos interurbanos con tiempos por parada distintos).
- Implementar caching de OSRM con ETags/TTL en un servicio común.

## Apéndice — Ubicaciones de código (edición)

- `lib/features/map/tourism/utils/tourist_bus_route_planner_core.dart`
- `lib/features/map/tourism/utils/tourist_bus_route_planner_helpers.dart`
- `lib/features/map/services/osrm_routing_service.dart`
- `lib/features/map/services/bus_route_polyline_builder.dart`
- `lib/features/map/viewmodels/map_viewmodel.dart`
- `lib/features/map/views/map_layers_builder.dart`
- `lib/features/map/tourism/widgets/tourist_bus_route_sheet.dart`

---

Si quieres, aplico ahora ejemplos concretos en la doc (snippets antes/después extraídos de los commits) y añado la sección de comandos reproducibles para CI (YAML). ¿Lo hago? 

