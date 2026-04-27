# Cambios de turismo, rutas y caché

## Resumen

Se refactorizó la parte de turismo y rutas del mapa para mejorar mantenibilidad, separar responsabilidades y dejar la lógica de cálculo más clara.

## Qué se hizo

### 1. Refactorización de turismo

- `tourist_place_sheet.dart` se dividió en módulos más pequeños para sheets, direcciones e instrucciones.
- `tourist_bus_route_planner.dart` se dividió en modelos, lógica principal y helpers.
- `optimized_map_view.dart` quedó más limpio y usa los módulos nuevos sin perder funcionalidad.

### 2. Cálculo de rutas

- La ruta a pie hacia paradas o lugares turísticos se calcula en `MapViewModel`.
- El cálculo usa OSRM para obtener la geometría real de la ruta caminando.
- Si OSRM falla, se usa un fallback en línea recta entre origen y destino.
- El tiempo de caminata se estima con una velocidad media de 1.39 m/s.
- Para rutas turísticas en bus, el planner evalúa rutas directas y con transbordo.
- La app rechaza planes de bus que no aportan ventaja real frente a ir andando.

### 2.1 Actualización abril 2026: planner multi-línea más estable

- Se reforzó el estado interno del planner para evitar rutas "zig-zag" en escenarios con varias líneas.
- El estado de búsqueda ahora tiene anclaje de línea y dirección para no mezclar recorridos incompatibles dentro del mismo tramo.
- El movimiento en bus se hace por avance de una parada a la siguiente, evitando saltos largos dentro de una línea.
- Se añadió control de transbordo por progreso del tramo: no permite cambios de línea demasiado pronto.
- La reconstrucción de segmentos se simplificó para agrupar por `(lineId + boardingStopId)` y recuperar paradas intermedias completas.
- Se corrigió el orden de `routeStops` para mantener dirección real del trayecto cuando cambian índices de origen/destino en la secuencia.

### 2.2 Priorización de opciones al usuario

- En el selector de paradas turísticas, las opciones se ordenan por calidad real del plan:
	- plan válido primero,
	- menor duración total,
	- menos transbordos,
	- menor distancia al punto turístico.
- En cada opción se muestra también el número de paradas del plan de bus para dar más contexto al usuario.

### 2.3 Visualización de ruta y paradas

- La polilínea turística se divide por tramos:
	- caminata de ida (OSRM walking),
	- bus (secuencia real de paradas del plan),
	- caminata final (OSRM walking).
- En modo ruta turística se muestran paradas intermedias como puntos pequeños y extremos destacados (subida/bajada).
- En la hoja de ruta se añadió listado numerado completo de `routeStops` (Subida, Intermedia, Bajada), además de chips.

### 2.4 Diagnóstico y trazabilidad

- Se añadieron trazas de depuración para verificar cuántas paradas produce el planner por segmento y en total.
- También se registran métricas al aplicar el plan en `MapViewModel` (`routeStops`, puntos de polilínea y tramos).
- Estas trazas permiten diferenciar rápidamente si una pérdida de paradas ocurre en algoritmo o en la capa de presentación.

### 3. Caché de datos

- `BusApiService` guarda líneas y paradas en memoria y también en `SharedPreferences`.
- Esa caché persistente tiene TTL de 24 horas.
- Si la caché expira, se limpia y se vuelve a descargar desde la API.
- También existe caché en memoria para llegadas por línea y por parada.
- `LinesViewModel` mantiene caché en memoria para paradas por línea.

### 4. Sesión de autenticación

- La contraseña no se guarda en caché.
- Lo que se persiste es la sesión del usuario: token, datos del usuario y avatar.
- Esa persistencia se hace con `SharedPreferences` para mantener el login entre aperturas de la app.
- Si la sesión deja de ser válida, se cierra automáticamente.

## Validación

- Se validó la compilación del módulo de mapa sin errores.
- Se ejecutaron los tests relevantes de mapa y turismo.
- Resultado final de la última validación limpia: `17` tests pasando.

## Archivos clave

- `lib/features/map/viewmodels/map_viewmodel.dart`
- `lib/features/map/tourism/utils/tourist_bus_route_planner_core.dart`
- `lib/features/map/tourism/utils/tourist_bus_route_planner_helpers.dart`
- `lib/features/map/services/bus_route_polyline_builder.dart`
- `lib/features/map/views/map_layers_builder.dart`
- `lib/features/map/tourism/widgets/tourist_bus_stops_sheet.dart`
- `lib/features/map/tourism/widgets/tourist_bus_route_sheet.dart`
- `lib/shared/services/bus_api_service.dart`
- `lib/features/auth/viewmodels/auth_viewmodel.dart`