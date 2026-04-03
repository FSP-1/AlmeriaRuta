# AlmeriaRuta

Aplicación móvil Flutter para consultar servicios de **movilidad municipal** de Almería: transporte público, estacionamiento regulado, parkings, bicicletas compartidas, patinetes y mucho más. 🚌🚗🚴‍♂️🛴

## Características

### 👤 Acceso por tipo de usuario

- **No registrado**: puede acceder a Líneas, Mapa, Tickets y Notificaciones de bus.
- **Registrado**: además habilita recargas, pago con saldo, bandeja personal de tickets recibidos y compra para otro usuario.

### 🚌 Transporte Público

- **Líneas urbanas reales**: 16 líneas de autobús urbano (L1-L31) con datos oficiales GTFS de ALSA
- **Mapa interactivo**: Visualización de paradas con filtros por cercanía, favoritas y línea
- **Geolocalización**: GPS integrado con cálculo de distancias
- **Navegación real**: Rutas caminando usando OSRM que siguen calles reales
- **Datos en tiempo real**: API Flask procesando GTFS de ALSA
- **Filtros avanzados**: Cercanas, todas, favoritas y por línea con buscador
- **Notificaciones locales**: aviso de caducidad de mensual (3 días antes) y aviso de llegada (X min) por parada/línea

### 🗺️ Turismo y orientación

- **Modo turístico en mapa**: Puntos de interés por categoría (playas, museos, monumentos, parques, compras, puerto y ocio)
- **Filtro turístico compacto**: Selector en bottom sheet para reducir espacio en pantalla
- **Ruta automática a lugar turístico**: Acción "Como llegar" desde el detalle del POI
- **Distancia y tiempo estimado**: Datos visibles para la ruta seleccionada
- **Fallback automático**: Línea recta cuando falla el cálculo de ruta
- **Recalcular y cancelar**: Controles directos sobre la ruta activa

### 🏙️ Servicios de Movilidad Urbana

- **Zona Azul**: Información sobre zonas de estacionamiento regulado
- **Parkings**: Localización de parkings públicos y plazas disponibles
- **Bicicletas**: Servicios de bicicletas públicas y carriles bici
- **Patinetes**: Patinetes eléctricos compartidos disponibles
- **Notificaciones de Accesibilidad**: Información sobre paradas accesibles (PRM)

### 💳 Sistema de Transporte

- **Compra de tickets**: Billetes individuales y múltiples
- **Compra para otro usuario**: Disponible solo para cuentas registradas
- **Gestión de tarjetas**: Recarga de títulos de transporte con normativa oficial SURBUS (solo registrado)
- **Validación de viajes**: Sistema QR para validar tickets al subir al autobús
- **Control de saldo**: Tarjeta virtual recargable (solo registrado)

## Conexion API y Rendimiento

Resumen corto de la optimizacion global de conectividad y estado:

- Capa API central con cache, deduplicacion de requests en vuelo, timeout y retry.
- Inicializacion del mapa protegida para evitar reinicializaciones y llamadas redundantes.
- Carga de paradas optimizada en paralelo (`Future.wait`) para reducir tiempo de arranque.
- Popup de parada en Lineas sin recomputacion redundante en cada rebuild.
- Home y Lineas con guardas de recarga y refresh explicito solo al reintentar.

Documentacion tecnica completa:
- [documentacion/API_CONEXION_Y_OPTIMIZACION.md](documentacion/API_CONEXION_Y_OPTIMIZACION.md)

## Arquitectura MVVM

### Estructura del proyecto

