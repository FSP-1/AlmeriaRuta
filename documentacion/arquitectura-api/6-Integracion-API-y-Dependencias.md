# 6.- Integración API y dependencias técnicas

## Objetivo

Documentar de forma detallada cómo se conecta la aplicación Flutter con el backend API, qué servicios externos se integran (incluyendo OSRM) y qué dependencias/plugins sostienen esta arquitectura.

## 6.1 Arquitectura de conexión app-backend

### 6.1.1 Flujo funcional

1. La vista solicita una operación al ViewModel.
2. El ViewModel delega en `BusApiService`.
3. `BusApiService` construye la URL y realiza la petición HTTP.
4. El backend Flask responde JSON.
5. El servicio transforma JSON a modelos (`LineModel`, `StopModel`, etc.).
6. El ViewModel actualiza estado y notifica con `notifyListeners()`.

### 6.1.2 Configuración base

Archivo: [V2/almeriarutav02/lib/core/constants/app_constants.dart](../../V2/almeriarutav02/lib/core/constants/app_constants.dart)

```dart
class AppConstants {
  static const String appName = 'AlmeriaRuta V2';
  static const String apiBaseUrl = 'http://10.0.2.2:5000';
}
```

Explicación breve:
- `apiBaseUrl` centraliza el host del backend para evitar hardcodeo en múltiples módulos.
- En emulador Android se usa `10.0.2.2` para apuntar al `localhost` de la máquina host.

## 6.2 Backend API (Flask + GTFS)

Archivo principal: [backend/almeria_busmaps_api.py](../../backend/almeria_busmaps_api.py)

### 6.2.1 Endpoints publicados

- `GET /lines`
- `GET /lines/<line_id>/stops`
- `GET /lines/<line_id>/arrivals`
- `GET /stops/<stop_id>/arrivals`

```python
@app.route('/lines')
def get_lines():
    return jsonify(client.get_almeria_lines())

@app.route('/lines/<line_id>/stops')
def get_line_stops(line_id):
    ...

@app.route('/lines/<line_id>/arrivals')
def get_line_arrivals(line_id):
    return jsonify(client.get_line_arrivals(line_id))

@app.route('/stops/<stop_id>/arrivals')
def get_stop_arrivals(stop_id):
    limit = request.args.get('limit', default=3, type=int)
    return jsonify(client.get_stop_arrivals(stop_id, limit=limit))
```

Explicación breve:
- `lines` y `stops` alimentan Home, Líneas y Mapa.
- `arrivals` por línea/parada soporta tiempos de llegada y notificaciones.

### 6.2.2 Fuente y procesamiento de datos

El backend carga GTFS desde `alsa-autobuses.zip`, normaliza `stop_id`, filtra rutas urbanas de Almería y construye estructuras listas para la app.

```python
with zipfile.ZipFile(gtfs_path) as z:
    self.routes = pd.read_csv(z.open("routes.txt"))
    self.stops = pd.read_csv(z.open("stops.txt"))
    self.trips = pd.read_csv(z.open("trips.txt"))
    self.stop_times = pd.read_csv(z.open("stop_times.txt"))
```

Explicación breve:
- El backend no depende de base de datos externa en tiempo real para estas operaciones.
- Trabaja sobre GTFS y calcula próximas llegadas con lógica temporal interna.

## 6.3 Capa API en Flutter

Archivo: [V2/almeriarutav02/lib/shared/services/bus_api_service.dart](../../V2/almeriarutav02/lib/shared/services/bus_api_service.dart)

### 6.3.1 Servicio centralizado

```dart
class BusApiService {
  static List<LineModel>? _linesCache;
  static Future<List<LineModel>>? _inFlightLines;
  static final Map<String, List<StopModel>> _stopsCache = {};
  static final Map<String, Future<List<StopModel>>> _inFlightStops = {};

  Future<List<LineModel>> getLines({bool forceRefresh = false}) async {
    if (!forceRefresh && _linesCache != null) return _linesCache!;
    if (!forceRefresh && _inFlightLines != null) return _inFlightLines!;

    final future = _fetchLines();
    _inFlightLines = future;
    try {
      final lines = await future;
      _linesCache = lines;
      return lines;
    } finally {
      _inFlightLines = null;
    }
  }
}
```

Explicación breve:
- Evita duplicación de llamadas con caché y peticiones en vuelo.
- Mejora latencia percibida y estabilidad al navegar entre pantallas.

