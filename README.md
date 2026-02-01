# AlmeriaRuta 

Aplicación móvil Flutter para consultar el transporte público de Almería con datos GTFS oficiales de ALSA.

## Características

- **Líneas urbanas reales**: 16 líneas de autobús urbano (L1-L31) con datos oficiales
- **Mapa interactivo**: Visualización de paradas con filtros por línea y zona
- **Geolocalización**: GPS integrado con cálculo de distancias
- **Datos en tiempo real**: API Flask procesando GTFS de ALSA
- **Filtros avanzados**: Por línea específica y zona geográfica
- **Interfaz nativa**: Diseño con colores municipales de Almería

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
│   └── map/            # Funcionalidad del mapa
│       ├── models/     # LocationModel
│       ├── viewmodels/ # MapViewModel
│       └── views/      # OptimizedMapView
└── shared/
    └── services/       # API y modelos compartidos
```

### Patrón MVVM Implementado

**Model**: Datos y lógica de negocio

- `LineModel`: Información de líneas de autobús
- `StopModel`: Datos de paradas con relaciones línea-parada
- `LocationModel`: Coordenadas y direcciones

**View**: Interfaz de usuario

- `HomeView`: Lista de líneas con información
- `OptimizedMapView`: Mapa interactivo con filtros
- Widgets reutilizables y responsive

**ViewModel**: Gestión de estado

- `HomeViewModel`: Estado de líneas y paradas
- `MapViewModel`: Estado del mapa y ubicación
- `ChangeNotifier` + `Provider` para reactividad

## Sistema de Mapas

### Tecnologías utilizadas

- **flutter_map**: Mapas OpenStreetMap sin dependencias de Google
- **geolocator**: GPS y cálculo de distancias
- **latlong2**: Manejo de coordenadas geográficas

### Características del mapa

- **Zoom inteligente**: Paradas visibles solo con zoom ≥ 14
- **Marcadores diferenciados**:
  - 🔴 Rojo: Parada de una línea
  - 🟣 Púrpura: Parada multimodal (varias líneas)
  - 🔵 Azul: Ubicación del usuario
- **Filtros en tiempo real**: Por línea y zona geográfica
- **Información contextual**: Distancia, líneas que pasan, coordenadas

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

## 🔧 Configuración

### Permisos Android

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
```

### Dependencias principales

```yaml
dependencies:
  flutter_map: ^8.2.2
  geolocator: ^14.0.2
  provider: ^6.1.2
  http: ^1.2.2
```

## Rendimiento

### Optimizaciones implementadas

- **Carga lazy**: Paradas visibles solo con zoom alto
- **Deduplicación**: Paradas únicas con múltiples líneas
- **Cache local**: Datos persistentes entre sesiones
- **Filtrado eficiente**: Algoritmos O(n) para filtros

### Métricas

- Tiempo de carga inicial: ~2s
- Paradas procesadas: ~200 únicas
- Líneas urbanas: 16 activas
- Zoom óptimo: 14-18

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
- **OpenStreetMap**: Mapas libres y colaborativos
- **Flutter Community**: Paquetes y documentación