```
lib/
├── core/
│   ├── theme/           # Tema y colores de la app
│   └── constants/       # Constantes globales
├── features/
│   ├── auth/           # Acceso, registro y sesión
│   │   ├── models/     # AppUser
│   │   ├── services/   # AuthApiService
│   │   ├── viewmodels/ # AuthViewModel
│   │   └── views/      # AuthScreen
│   ├── home/           # Pantalla principal
│   │   ├── models/     # MobilityServiceModel, ServiceStatus
│   │   ├── viewmodels/ # HomeViewModel con servicios
│   │   └── views/      # HomeView con grid de servicios
│   ├── map/            # Funcionalidad del mapa
│   │   ├── models/     # LocationModel, ZoneModel, FilterMode, FavoriteModel
│   │   ├── viewmodels/ # MapViewModel + FavoritesViewModel
│   │   ├── views/      # OptimizedMapView (presentacional y modular)
│   │   ├── widgets/    # SearchWidget, MapFilterBar, LineFilterSheet, FavoritesSheet, etc
│   │   └── tourism/    # Módulo turístico (modelos, datos, VM y widgets)
│   ├── tickets/        # Sistema de compra de tickets
│   │   ├── models/     # TicketModel
│   │   ├── viewmodels/ # TicketViewModel
│   │   └── views/      # BuyTicketView
│   ├── recharge/       # Gestión de tarjetas de transporte
│   │   ├── models/     # TransportCardModel, RechargeHistory
│   │   ├── viewmodels/ # RechargeViewModel
│   │   └── views/      # RechargeView
│   ├── settings/       # Ajustes y estado de cuenta
│   │   └── views/      # SettingsView
│   ├── notifications/  # Notificaciones de bus y bandeja personal
│   │   ├── models/     # NotificationSettings, UserNotification
│   │   ├── services/   # LocalNotificationService, BackendNotificationsApiService
│   │   ├── viewmodels/ # NotificationsViewModel
│   │   └── views/      # NotificationsView
│   └── validation/     # Validación de viajes
│       ├── models/     # ValidationModel
│       ├── services/   # ValidationService
│       ├── viewmodels/ # ValidationViewModel
│       └── views/      # ValidateTripView
└── shared/
    └── services/       # API y modelos compartidos
```

### Patrón MVVM Implementado

**Model**: Datos y lógica de negocio

- `LineModel`: Información de líneas de autobús
- `StopModel`: Datos de paradas con relaciones línea-parada
- `LocationModel`: Coordenadas y direcciones
- `ZoneModel`: Polígonos geográficos de Almería
- `TicketModel`: Datos de tickets y compras con usos restantes
- `TransportCardModel`: Tarjetas de transporte con caducidad e historial
- `ValidationModel`: Registro de validaciones de viaje
- `TouristPlace`: Lugar turístico con categoría y coordenadas

**View**: Interfaz de usuario

- `HomeView`: Lista de líneas con información y navegación a secciones
- `OptimizedMapView`: Mapa interactivo con filtros y navegación
- `SearchWidget`: Búsqueda de direcciones con Nominatim
- `MapFilterBar`: Barra de filtros modular del mapa
- `LineFilterSheet`: Selector de línea con buscador por nombre/destino/parada
- `FavoritesSheet`: Gestión de favoritos (selección y eliminación)
- `TourismMarkersLayer`: Marcadores turísticos desacoplados de la vista
- `AuthScreen`: Pantalla de iniciar sesión y crear cuenta
- `SettingsView`: Ajustes y gestión de sesión
- `BuyTicketView`: Interfaz de compra de tickets
- `NotificationsView`: Avisos de llegada y bandeja personal (registrado)
- `RechargeView`: Gestión y recarga de tarjetas de transporte
- `ValidateTripView`: Validación de viajes con código QR
- Widgets reutilizables y responsive

**ViewModel**: Gestión de estado

- `HomeViewModel`: Estado de líneas, servicios urbanos y accesibilidad
  - `busServices`: 4 servicios principales (Líneas, Tickets, Recargas, Mapa)
  - `urbanMobilityServices`: 4 servicios informativos (Zona Azul, Parkings, Bicicletas, Patinetes)
  - `accessibilityService`: Notificaciones de accesibilidad PRM
- `MapViewModel`: Estado del mapa, ubicación, rutas y filtros (MVVM compliant)
  - Métodos centralizados: `loadStops()`, `getCurrentLocation()`, `getRouteResult()`, `setFilter()`, `refreshFavoriteStops()`, `setTouristRoute()`
  - Propiedades: `filteredStops`, `userLocation`, `currentFilter`, `isLoadingStops`, `favoriteStopIds`, `selectedTouristPlace`
- `FavoritesViewModel`: Persistencia local de paradas/líneas favoritas con `SharedPreferences`
- `AuthViewModel`: Estado de sesión, login/registro, recuperación de usuario y control de permisos por perfil
- `NotificationsViewModel`: Configuración de notificaciones locales de bus, bandeja personal remota (registrado), marcado como leída y eliminación automática al agotar ticket
- `TourismViewModel`: Control de modo turístico y categoría seleccionada
- `TicketViewModel`: Lógica de compra, restricciones por perfil (no registrado sin saldo ni envío a terceros) y consumo/eliminación de tickets agotados
- `RechargeViewModel`: Gestión de tarjetas, caducidad e historial
- `ValidationViewModel`: Control de validaciones y usos restantes
- `ChangeNotifier` + `Provider` para reactividad global

