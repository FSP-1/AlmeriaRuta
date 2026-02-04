# AlmeriaRuta 

Aplicación móvil Flutter para consultar el transporte público de Almería con datos GTFS oficiales de ALSA.

## Características

- **Líneas urbanas reales**: 16 líneas de autobús urbano (L1-L31) con datos oficiales
- **Mapa interactivo**: Visualización de paradas con filtros por línea y zona
- **Geolocalización**: GPS integrado con cálculo de distancias
- **Navegación real**: Rutas caminando usando OSRM que siguen calles reales
- **Datos en tiempo real**: API Flask procesando GTFS de ALSA
- **Filtros avanzados**: Por línea específica y navegación por zonas
- **Interfaz nativa**: Diseño con colores municipales de Almería
- **Modo navegación**: Vista enfocada durante "Cómo llegar"
- **Sistema de tickets**: Compra de billetes individuales, múltiples y tarjetas virtuales
- **Gestión de tarjetas**: Recarga de títulos de transporte con normativa oficial SURBUS

## Arquitectura MVVM

### Estructura del proyecto

```
lib/
├── core/
│   ├── theme/           # Tema y colores de la app
│   └── constants/       # Constantes globales
├── features/
│   ├── home/           # Pantalla principal
│   │   ├── models/     # Modelos de datos
│   │   ├── viewmodels/ # Lógica de negocio
│   │   └── views/      # Interfaces de usuario
│   ├── map/            # Funcionalidad del mapa
│   │   ├── models/     # LocationModel, ZoneModel
│   │   ├── viewmodels/ # MapViewModel
│   │   ├── views/      # OptimizedMapView
│   │   └── widgets/    # SearchWidget
│   ├── tickets/        # Sistema de compra de tickets
│   │   ├── models/     # TicketModel
│   │   ├── viewmodels/ # TicketViewModel
│   │   └── views/      # BuyTicketView
│   └── recharge/       # Gestión de tarjetas de transporte
│       ├── models/     # TransportCardModel, RechargeHistory
│       ├── viewmodels/ # RechargeViewModel
│       └── views/      # RechargeView
└── shared/
    └── services/       # API y modelos compartidos
```

### Patrón MVVM Implementado

**Model**: Datos y lógica de negocio

- `LineModel`: Información de líneas de autobús
- `StopModel`: Datos de paradas con relaciones línea-parada
- `LocationModel`: Coordenadas y direcciones
- `ZoneModel`: Polígonos geográficos de Almería
- `TicketModel`: Datos de tickets y compras
- `TransportCardModel`: Tarjetas de transporte con caducidad e historial

**View**: Interfaz de usuario

- `HomeView`: Lista de líneas con información y navegación a secciones
- `OptimizedMapView`: Mapa interactivo con filtros y navegación
- `SearchWidget`: Búsqueda de direcciones con Nominatim
- `BuyTicketView`: Interfaz de compra de tickets
- `RechargeView`: Gestión y recarga de tarjetas de transporte
- Widgets reutilizables y responsive

**ViewModel**: Gestión de estado

- `HomeViewModel`: Estado de líneas y paradas
- `MapViewModel`: Estado del mapa, ubicación y rutas
- `TicketViewModel`: Lógica de compra y validación
- `RechargeViewModel`: Gestión de tarjetas, caducidad e historial
- `ChangeNotifier` + `Provider` para reactividad

## Sistema de Tickets y Tarjetas

### Compra de Tickets

- **Tickets individuales**: 1.05€ por viaje
- **Tickets múltiples**: 1.05€ × cantidad seleccionada
- **Tarjeta virtual**: 10.00€ con saldo recargable
- **Métodos de pago**: Google Pay, Apple Pay, Visa
- **Validación**: Control de errores y confirmación de compra

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
- **Tarjeta Discapacidad 65%**: Gratuita - Sin caducidad
- **Tarjeta Infantil**: Gratuita - Caduca en cumpleaños

**Funcionalidades:**
- **Restricciones de recarga**: Solo 1 día antes o después de caducar
- **Importes fijos**: Según normativa oficial SURBUS
- **Historial de recargas**: Registro completo de transacciones
- **Avisos de caducidad**: Banner superior para tarjetas próximas a vencer
- **Renovación automática**: Extensión de fechas al recargar tarjetas mensuales
- **Estados visuales**: Tarjetas caducadas en gris, botones deshabilitados

## Sistema de Mapas

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
- **Navegación por zonas**: Tap o dropdown para ir a zonas de Almería
- **Modo navegación**: Vista enfocada con solo parada destino
- **Rutas reales**: Navegación siguiendo calles usando OSRM
- **Información contextual**: Distancia, tiempo caminando, líneas

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

### Prerrequisitos

- Flutter SDK ≥ 3.8.1
- Python 3.9+ (para API)
- Android SDK 22+ / iOS 12+

### Backend (API)

```bash
cd backend/
pip install flask flask-cors pandas
python almeria_busmaps_api.py
# API disponible en http://localhost:5000
```

### Frontend (Flutter)

```bash
cd V2/almeriarutav02/
flutter pub get
flutter run
```

### Endpoints API

- `GET /lines` - Todas las líneas urbanas
- `GET /lines/{id}/stops` - Paradas de una línea específica
- `GET /stops/{id}` - Detalles de una parada

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

- **Compra integrada**: Tickets individuales, múltiples y tarjetas virtuales
- **Validación de pagos**: Simulación de métodos de pago modernos
- **Control de cantidad**: Selector inteligente solo para tickets múltiples
- **Cálculo automático**: Precios dinámicos según selección

### Gestión de Tarjetas

- **Normativa oficial**: Cumple regulaciones SURBUS Almería
- **Control de caducidad**: Sistema automático de vencimientos
- **Tipos diferenciados**: Saldo libre vs. importes fijos
- **Historial completo**: Registro de todas las recargas
- **Avisos proactivos**: Notificaciones de próximos vencimientos

### Búsqueda de direcciones

- **Nominatim OSM**: Geocoding gratuito
- **Búsqueda local**: Limitada a Almería
- **Autocompletado**: Sugerencias en tiempo real

### Gestión de estado

- **Provider pattern**: Gestión reactiva del estado
- **Context correcto**: Solución a problemas de Provider + BottomSheet
- **Estado persistente**: Rutas y selecciones sobreviven a overlays

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
- **Flutter Community**: Paquetes y documentación