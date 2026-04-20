# Refactorización del Mapa, Rutas Turísticas y Seguridad del Backend

## Índice

1. [Seguridad del backend](#1-seguridad-del-backend)
2. [Onboarding y filtrado inteligente del mapa](#2-onboarding-y-filtrado-inteligente-del-mapa)
3. [Algoritmo de rutas turísticas en bus — Dijkstra DP](#3-algoritmo-de-rutas-turísticas-en-bus--dijkstra-dp)
4. [Polilínea real con OSRM](#4-polilínea-real-con-osrm)
5. [Refactorización del MapViewModel](#5-refactorización-del-mapviewmodel)
6. [Refactorización de vistas del mapa](#6-refactorización-de-vistas-del-mapa)
7. [Tests unitarios del módulo auth](#7-tests-unitarios-del-módulo-auth)
8. [Estructura de archivos resultante](#8-estructura-de-archivos-resultante)

---

## 1. Seguridad del backend

### Sanitización de inputs (XSS)

`service.py` devolvía inputs del usuario directamente en respuestas JSON. Se añadió `html.escape()` en los puntos de entrada:

```python
@staticmethod
def _sanitize(value: str) -> str:
    return html.escape(str(value).strip())
```

Aplicado en `register`, `login` y `purchase_ticket` sobre campos de texto libre (`username`, `identifier`, `sender_username`, `ticket_type`, `payment_method`). Las contraseñas y PINs no se sanitizan porque se hashean directamente y nunca se devuelven.

### Datetimes con timezone

Todos los `datetime.now()` reemplazados por `datetime.now(timezone.utc)` en `almeria_busmaps_api.py` y `auth_mvc/service.py` para evitar ambigüedades con horario de verano/invierno.

---

## 2. Onboarding y filtrado inteligente del mapa

### Primera vez en el mapa

Al abrir el mapa por primera vez se muestra un tutorial con `SharedPreferences` para no repetirlo:

```dart
// shared/services/onboarding_service.dart
static Future<bool> isDone() async { ... }
static Future<void> setDone() async { ... }
```

El tutorial explica las tres funciones principales con iconos:

- Filtrar por líneas
- Buscar paradas o zonas
- Guardar favoritos

Tras el tutorial aparece un selector opcional de línea favorita con el mismo diseño de cards que `lines_view.dart` (círculo de color, nombre completo, frecuencia).

### Filtrado por proximidad por defecto

Sin línea seleccionada, solo se muestran paradas en un radio de **800 metros** del usuario:

```dart
static const double _nearbyRadius = 800;

// En _filteredStops():
if (_selectedLineId == null && _userLocation != null) {
  if (distance > _nearbyRadius) return false;
}
```

Con línea seleccionada se muestran todas las paradas de esa línea sin límite de distancia.

### Botón ℹ️ permanente

El tutorial es accesible en cualquier momento desde el AppBar del mapa para que el usuario pueda repasar las instrucciones.

---

## 3. Algoritmo de rutas turísticas en bus — Dijkstra DP

### Problema con el algoritmo anterior (greedy)

El algoritmo anterior evaluaba cada línea de forma independiente y buscaba la parada de subida más cercana al usuario entre todas las paradas anteriores al destino en la secuencia. Esto producía rutas incorrectas:

- Proponía L2 → L18 cuando L18 ya iba directo a Torrecardenas
- No verificaba que el bus avanzara geográficamente hacia el destino
- Podía proponer subirse en una parada que estuviera en dirección contraria

### Solución: Dijkstra sobre paradas

Cada parada de bus es un nodo. El coste acumulado es tiempo real:

```
coste(nodo) = minutos_caminando_hasta_primera_parada
            + minutos_en_bus (por paradas reales recorridas)
            + penalización_transbordo (8 min por cambio de línea)
```

El algoritmo expande por todas las paradas intermedias reales de cada secuencia, no solo origen y destino.

### Filtro de desvío geográfico (detour ratio)

Para cada tramo de bus se calcula:

```dart
final routeDistance = _distanceAlongStops(stopsInSegment);
final straightDistance = Geolocator.distanceBetween(...boarding, ...destination);

if (routeDistance / straightDistance > 2.5) break; // descartado
```

Si el bus recorre más de 2.5 veces la distancia en línea recta entre subida y bajada, ese tramo se descarta. Esto elimina rutas que van en dirección contraria (ej. L18 hacia Costacabana cuando el destino es Torrecardenas al norte).

### Penalización de transbordos

```dart
const transferPenaltyMinutes = 8;
final adjusted = totalDurationMinutes + (segments.length - 1) * transferPenaltyMinutes;
```

Una ruta directa siempre gana a una con transbordo salvo que el transbordo ahorre más de 8 minutos reales.

### Comparativa con caminar

Antes de mostrar cualquier ruta en bus se compara con ir caminando directamente:

```dart
bool isBusWorthIt(TouristBusRoutePlan plan, double directWalkMeters, {int minSavingMinutes = 5}) {
  final directWalkMinutes = estimateWalkingMinutes(directWalkMeters);
  return (directWalkMinutes - plan.totalDurationMinutes) >= minSavingMinutes;
}
```

Si el destino está a menos de 12 minutos caminando, se muestra un snackbar directo sin abrir el selector de paradas.

### Tiempo por parada corregido

`estimateBusRideMinutes` usaba 3 min/parada. Corregido a **2 min/parada**, más realista para líneas urbanas de Almería.

---

## 4. Polilínea real con OSRM

### Problema anterior

`routePoints` del plan eran solo las coordenadas de las paradas (puntos discretos). La línea en el mapa atravesaba edificios porque conectaba paradas con líneas rectas.

### Solución: OSRM por cada tramo

`BusRoutePolylineBuilder` construye la polilínea completa llamando a OSRM por cada segmento:

```
usuario → parada_subida          (perfil: walking)
parada_1 → parada_2              (perfil: driving)
parada_2 → parada_3              (perfil: driving)
...
última_parada → destino_turístico (perfil: walking)
```

El perfil `driving` para los tramos de bus sigue las calles por donde circula el autobús. El perfil `walking` para los tramos a pie sigue aceras y caminos peatonales.

Si OSRM falla en algún tramo, ese tramo cae a línea recta como fallback sin romper el resto de la polilínea.

```dart
// services/bus_route_polyline_builder.dart
Future<List<LatLng>> build(TouristBusRoutePlan plan, LatLng userLocation) async {
  // 1. Walk to boarding
  // 2. Bus legs (driving profile, stop by stop)
  // 3. Walk to place
}
```

---

## 5. Refactorización del MapViewModel

### Problema

`MapViewModel` tenía ~350 líneas mezclando cuatro responsabilidades:

- Lógica HTTP de OSRM (parseo JSON, fallback)
- Carga y deduplicación de paradas desde la API
- Construcción de polilíneas de bus
- Gestión de estado del mapa

### Servicios extraídos

**`map/services/osrm_routing_service.dart`**

Toda la lógica de OSRM: petición HTTP, parseo de coordenadas, validación de velocidad, fallback a línea recta y cálculo de minutos caminando.

```dart
class OsrmRoutingService {
  Future<RouteResult> getRoute(LatLng from, LatLng to, {String profile = 'walking'})
  Future<List<LatLng>> getSegmentPoints(LatLng from, LatLng to, {String profile})
  static int walkMinutes(double meters)
}
```

**`map/services/stop_loader_service.dart`**

Carga paralela de líneas y paradas con deduplicación:

```dart
class StopLoaderService {
  Future<({List<LineModel> lines, List<StopModel> stops})> load()
}
```

**`map/services/bus_route_polyline_builder.dart`**

Construcción de la polilínea completa para rutas turísticas en bus.

```dart
class BusRoutePolylineBuilder {
  Future<List<LatLng>> build(TouristBusRoutePlan plan, LatLng userLocation)
}
```

### MapViewModel resultante

~250 líneas, solo orquestación. Los servicios son inyectables por constructor para facilitar tests:

```dart
MapViewModel({
  OsrmRoutingService? routing,
  StopLoaderService? stopLoader,
  BusRoutePolylineBuilder? polylineBuilder,
})
```

---

## 6. Refactorización de vistas del mapa

### Widgets extraídos

**`widgets/tourist_bus_stop_info_sheet.dart`**

El bottom sheet que se mostraba inline en `_showTouristBusStopInfo` dentro del State. Ahora es un `StatelessWidget` con props tipadas:

```dart
class TouristBusStopInfoSheet extends StatelessWidget {
  final StopModel stop;
  final TouristBusRoutePlan? plan;
  final TouristPlace? selectedPlace;
}
```

**`views/map_widget.dart`**

El `FlutterMap` con todos sus callbacks extraído a un widget dedicado con interfaz clara:

```dart
class MapWidget extends StatelessWidget {
  final MapController mapController;
  final MapViewModel mapViewModel;
  final TourismViewModel tourismViewModel;
  final void Function(StopModel) onStopTap;
  final void Function(StopModel) onTouristBusStopTap;
  // ...
}
```

**`views/optimized_map_view.dart`**

Reducido de ~230 a ~140 líneas. Solo orquesta los widgets y handlers. El `AppBar` se extrajo a `_MapAppBar` (widget privado con `PreferredSizeWidget`).

### Estructura de vistas resultante

```
views/
├── optimized_map_view.dart    ← orquestación
├── map_widget.dart            ← FlutterMap + callbacks
├── map_layers_builder.dart    ← capas del mapa
├── map_overlays_builder.dart  ← overlays UI
├── map_fab_actions.dart       ← acciones FAB
├── map_initialization.dart    ← init + onboarding
└── map_onboarding_flow.dart   ← tutorial
```

---

## 7. Tests unitarios del módulo auth

Se añadieron **84 tests** organizados en 4 archivos cubriendo todo el módulo de autenticación.

### Archivos de test

| Archivo                                      | Tests | Cobertura                                                         |
| -------------------------------------------- | ----- | ----------------------------------------------------------------- |
| `auth/models/app_user_test.dart`           | 11    | `fromJson` (todos los branches), `toJson`, roundtrip          |
| `auth/utils/auth_validators_test.dart`     | 33    | Todos los validadores con casos válidos, inválidos y edge cases |
| `auth/services/auth_api_service_test.dart` | 14    | Todos los métodos HTTP con respuestas 200 y errores reales       |
| `auth/viewmodels/auth_viewmodel_test.dart` | 26    | Flujos completos con fake service                                 |

### Cambios en producción para habilitar tests

Inyección opcional de dependencias sin alterar comportamiento:

```dart
// AuthViewModel
AuthViewModel({AuthApiService? api}) : _api = api ?? AuthApiService();

// AuthApiService
AuthApiService({http.Client? client}) : _client = client ?? http.Client();
```

### Fake service para ViewModel tests

Se implementó `_FakeAuthApiService` que extiende `AuthApiService` y permite simular éxito o fallo controlado sin red:

```dart
class _FakeAuthApiService extends AuthApiService {
  final bool shouldFail;
  // override login, register, guest, me, updateProfile, changePassword, recoverPassword
}
```

---

## 8. Estructura de archivos resultante

```
lib/features/map/
├── services/                          ← NUEVO
│   ├── osrm_routing_service.dart
│   ├── stop_loader_service.dart
│   └── bus_route_polyline_builder.dart
├── viewmodels/
│   └── map_viewmodel.dart             ← reducido, solo orquestación
├── views/
│   ├── map_widget.dart                ← NUEVO
│   ├── optimized_map_view.dart        ← reducido
│   └── ...
├── widgets/
│   ├── tourist_bus_stop_info_sheet.dart ← NUEVO
│   └── ...
└── tourism/
    └── utils/
        └── tourist_bus_route_planner_core.dart ← Dijkstra DP

lib/shared/services/
└── onboarding_service.dart            ← NUEVO

backend/
├── .env.example                       ← NUEVO
├── .env                               ← NUEVO (no versionado)
└── auth_mvc/
    ├── service.py                     ← sanitización XSS, timezone UTC
    └── repository.py                  ← sin credenciales hardcodeadas
```
