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
- `lib/shared/services/bus_api_service.dart`
- `lib/features/auth/viewmodels/auth_viewmodel.dart`