### Cambios MVVM Recientes

- **Auth + Settings**:
  `AuthViewModel` centraliza sesión/token/usuario y `SettingsView` refleja estado de cuenta y cierre de sesión.
- **Notifications**:
  `NotificationsViewModel` combina notificación local de bus con bandeja remota (usuarios registrados), soporta marcar leída y eliminar notificación cuando el ticket se agota.
- **Tickets**:
  `BuyTicketView` y `TicketViewModel` aplican reglas por perfil: no registrado compra solo para sí y solo con Google Pay/Apple Pay/Visa; registrado añade saldo y compra para terceros.

## Servicios de Movilidad

### MobilityServiceModel

Modelo unificado para representar servicios con estado y metadata:

```dart
class MobilityServiceModel {
  final String id;
  final String title;          // "Zona Azul", "Parkings", etc
  final String? subtitle;      // Información secundaria
  final String description;    // Descripción completa
  final IconData icon;         // Icono del servicio
  final Color color;           // Color identificativo
  final ServiceStatus status;  // active, comingSoon, information
}

enum ServiceStatus {
  active,      // Total funcionalidad
  comingSoon,  // Próximamente
  information  // Solo información
}
```

### HomeView - Servicios organizados

```
┌─────────────────────────────┐
│  🚌 Servicios de Autobús    │
├─────────────────────────────┤
│ [Líneas][Tickets][Rec][Mapa]│ ← 4 cards actuales
└─────────────────────────────┘

┌─────────────────────────────┐
│ 🏙️ Otros Servicios          │
├─────────────────────────────┤
│ [Zona A.][Parkings]         │
│ [Bikis] [Patinetes]         │
│ [Accesibilidad]             │
└─────────────────────────────┘
```

### Compra de Tickets

- **Tickets individuales**: 1.05€ por viaje
- **Tickets múltiples**: 1.05€ × cantidad seleccionada
- **Métodos de pago (no registrado)**: Google Pay, Apple Pay y Visa
- **Métodos de pago (registrado)**: Saldo, Google Pay, Apple Pay y Visa
- **Validación de saldo**: Control de saldo insuficiente (solo cuando se usa saldo)
- **Compra para otro usuario**: Solo registrada, con notificación al destinatario
- **Redirección automática**: Tras compra propia exitosa, redirige a validación

### Validación de Viajes

**Funcionalidades:**
- **Contador de usos**: Muestra viajes restantes en tickets múltiples
- **Validación simulada**: Sistema de validación con resultado aleatorio
- **Control de usos**: Decremento automático al validar
- **Bloqueo inteligente**: Deshabilita validación cuando no hay viajes disponibles
- **Cierre automático**: Al agotar usos, la pantalla de validación se cierra automáticamente
- **Registro de validación**: Información de línea, bus y fecha/hora
- **Estados visuales**: Confirmación verde o rechazo rojo

**Flujo de validación:**

1. Usuario compra ticket (individual o múltiple)
2. Sistema redirige automáticamente a pantalla de validación
3. Muestra código QR y viajes restantes (si aplica)
4. Usuario presiona "Validar ahora"
5. Sistema procesa validación (2 segundos)
6. Muestra resultado con detalles del viaje
7. Decrementa contador de usos automáticamente

**Tickets recibidos por notificación:**

1. Usuario registrado recibe notificación de ticket
2. Abre la notificación y entra directamente a validar
3. Si se agotan los usos, la notificación se elimina automáticamente

### Gestión de Tarjetas de Transporte

**Tipos de tarjetas soportadas:**

- **Tarjeta Saldo Virtual**: Recarga libre de cualquier importe
- **Mensual Ordinaria**: 19.55€ - Renovación mensual
- **Bonobús Universidad**: 3.35€ - Caduca curso escolar (30/09)
- **Mensual Estudiante**: 16.55€ - Renovación mensual
- **Bonobús Ordinario**: 4.45€ - 10 viajes con transbordo
- **Bonobús Pensionista**: 1.75€ - 10 viajes con transbordo
- **Tarjeta Estudiante 10**: 7.15€ - Viajes ilimitados mensuales
- **Tarjeta +65**: Gratuita - Sin caducidad

