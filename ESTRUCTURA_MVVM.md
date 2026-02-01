# AlmeriaRuta - Estructura MVVM

## Estructura del Proyecto

```
lib/
├── core/                          # Configuración y utilidades centrales
│   ├── constants/                 # Constantes de la aplicación
│   │   └── app_constants.dart
│   ├── routes/                    # Configuración de rutas
│   │   └── app_routes.dart
│   └── theme/                     # Temas de la aplicación
│       └── app_theme.dart
├── features/                      # Funcionalidades de la aplicación
│   ├── home/                      # Página principal
│   │   ├── models/
│   │   │   └── menu_item_model.dart
│   │   ├── viewmodels/
│   │   │   └── home_viewmodel.dart
│   │   └── views/
│   │       └── home_view.dart
│   └── movilidad/                 # Funcionalidades de movilidad
│       └── buses/                 # Funcionalidad de buses
│           ├── models/
│           │   └── bus_model.dart
│           ├── viewmodels/
│           │   └── buses_viewmodel.dart
│           └── views/
│               └── buses_view.dart
├── shared/                        # Componentes compartidos
│   ├── widgets/                   # Widgets reutilizables
│   │   └── common_widgets.dart
│   └── services/                  # Servicios compartidos (futuro)
└── main.dart                      # Punto de entrada de la aplicación
```

## Patrón MVVM Implementado

### Model
- Contiene la lógica de datos y modelos de negocio
- Ejemplo: `BusModel` para representar información de autobuses

### View
- Interfaz de usuario (UI)
- Se comunica con el ViewModel a través de Provider
- Ejemplo: `HomeView`, `BusesView`

### ViewModel
- Lógica de presentación y estado
- Extiende `ChangeNotifier` para notificar cambios a la vista
- Ejemplo: `HomeViewModel`, `BusesViewModel`

## Dependencias Utilizadas

- **provider**: Gestión de estado y patrón MVVM
- **go_router**: Navegación declarativa
- **mockito**: Generación de mocks para testing
- **faker**: Generación de datos falsos para desarrollo

## Cómo Agregar Nuevas Funcionalidades

1. Crear carpeta en `features/` con el nombre de la funcionalidad
2. Crear subcarpetas: `models/`, `viewmodels/`, `views/`
3. Implementar los archivos siguiendo el patrón MVVM
4. Agregar rutas en `app_routes.dart`
5. Agregar constantes en `app_constants.dart`
6. Actualizar el menú principal en `home_viewmodel.dart`

## Datos Mock

Actualmente la aplicación utiliza datos mock para desarrollo:
- Los modelos incluyen factory constructors para generar datos falsos
- Los ViewModels simulan llamadas asíncronas con delays
- Esto permite desarrollar la UI sin depender de APIs reales

## Próximos Pasos

1. Implementar servicios reales para reemplazar los mocks
2. Agregar más funcionalidades de movilidad
3. Implementar tests unitarios y de integración
4. Agregar manejo de errores más robusto
5. Implementar persistencia local de datos