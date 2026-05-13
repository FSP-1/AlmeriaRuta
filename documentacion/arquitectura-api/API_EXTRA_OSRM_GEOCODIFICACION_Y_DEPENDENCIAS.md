# API Extra: OSRM, Geocodificacion y Dependencias de la App

## Objetivo

Este documento complementa la documentacion principal de conexion API-app y explica, con detalle, todo lo que no entra en la API de buses como tal pero que es clave para la experiencia de la aplicacion:

1. Rutas peatonales con **OSRM**.
2. Busqueda y seleccion de ubicaciones con **Nominatim / OpenStreetMap**.
3. Geolocalizacion del dispositivo con **Geolocator**.
4. Mapa interactivo con **flutter_map** y dependencias asociadas.
5. Servicios de autenticacion, tickets y notificaciones que consumen la API de backend.
6. Relacion exacta entre cada archivo Dart y el flujo que usa la app.

---

## 1. Resumen de Integracion

La app Flutter usa varias capas de servicio, cada una con una responsabilidad concreta:

| Capa | Archivo principal | Responsabilidad |
|---|---|---|
| Configuracion | `lib/core/constants/app_constants.dart` | Define las URLs base del backend |
| Mapa y rutas | `lib/features/map/viewmodels/map_viewmodel.dart` | Carga ubicaciones, paradas y rutas peatonales |
| Busqueda de ubicaciones | `lib/features/map/widgets/search_widget.dart` | Geocodifica texto a coordenadas |
| Mapa principal | `lib/features/map/views/optimized_map_view.dart` | Pantalla principal con filtros, capas, busqueda y rutas |
| Info de parada | `lib/features/map/widgets/stop_info_sheet.dart` | Distancia y tiempo andando |
| API de autenticacion | `lib/features/auth/services/auth_api_service.dart` | Login, registro, invitado y perfil |
| API de notificaciones | `lib/features/notifications/services/backend_notifications_api_service.dart` | Lectura, marcado y borrado |
| API de tickets | `lib/features/tickets/services/ticket_purchase_api_service.dart` | Validacion de destinatario y compra |

---

## 2. Dependencias Flutter Implicadas

### 2.1 `pubspec.yaml`

Dependencias relevantes para este bloque funcional:

```yaml
dependencies:
  http: ^1.2.2
  geolocator: ^14.0.2
  flutter_map: ^8.2.2
  latlong2: ^0.9.1
  shared_preferences: ^2.2.2
  flutter_local_notifications: ^21.0.0
  qr_flutter: ^4.1.0
  provider: ^6.1.2
  timezone: ^0.11.0
  flutter_timezone: ^5.0.2
```

### 2.2 Para que se usa cada una

| Paquete | Uso real en la app |
|---|---|
| `http` | Peticiones a OSRM, Nominatim y al backend Flask |
| `flutter_map` | Render del mapa principal y capas vectoriales |
| `latlong2` | Modelo de coordenadas `LatLng` |
| `geolocator` | GPS, permisos, distancia entre puntos |
| `shared_preferences` | Persistencia local de favoritos, onboarding y estado |
| `flutter_local_notifications` | Notificaciones locales del dispositivo |
| `qr_flutter` | Generacion visual de QR para validacion |
| `provider` | Inyeccion y consumo de ViewModels |
| `timezone` / `flutter_timezone` | Programacion de notificaciones locales |

Nota de mantenimiento: `location_picker_flutter_map`, `flutter_map_tile_caching` y `cupertino_icons` pueden aparecer declaradas en `pubspec.yaml`, pero no tienen uso activo detectado en `lib/` tras la consolidacion del mapa principal.

---

## 3. Configuracion de URLs Base