**Funcionalidades:**

- **Acceso restringido**: Funcionalidad disponible para usuarios registrados
- **Restricciones de recarga**: Solo 1 día antes o después de caducar
- **Importes fijos**: Según normativa oficial SURBUS
- **Historial de recargas**: Registro completo de transacciones

### Arquitectura MVVM en MapView

**Refactorización completa**: Toda la lógica de negocio movida de OptimizedMapView al MapViewModel

**ViewModel (mapViewModel)** - Lógica centralizada:

```dart
class MapViewModel extends ChangeNotifier {
  // Estado centralizado
  List<StopModel> _stops = [];
  LatLng? _userLocation;
  MapFilter _currentFilter;
  
  // Métodos de negocio (no en view)
  Future<void> loadStops() async     // API + transformación
  Future<void> getCurrentLocation()  // Geolocator
  List<StopModel> get filteredStops  // Lógica de filtrado
  Future<List<LatLng>> getRoute()    // OSRM routing
}
```

**View (OptimizedMapView)** - 100% presentacional:

```dart
// Solo rendering UI
Consumer<MapViewModel>(
  builder: (context, vm, child) {
    return FlutterMap(
      children: [
        // Markers basados en vm.filteredStops
        // Polylines basados en vm.activeRoute
        // Dropdown usando vm.currentFilter
      ]
    );
  }
)
```

### Tecnologías utilizadas

- **flutter_map**: Mapas OpenStreetMap sin dependencias de Google
- **geolocator**: GPS y cálculo de distancias
- **latlong2**: Manejo de coordenadas geográficas
- **OSRM**: Routing real para navegación peatonal

### Características del mapa

- **Zoom inteligente**: Paradas visibles solo con zoom ≥ 12
- **Marcadores diferenciados**:
  - 🔴 Rojo: Parada de una línea
  - 🟣 Púrpura: Parada multimodal (varias líneas)
  - 🔵 Azul: Ubicación del usuario
- **Filtros en tiempo real**: Por línea específica
- **Filtros en tiempo real**: Cercanas, todas, favoritas y por línea
- **Navegación por zonas**: Tap o dropdown para ir a zonas de Almería
- **Modo navegación**: Vista enfocada con solo parada destino
- **Rutas reales**: Navegación siguiendo calles usando OSRM
- **Información contextual**: Distancia, tiempo caminando, líneas
- **Popup de líneas con buscador**: Búsqueda por nombre, destino y paradas asociadas
- **Favoritos sincronizados**: Si se eliminan favoritos, el filtro se actualiza automáticamente
- **Modo turístico**: Marcadores de POIs con categorías
- **Ruta a POI**: Cálculo automático desde la ubicación del usuario
- **Tiempos peatonales coherentes**: Validación de duración para evitar estimaciones irreales

### Sistema de navegación

- **Routing real**: Usa OSRM para rutas que siguen calles
- **Fallback seguro**: Línea recta si falla la API
- **Modo enfocado**: Solo muestra parada destino durante navegación
- **Controles intuitivos**: Botón rojo para salir del modo navegación

## Datos GTFS

### Fuente de datos

- **Proveedor**: ALSA (operador oficial)
- **Formato**: GTFS (General Transit Feed Specification)
- **Cobertura**: Líneas urbanas de Almería

### Procesamiento de datos

```python
# API Flask (backend/almeria_busmaps_api.py)
def get_almeria_lines():
    # 1. Filtrar líneas urbanas por route_ids específicos
    almeria_route_ids = {2330, 2331, 2333, ...}
  
    # 2. Normalizar stop_ids entre archivos GTFS
    def normalize_stop_id(stop_id):
        return str(int(''.join(filter(str.isdigit, str(stop_id)))))
  
    # 3. Merge correcto: stop_times + stops
    trip_stops = trip_stops.merge(stops, on='stop_id_norm')
  
    # 4. Asignar zonas geográficas
    return processed_lines
```

### Estructura de datos

- **routes.txt**: Definición de líneas
- **stops.txt**: Ubicación de paradas
- **trips.txt**: Viajes programados
- **stop_times.txt**: Horarios y secuencias