### 6.3.2 Resiliencia de red

```dart
Future<http.Response> _getWithRetry(Uri uri) async {
  const attempts = 2;
  for (var i = 0; i < attempts; i++) {
    try {
      return await _client.get(uri).timeout(const Duration(seconds: 12));
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw Exception('Error de red en $uri');
}
```

Explicación breve:
- Timeout para no bloquear la UI indefinidamente.
- Retry corto para mitigar fallos de red puntuales.

## 6.4 Integración con MVVM

Ejemplo: [V2/almeriarutav02/lib/features/home/viewmodels/home_viewmodel.dart](../../V2/almeriarutav02/lib/features/home/viewmodels/home_viewmodel.dart)

```dart
Future<void> loadLines({bool forceRefresh = false}) async {
  _isLoading = true;
  notifyListeners();
  _lines = await _apiService.getLines(forceRefresh: forceRefresh);
  _isLoading = false;
  notifyListeners();
}
```

Explicación breve:
- El ViewModel orquesta caso de uso y estado.
- La vista consume datos/estado sin conocer detalles HTTP.

## 6.5 OSRM y servicios externos

### 6.5.1 Routing peatonal (OSRM)

Archivo: [V2/almeriarutav02/lib/features/map/viewmodels/map_viewmodel.dart](../../V2/almeriarutav02/lib/features/map/viewmodels/map_viewmodel.dart)

```dart
final url = Uri.parse(
  'https://router.project-osrm.org/route/v1/walking/'
  '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
  '?overview=full&geometries=geojson'
);
```

Explicación breve:
- Se utiliza OSRM público para ruta peatonal real.
- Si falla el servicio, la app aplica fallback a línea recta.

### 6.5.2 Geocodificación de direcciones

La búsqueda de direcciones en mapa se apoya en Nominatim/OpenStreetMap (vía widgets/servicios de mapa).

## 6.6 Dependencias/plugins del proyecto

### 6.6.1 Nota sobre `pom.xml`

En este repositorio no existe `pom.xml` (no es un proyecto Java/Maven). La gestión de dependencias se realiza con:

- Flutter/Dart: `pubspec.yaml`
- Backend Python: paquetes instalados para Flask

### 6.6.2 Dependencias Flutter principales

Archivo: [V2/almeriarutav02/pubspec.yaml](../../V2/almeriarutav02/pubspec.yaml)

- `provider`: gestión de estado MVVM.
- `http`: cliente HTTP para API y servicios externos.
- `flutter_map` + `latlong2`: visualización cartográfica.
- `geolocator`: GPS y cálculo de distancia.
- `qr_flutter`: generación de códigos QR.
- `shared_preferences`: persistencia local (favoritos, ajustes).
- `flutter_local_notifications`: notificaciones locales.
- `timezone` y `flutter_timezone`: soporte de programación horaria.

Dependencias declaradas pendientes de limpieza si no se reintroduce su uso:

- `location_picker_flutter_map`: pertenecia al selector antiguo `map_view.dart`, que ya no forma parte del flujo activo.
- `flutter_map_tile_caching`: no tiene uso activo detectado en `lib/`.
- `cupertino_icons`: no tiene uso activo detectado en `lib/`.

### 6.6.3 Dependencias backend Python

Según documentación operativa: [README.md](../../README.md)

```bash
pip install flask flask-cors pandas
```

- `flask`: servidor API.
- `flask-cors`: habilita CORS para consumo desde la app.
- `pandas`: procesamiento de datos GTFS.

## 6.7 Optimización y buenas prácticas

### 6.7.1 Medidas aplicadas

- Caché en memoria para líneas/paradas/llegadas.
- Deduplicación de requests concurrentes (`_inFlight...`).
- Guardas de ciclo de vida en ViewModels para evitar recargas innecesarias.
- Timeout + retry para robustez de red.

### 6.7.2 Recomendaciones de mantenimiento

- Mantener `BusApiService` como única puerta HTTP en Flutter.
- Evitar llamadas HTTP directas desde vistas.
- Usar `forceRefresh` solo en acciones explícitas del usuario.
- Mantener trazabilidad de endpoints y contratos de modelo.

## 6.8 Resultado esperado

- Integración API-app estable y trazable.
- Rendimiento consistente en navegación entre módulos.
- Arquitectura técnica clara para mantenimiento y evolución.