### Archivo: `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  static const String appName = 'AlmeriaRuta V2';
  static const String apiBaseUrl = 'http://10.0.2.2:5000';
  static const String authApiBaseUrl = 'http://10.0.2.2:5001';
}
```

### Significado

| Constante | Usa |
|---|---|
| `apiBaseUrl` | Backend de buses: `/lines`, `/stops`, `/arrivals` |
| `authApiBaseUrl` | Backend de autenticacion: `/auth/*` |

### Por que `10.0.2.2`

En Android Emulator, `10.0.2.2` apunta al `localhost` del equipo anfitrion. Eso permite que la app del emulador llegue al backend Python que corre en la misma maquina de desarrollo.

---

## 4. Geocodificacion de Búsqueda

### Archivo: `lib/features/map/widgets/search_widget.dart`

Este widget permite escribir una direccion, barrio o zona y convertir ese texto en coordenadas reales.

### Flujo funcional

1. El usuario escribe en el `TextField`.
2. Si el texto tiene menos de 3 caracteres, no se busca nada.
3. Primero se comprueba si el texto coincide con un alias de zona local.
4. Si no hay alias, se consulta **Nominatim**.
5. Se muestran sugerencias en una lista.
6. Al tocar una sugerencia, la app devuelve una `LocationModel` a la pantalla padre.

### Aliases locales de zonas

```dart
final normalized = query.toLowerCase().trim();
if (ZoneAliases.aliases.containsKey(normalized)) {
  final zoneName = ZoneAliases.aliases[normalized]!;
```

Esto evita depender de la geocodificacion externa cuando el usuario escribe nombres comunes como:

- `centro`
- `zapillo`
- `universidad`
- `aeropuerto`
- `retamar`

### Endpoint usado por Nominatim

```dart
final url = Uri.parse(
  'https://nominatim.openstreetmap.org/search?'
  'q=$query, Almería, España&'
  'format=json&'
  'limit=5&'
  'bounded=1&'
  'viewbox=-2.55,36.75,-2.35,36.90',
);
```

### Efecto de los parametros

| Parametro | Funcion |
|---|---|
| `q` | Texto de busqueda del usuario |
| `format=json` | Respuesta JSON legible por Flutter |
| `limit=5` | Limita sugerencias para evitar ruido |
| `bounded=1` | Restringe resultados al area definida |
| `viewbox` | Caja geografica aproximada de Almeria |

### Header requerido

```dart
headers: {'User-Agent': 'AlmeriaRuta/1.0.0'},
```

Nominatim recomienda identificar la aplicacion mediante `User-Agent` para evitar bloqueos o limitaciones por peticiones anonimas.

### Modelo devuelto

El resultado se transforma a `LocationModel`:

```dart
LocationModel(
  latitude: double.parse(item['lat']),
  longitude: double.parse(item['lon']),
  address: item['display_name'],
  name: item['name'],
)
```

### Archivos de soporte

- `lib/features/map/models/location_model.dart`
- `lib/features/map/data/zone_aliases.dart`

### Relacion con la UI

El `SearchWidget` no navega por si mismo. Solo devuelve una ubicacion seleccionada mediante el callback `onLocationSelected`. La pantalla que lo contiene decide despues si mueve el mapa, pone un marcador o aplica un filtro.

---

## 5. Mapa Principal y Seleccion de Ubicacion

### Archivo: `lib/features/map/views/optimized_map_view.dart`

La seleccion y busqueda de ubicaciones se integra en la experiencia principal del mapa. El flujo activo combina `OptimizedMapView`, `SearchWidget` y `MapViewModel`, en lugar de una pantalla separada de picker.

### Funcionamiento

1. `SearchWidget` resuelve texto a `LocationModel` mediante alias locales o Nominatim.
2. `OptimizedMapView` recibe la ubicacion seleccionada.
3. `MapViewModel` actualiza foco, rutas o filtros segun el contexto.
4. `flutter_map` renderiza la ubicacion, paradas, zonas y rutas en la misma pantalla.

### Relacion con la app

El usuario no sale del mapa para buscar o seleccionar una ubicacion. Esto reduce navegacion intermedia y mantiene visibles las capas de paradas, favoritos, turismo y ruta activa.

---

## 6. Geolocalizacion del Dispositivo

### Archivo: `lib/features/map/viewmodels/map_viewmodel.dart`

La geolocalizacion real del usuario se obtiene desde `geolocator`.

### Codigo clave

```dart
Future<void> getCurrentLocation() async {
  if (_userLocation != null) return;

  try {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition();
    _userLocation = LatLng(position.latitude, position.longitude);
    notifyListeners();
  } catch (e) {
    _userLocation = const LatLng(36.8381, -2.4597);
    notifyListeners();
  }
}
```

### Que resuelve

1. Solicita permiso de localizacion.
2. Obtiene coordenadas reales.
3. Si falla, usa centro de Almeria como respaldo.
4. Notifica a la UI para recalcular filtros y distancias.

### Uso posterior de la posicion

La ubicacion del usuario se usa para:

- Filtrar paradas cercanas.
- Calcular distancia a una parada.
- Estimar tiempo caminando.
- Pedir ruta peatonal por OSRM.

---

## 7. Rutas Peatonales con OSRM

### Archivo: `lib/features/map/viewmodels/map_viewmodel.dart`

OSRM se usa para dibujar la ruta a pie entre dos puntos.

### Endpoint consumido

```dart
https://router.project-osrm.org/route/v1/walking/{lon1},{lat1};{lon2},{lat2}?overview=full&geometries=geojson
```

### Metodo principal

```dart
Future<RouteResult> getRouteResult(LatLng from, LatLng to) async {
  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/walking/'
    '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
    '?overview=full&geometries=geojson'
  );
```

### Respuesta esperada de OSRM

OSRM devuelve un JSON con un array `routes`, y dentro de cada ruta:

- `geometry.coordinates`
- `distance`
- `duration`

### Conversion interna

```dart
final coords = route['geometry']['coordinates'] as List;
final distanceMeters = (route['distance'] as num?)?.toDouble() ??
    Geolocator.distanceBetween(...);
final osrmDurationSeconds =
    (route['duration'] as num?)?.toDouble() ?? (distanceMeters / _walkingSpeedMps);
```

### Control de calidad de la duracion

No se acepta ciegamente la duracion de OSRM. Si la velocidad implícita supera un limite razonable para caminar, la app sustituye la estimacion por una calculada localmente.

```dart
final osrmSpeedMps = distanceMeters / osrmDurationSeconds;

final durationMinutes = osrmSpeedMps > _maxReasonableWalkingSpeedMps
  ? _estimateWalkingMinutes(distanceMeters)
  : (osrmDurationSeconds / 60).round();
```

### Fallback cuando falla OSRM

Si la peticion falla o el servicio no responde:

1. Se calcula distancia en linea recta con `Geolocator.distanceBetween`.
2. Se genera una ruta de dos puntos `[from, to]`.
3. Se marca `isFallback: true`.
4. Se mantiene experiencia usable aunque no haya ruta real.

### Uso en la app

OSRM se activa cuando la app necesita mostrar una ruta desde:

- la ubicacion del usuario hasta una parada,
- una parada externa abierta desde otra pantalla,
- o un punto seleccionado manualmente.

### Metodo auxiliar relevante

```dart
Future<void> showStopWithRouteFromExternal(StopModel stop) async {
  final from = _userLocation ?? const LatLng(36.8381, -2.4597);
  final route = await getRoute(from, LatLng(stop.lat, stop.lon));
  setRoute(stop, route);
}
```

---

## 8. Mapa Principal y Capas Visuales

### Archivo: `lib/features/map/views/optimized_map_view.dart`

Esta es la vista principal del mapa y es la que junta varias piezas:

- `flutter_map`
- `MapViewModel`
- busqueda por texto
- filtro por zonas
- rutas activas
- capas turísticas
- paradas favoritas

### Capas relevantes

| Capa | Función |
|---|---|
| `TileLayer` | Carga el mapa base de OSM |
| `PolygonLayer` | Resalta la zona seleccionada |
| `PolylineLayer` | Dibuja la ruta activa |
| Marcadores | Pintan paradas y puntos de interes |

### Inicializacion

```dart
Future<void> _initializeMapView() async {
  final vm = context.read<MapViewModel>();
  await vm.initialize();
```

### Flujo con parada inicial

Si la pantalla se abre con una parada concreta:

1. Se mueve la camara al punto de la parada.
2. Si no es modo favoritos, se calcula ruta hacia esa parada.
3. Se ajusta el zoom a 16.
4. Se muestra el contexto correcto sin que el usuario tenga que buscarlo.

### Integracion con filtros

La vista puede abrirse con filtro de favoritos, filtro por linea o filtro por zona. Eso se traduce en llamadas directas al `MapViewModel`.

---

## 9. Capa de Estado del Mapa

### Archivo: `lib/features/map/viewmodels/map_viewmodel.dart`

Este ViewModel centraliza el estado del mapa:

- ubicacion del usuario,
- paradas,
- lineas,
- paradas favoritas,
- rutas activas,
- zona activa,
- errores y estado de carga.

### Carga de paradas

```dart
Future<void> loadStops() async {
  if (_isLoadingStops) return;
  if (_stops.isNotEmpty) return;

  final lines = await _apiService.getLines();
  final uniqueStops = <String, StopModel>{};

  for (final line in lines) {
    final lineId = line.id;
    final stops = await _apiService.getLineStops(lineId);
    for (final stop in stops) {
      if (uniqueStops.containsKey(stop.id)) {
        uniqueStops[stop.id] = uniqueStops[stop.id]!.copyWith(
          lineIds: {...uniqueStops[stop.id]!.lineIds, lineId},
        );
      } else {
        uniqueStops[stop.id] = stop.copyWith(lineIds: {lineId});
      }
    }
  }
```

### Razon de esta logica

La misma parada puede pertenecer a mas de una linea. Por eso el modelo `StopModel` incluye `lineIds`, y la app fusiona duplicados para que una sola parada conserve todas sus lineas asociadas.

### Filtro por cercania

```dart
final distance = Geolocator.distanceBetween(
  _userLocation!.latitude,
  _userLocation!.longitude,
  stop.lat,
  stop.lon,
);
return distance <= 800;
```

### Filtro por zona

Se apoya en `AlmeriaZones.isPointInsidePolygon(...)` para comprobar si la parada cae dentro de una zona transportable.

### Ruta activa

`RouteResult` conserva:

- lista de puntos,
- metros totales,
- minutos estimados,
- si se uso fallback o no.

Eso permite que la interfaz dibuje una linea real o una aproximacion simple sin romper la pantalla.

---

## 10. Informacion de Parada

### Archivo: `lib/features/map/widgets/stop_info_sheet.dart`

Este widget muestra el detalle de una parada en una hoja inferior.

### Datos calculados localmente

```dart
final distance = Geolocator.distanceBetween(
  userLocation!.latitude,
  userLocation!.longitude,
  stop.lat,
  stop.lon,
);

final timeInSeconds = distance / 1.39;
final timeInMinutes = (timeInSeconds / 60).round();
```

### Contenido mostrado

- Nombre de la parada.
- Lineas que la usan.
- Distancia en metros.
- Tiempo caminando estimado.
- Accion de favoritos.
- Boton “Como llegar”.

### Relacion con favoritos

El widget monta temporalmente un `FavoritesViewModel` y permite guardar o eliminar una parada favorita sin salir de la hoja.

---

## 11. Servicios HTTP de Autenticacion, Tickets y Notificaciones

### 11.1 `auth_api_service.dart`

#### Uso

Consume la API de autenticacion en `http://10.0.2.2:5001`.

#### Endpoints consumidos

| Metodo | Endpoint | Uso |
|---|---|---|
| `POST` | `/auth/login` | Iniciar sesion |
| `POST` | `/auth/register` | Crear usuario |
| `POST` | `/auth/guest` | Entrar como invitado |
| `GET` | `/auth/me` | Recuperar perfil autenticado |

#### Flujo de parseo

El servicio devuelve una tupla:

```dart
Future<(String, AppUser)> login(...)
```

Donde:

- el primer valor es el token,
- el segundo es el usuario modelado.

### 11.2 `backend_notifications_api_service.dart`

#### Uso

Gestiona las notificaciones persistidas en backend.

#### Endpoints consumidos

| Metodo | Endpoint | Uso |
|---|---|---|
| `GET` | `/auth/notifications` | Listar notificaciones |
| `POST` | `/auth/notifications/{id}/read` | Marcar como leida |
| `DELETE` | `/auth/notifications/{id}` | Eliminar notificacion |

#### Detalle del flujo

1. Recibe token Bearer.
2. Lee JSON de respuesta.
3. Convierte cada item a `UserNotification`.
4. Permite resolver `payloadJson` para abrir contexto de compra o ticket.

### 11.3 `ticket_purchase_api_service.dart`

#### Uso

Se conecta al backend de auth para validar destinatario o registrar una compra de ticket.

#### Llamadas

| Metodo | Endpoint | Uso |
|---|---|---|
| `POST` | `/auth/tickets/purchase` | Validar destinatario |
| `POST` | `/auth/tickets/purchase` | Notificar compra |

#### Modo validacion

```dart
body: jsonEncode({
  'recipientIdentifier': recipientIdentifier,
  'validateOnly': true,
})
```

#### Modo compra real

```dart
body: jsonEncode({
  'recipientIdentifier': recipientIdentifier,
  'type': type,
  'quantity': quantity,
  'amount': amount,
  'paymentMethod': paymentMethod,
})
```

### Relacion con el backend

Estos servicios dependen de que el backend Auth mantenga usuarios, notificaciones y tickets coherentes. La app no accede directamente a MySQL: siempre entra por HTTP.

---

## 12. Flujo Completo de Uso en la App

### Caso 1: Buscar una direccion y abrir el mapa

1. El usuario escribe una direccion en `SearchWidget`.
2. Si coincide con un alias local, la app resuelve la zona inmediatamente.
3. Si no, consulta Nominatim.
4. La UI recibe una `LocationModel`.
5. `OptimizedMapView` mueve el mapa o actualiza el foco.
6. Si hay una parada concreta, `MapViewModel` puede calcular ruta con OSRM.

### Caso 2: Abrir la informacion de una parada cercana

1. El mapa obtiene la posicion actual con `Geolocator`.
2. `MapViewModel` filtra paradas a menos de 800 metros.
3. El usuario abre una parada.
4. `StopInfoSheet` calcula distancia y tiempo caminando.
5. Si pulsa “Como llegar”, se usa la ruta activa.

### Caso 3: Login y notificaciones

1. `AuthApiService` envia credenciales a `/auth/login`.
2. El backend devuelve token y perfil.
3. La app guarda el token en estado local.
4. `BackendNotificationsApiService` usa ese token para leer notificaciones.
5. `TicketPurchaseApiService` usa el mismo token para validar o notificar compras.

---

## 13. Problemas Reales que Estas Capas Resuelven

| Problema | Solucion aplicada |
|---|---|
| No tener direccion exacta | Geocodificacion con Nominatim |
| Necesitar una zona en vez de una direccion | Aliases locales de zonas |
| No saber donde esta el usuario | GPS con Geolocator |
| Querer una ruta peatonal visual | OSRM |
| No querer saturar la red | Carga guiada desde ViewModels y caches |
| Necesitar feedback rapido en mapa | `flutter_map` + capas separadas |
| Tener compras y notificaciones persistentes | API Auth con token Bearer |

---

## 14. Dependencias y Archivos por Funcionalidad

| Funcionalidad | Archivos clave |
|---|---|
| Geocodificacion | `search_widget.dart`, `location_model.dart`, `zone_aliases.dart` |
| GPS del usuario | `map_viewmodel.dart`, `stop_info_sheet.dart` |
| Ruta peatonal | `map_viewmodel.dart` |
| Seleccion de ubicacion | `optimized_map_view.dart`, `search_widget.dart` |
| Mapa principal | `optimized_map_view.dart`, `map_widget.dart`, `map_overlays_builder.dart` |
| API de autenticacion | `auth_api_service.dart` |
| Notificaciones backend | `backend_notifications_api_service.dart` |
| Compra de tickets | `ticket_purchase_api_service.dart` |
| Configuracion de URLs | `app_constants.dart` |

---

## 15. Conclusiones Tecnicas

La parte de OSRM, geocodificacion y dependencias no es un extra decorativo: es la capa que convierte la app en una experiencia utilizable. El backend entrega los datos estructurados de transporte, pero la navegacion real del usuario depende de:

- encontrar lugares en texto natural,
- convertir ese texto en coordenadas,
- obtener la posicion real del dispositivo,
- trazar rutas peatonales comprensibles,
- y mantener sincronizados login, tickets y notificaciones.

En conjunto, estas piezas son las que permiten que AlmeriaRuta no sea solo un visor de paradas, sino una app completa de movilidad urbana.