### Relaciones línea-parada

```dart
class StopModel {
  final String id;
  final String name;
  final double lat, lon;
  final String zone;
  final Set<String> lineIds; // 🔑 Clave: múltiples líneas por parada
}
```

## Navegación y Rutas

### OSRM Integration

```dart
Future<List<LatLng>> _getRoute(LatLng from, LatLng to) async {
  final url = Uri.parse(
    'https://router.project-osrm.org/route/v1/walking/'
    '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
    '?overview=full&geometries=geojson'
  );
  
  final response = await http.get(url);
  final data = json.decode(response.body);
  final coords = data['routes'][0]['geometry']['coordinates'] as List;
  
  return coords.map((c) => LatLng(c[1], c[0])).toList();
}
```

### Características de navegación

- **Rutas reales**: Siguen calles y caminos peatonales
- **Cálculo de tiempo**: Estimación basada en velocidad promedio (5 km/h)
- **Vista enfocada**: Solo muestra parada destino durante navegación
- **Controles intuitivos**: Botones flotantes para gestionar rutas

## 🚀 Instalación y uso

### Descripción general

AlmeriaRuta es una plataforma integral de movilidad municipal que integra:

- **Transporte público**: Consultas de líneas, horarios y navegación
- **Servicios informativos**: Zona azul, parkings, bicicletas, patinetes, accesibilidad
- **Sistema de tickets**: Compra y validación de billetes
- **Gestión de tarjetas**: Recarga y control de saldo

### Prerrequisitos

- Flutter SDK ≥ 3.8.1
- Python 3.9+ (para API)
- Android SDK 22+ / iOS 12+

### Backend (API)

```bash
cd backend/
pip install flask flask-cors pandas pymysql itsdangerous

# API de líneas/paradas (GTFS/OSRM)
python almeria_busmaps_api.py
# disponible en http://localhost:5000

# API de autenticación/notificaciones/tickets entre usuarios
python almeria_auth_api.py
# disponible en http://localhost:5001
```

### Frontend (Flutter)

```bash
cd V2/almeriarutav02/
flutter pub get
flutter run
```

### Endpoints API

**Movilidad (5000):**
- `GET /lines` - Todas las líneas urbanas
- `GET /lines/{id}/stops` - Paradas de una línea específica
- `GET /stops/{id}` - Detalles de una parada

**Auth y cuenta (5001):**
- `POST /auth/register` - Registro de usuario
- `POST /auth/login` - Inicio de sesión
- `POST /auth/guest` - Sesión temporal de no registrado
- `GET /auth/me` - Perfil actual

**Tickets entre usuarios y notificaciones (5001):**
- `POST /auth/tickets/purchase` - Compra para otro usuario (crea notificación con payload de ticket)
- `GET /auth/notifications` - Listado de notificaciones de cuenta
- `POST /auth/notifications/{id}/read` - Marcar notificación como leída (idempotente)
- `DELETE /auth/notifications/{id}` - Eliminar notificación (usado al agotar ticket recibido)

## Diseño

### Colores municipales

```dart
class AppTheme {
  static const primaryRed = Color(0xFFE53E3E);   // Rojo principal
  static const lightRed = Color(0xFFFC8181);     // Rojo claro
  static const darkRed = Color(0xFFC53030);      // Rojo oscuro
  static const backgroundRed = Color(0xFFFED7D7); // Fondo
}
```

### Componentes UI

- Cards con información de líneas
- Modales deslizables para paradas
- Filtros dropdown integrados
- Indicadores de carga y estado
- Botones flotantes para navegación

## 🔧 Configuración

### Permisos Android

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

### Dependencias principales

```yaml
dependencies:
  flutter_map: ^8.2.2
  geolocator: ^14.0.2
  provider: ^6.1.2
  http: ^1.2.2
  latlong2: ^0.9.1
  qr_flutter: ^4.1.0
```

## Rendimiento

### Optimizaciones implementadas

- **Carga lazy**: Paradas visibles solo con zoom alto
- **Deduplicación**: Paradas únicas con múltiples líneas
- **Filtrado eficiente**: Algoritmos O(n) para filtros
- **Routing asíncrono**: Navegación no bloquea la UI
- **Vista enfocada**: Reduce marcadores durante navegación

### Métricas

- Tiempo de carga inicial: ~2s
- Paradas procesadas: ~200 únicas
- Líneas urbanas: 16 activas
- Zoom óptimo: 12-18
- Routing: <1s para rutas locales

## Funcionalidades Avanzadas

### Sistema de Tickets

- **Compra integrada**: Tickets individuales y múltiples
- **Validación de pagos**: Simulación de métodos de pago modernos
- **Control de cantidad**: Selector inteligente solo para tickets múltiples
- **Cálculo automático**: Precios dinámicos según selección
- **Gestión de saldo**: Control de saldo disponible en tarjeta virtual

### Validación de Viajes

- **Códigos QR**: Generación automática para cada ticket
- **Control de usos múltiples**: Contador de viajes restantes
- **Validación en tiempo real**: Simulación de validación con resultado
- **Registro automático**: Historial de validaciones con fecha y hora
- **Bloqueo de reutilización**: Prevención de uso fraudulento

### Gestión de Tarjetas

- **Normativa oficial**: Cumple regulaciones SURBUS Almería
- **Control de caducidad**: Sistema automático de vencimientos
- **Tipos diferenciados**: Saldo libre vs. importes fijos
- **Historial completo**: Registro de todas las recargas
- **Avisos proactivos**: Notificaciones de próximos vencimientos

## Desarrollo (V2 Flutter)

La app Flutter activa vive en `V2/almeriarutav02/`.

### Backend local

```bash
cd backend
python almeria_busmaps_api.py
```

### App Flutter

```bash
cd V2/almeriarutav02
flutter pub get
flutter run
```

Notas:
- En emulador Android, la app usa `http://10.0.2.2:5000`.
- En un móvil físico, hay que cambiar `apiBaseUrl` por la IP del PC (misma red) en `lib/core/constants/app_constants.dart`.

### Icono (launcher)

El icono se genera desde `assets/app_icon/app_icon.png` usando `flutter_launcher_icons`.

```bash
cd V2/almeriarutav02
dart run flutter_launcher_icons
```

### Búsqueda de direcciones

- **Nominatim OSM**: Geocoding gratuito
- **Búsqueda local**: Limitada a Almería
- **Autocompletado**: Sugerencias en tiempo real

### Gestión de estado

- **Provider pattern**: Gestión reactiva del estado
- **Context correcto**: Solución a problemas de Provider + BottomSheet
- **Estado persistente**: Rutas, filtros y favoritos sobreviven a overlays

## Contribución

1. Fork del repositorio
2. Crear rama feature: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -m 'Añadir nueva funcionalidad'`
4. Push a la rama: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT - ver [LICENSE](LICENSE) para detalles.

## Agradecimientos

- **ALSA**: Por proporcionar datos GTFS oficiales
- **SURBUS**: Normativa oficial de tarifas y títulos de transporte
- **OpenStreetMap**: Mapas libres y colaborativos
- **OSRM**: Routing engine gratuito y potente
- **QR Flutter**: Generación de códigos QR
- **Flutter Community**: Paquetes y documentación

## 📋 Estado del Proyecto

### ✅ Implementado

- [X] Arquitectura MVVM completa (HomeViewModel, MapViewModel, etc)
- [X] Map view refactorizado con MVVM puro
- [X] Sistema de servicios de movilidad municipal
- [X] Interfaz UI/UX mejorada con cards de servicios
- [X] Filtros avanzados en mapa
- [X] Sistema de tickets y validación con QR
- [X] Gestión de tarjetas de transporte
- [X] Notificaciones locales (caducidad mensual y llegada a parada)
- [X] Geolocalización en tiempo real
- [X] Routing con OSRM
- [X] Provider global de estado
- [X] Modo turístico con categorías y selector compacto
- [X] Ruta automática a lugares turísticos (OSRM + fallback)
- [X] Distancia y tiempo para rutas turísticas con ajuste peatonal

### 🚧 En desarrollo

- [ ] Integración backend de zona azul
- [ ] APIs de parkings y ubicación
- [ ] Servicio de bicicletas compartidas
- [ ] Sistema de patinetes eléctricos
- [ ] Push notifications para accesibilidad

### 📝 Última actualización

- **Marzo 2026**: Módulo de Notificaciones (caducidad mensual y llegada), selector de favoritos, y actualización de icono/nombre de la app
