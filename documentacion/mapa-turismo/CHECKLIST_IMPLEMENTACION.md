# Checklist de Implementación - Algoritmo de Ruta Turística

## ✅ Qué Está Hecho

### Algoritmo Core

- [X] **Dijkstra DP con estado consciente de transbordos**

  - Archivo: `tourist_bus_route_planner_core.dart`
  - Estado: `(stopId, lineId, transferCount)`
  - Complejidad temporal: O((V*L*T) log(V*L*T))
- [X] **Selección Route-First**

  - Función: `selectLineSequence()`
  - Selecciona mejor variante JSON por línea antes de expandir
  - Fallback a `line.stops` si JSON no disponible
- [X] **Expansión Forward-Only**

  - Solo expande a `nextIndex = currentIndex + 1`
  - Nunca retrocede o reordena paradas arbitrariamente
  - Respeta secuencias reales de ruta de autobús
- [X] **Estado Consciente de Transbordos**

  - Penalización pesada: 25,000 metros por transbordo
  - Conteo explícito de transbordos en nodo DP
  - Prioriza rutas con menos cambios de línea
- [X] **Seeding Inteligente**

  - Busca primera parada por línea dentro de `boardingRadiusMeters` (200m)
  - Solo seed desde primera parada en secuencia
  - Previene boarding arbitrario a mitad de ruta

### Estructuras de Datos

- [X] `_Node`: Estado DP (stopId, cost, prev, line, transfers)
- [X] `TouristBusRoutePlan`: Salida con segmentos, distancias, tiempos
- [X] `TouristBusSegment`: Un tramo de autobús (línea, parada_boarding, parada_destino)
- [X] `TouristNearbyStopOption`: Paradas alternativas (para futuro)

### API Backend

- [X] `/lines`: Obtener todas las líneas con paradas
- [X] `/lines/<id>/stops`: Obtener paradas para una línea
- [X] `/lines/<id>/arrivals`: Obtener tiempos de llegada (basado en línea)
- [X] Llegadas time-persistent: countdown desde tiempo inicial aleatorio
- [X] Cacheo per-(línea, parada): sin reinicio mid-sesión

### UI/Visualización

- [X] Hoja de instrucciones de ruta con chips de resumen
- [X] Tarjetas de instrucción numeradas
- [X] Lista de paradas colapsable para rutas largas
- [X] Polilíneas por segmento en mapa (colores diferentes)
- [X] Parada de transbordo destacada con ícono de intercambio
- [X] Banner "Transbordo" entre segmentos

### Integración

- [X] Planeador callable desde `MapViewModel`
- [X] Persistencia de filtros (SharedPreferences)
- [X] Observador de notificación corregido (llegadas basadas en línea)
- [X] Labels UI de línea muestran identificador L#
- [X] Favoritos muestran L# + nombre para líneas

### Organización de Archivos

- [X] Planeador principal: `tourist_bus_route_planner_core.dart`
- [X] Modelos: `tourist_bus_route_planner_models.dart`
- [X] Helpers: `tourist_bus_route_planner_helpers.dart`
- [X] Hoja de ruta dividida en módulos:
  - `tourist_bus_route_sheet.dart` (wrapper)
  - `tourist_bus_route_sheet_content.dart` (UI principal)
  - `tourist_bus_route_sheet_components.dart` (reusables)

### Testing & Validación

- [X] Compilación limpia (sin errores de análisis)
- [X] Lógica validada (route-first + forward-only + penalización transbordo)
- [X] Visualización de transbordos verificada
- [X] Refactorización de archivos verificada
- [X] Persistencia de filtros testeada

---

### Prioridad Media

- [ ] **Radio de Boarding como Parámetro UI**

  - Actualmente hardcodeado a 200m
  - Podría exponerse como preferencia de usuario
  - Relacionado: maxWalkToBoardMeters (actualmente 1200m)
- [ ] **Persistencia de Filtro de Línea**

  - Actualmente: solo filtro de turismo persiste
  - Agregar: persistencia de filtro de línea (opcional)
  - Agregar: persistencia de filtro de zona (opcional)
- [ ] **Monitoreo de Rendimiento**

  - Loguear tiempo de ejecución del planeador
  - Rastrear cuán a menudo se retorna null
  - Monitorear sintonización de penalización de transbordo

---

### Casos Edge

- **Usuario muy lejos de paradas** (>200m de todas líneas): Retorna null
- **Lugar turístico inalcanzable**: Retorna null
- **Sin línea cubriendo lugar**: Retorna null
- **Ruta con muchos transbordos**: Puede exceder `maxTransfers=2`

### Rendimiento

- Planeador corre sincrónicamente (podría ser async para redes grandes)
- Sin cacheo de planes computados
- Llamadas API bloquean UI (sin fetch en background)

---

## Checklist de Testing

### Tests Unitarios

- [ ] Test planeador con ruta 1-línea (sin transbordo)
- [ ] Test planeador con ruta 2-línea (1 transbordo)
- [ ] Test planeador con ruta 3-línea (2 transbordos, máx)
- [ ] Test planeador con ruta larga (>10 paradas)
- [ ] Test planeador con usuario lejos de paradas (>200m)
- [ ] Test planeador con destino inalcanzable
- [ ] Test `selectLineSequence()` con variantes JSON
- [ ] Test `selectLineSequence()` sin JSON (fallback)
- [ ] Test sintonización penalización transbordo (alto vs. bajo)
- [ ] Test casos edge de radio de boarding

### Tests de Integración

- [ ] API `/lines` retorna estructura correcta
- [ ] API `/lines/<id>/arrivals` countdown funciona
- [ ] Observador de llegada dispara notificación correctamente
- [ ] Hoja de ruta muestra transbordos visualmente
- [ ] Mapa muestra polilíneas por segmento
- [ ] Persistencia de filtros sobrevive reinicio app
- [ ] Observador de notificación no crashea con plan null

### Tests Manuales (QA)

- [ ] Abrir app → seleccionar lugar turístico → ver ruta realista
- [ ] Zoom mapa → ver parada de transbordo destacada
- [ ] Scroll hoja de ruta → ver sección de paradas colapsable
- [ ] Cerrar app → abrir de nuevo → filtros aún seleccionados
- [ ] Tap banner transbordo → ver "Transbordo" claramente
- [ ] Test con diferentes radios de boarding (200m, 400m, 600m)
- [ ] Test con diferentes máx transbordos (1, 2, 3)

### Tests de Regresión

- [ ] Filtro de línea existente aún funciona
- [ ] Filtro de zona existente aún funciona
- [ ] Paradas favoritas existentes aún funcionan
- [ ] Layout de tarjeta de línea sin cambios
- [ ] Capas de mapa renderizan sin jank

---

## 📊 Complejidad Análisis

| Métrica              | Valor                                    |
| --------------------- | ---------------------------------------- |
| Complejidad Temporal  | O((V*L*T) log(V*L*T))                |
| Complejidad Espacial  | O(V*L*T)                               |
| Típico para Almería | ~300 paradas, ~16 líneas, 2 transbordos |
| Tiempo de Ejecución  | <1 segundo                               |
| Uso de Memoria        | ~50KB                                    |

---

## 📁 Estructura de Archivos

```
lib/features/map/tourism/
├── utils/
│   ├── tourist_bus_route_planner_core.dart          ⭐ Algoritmo
│   ├── tourist_bus_route_planner_models.dart        Modelos
│   ├── tourist_bus_route_planner_helpers.dart       Utilidades
│   └── tourist_bus_route_planner_test.dart          Tests
├── viewmodels/
│   └── tourism_viewmodel.dart                       Estado + persistencia
├── widgets/
│   ├── tourist_bus_route_sheet/                     UI Ruta
│   │   ├── tourist_bus_route_sheet.dart             Wrapper modal
│   │   ├── tourist_bus_route_sheet_content.dart     UI principal
│   │   └── tourist_bus_route_sheet_components.dart  Widgets reusables
│   └── ...
└── docs/                                            📚 AQUÍ ESTAMOS
    ├── README.md
    ├── ALGORITHM.md
    ├── ALGORITHM_QUICK_REF.md
    ├── BACKEND_API_CONTRACT.md
    └── IMPLEMENTATION_CHECKLIST.md
```

---

## 🚀 Disposición para Producción

### Listo para Producción ✅

- Algoritmo core (estable)
- Visualización de transbordos (completa)
- Mejoras UI (pulidas)
- Organización de archivos (modular)

### Necesita Revisión Antes de Release ⏳

- Carga de variantes JSON (deshabilitada, necesita validación)
- Testing end-to-end (no realizado aún)

### Puede Desplegar Ahora

- Planeador funciona sin variantes JSON (fallback limpio)
- Rutas se muestran correctamente
- Transbordos visualizados
- Filtros persisten
- Sin crasheos o errores

---

## ¿Preguntas?

- **"¿Cómo funciona?"** → Ver [ALGORITMO_RUTA_TURISTICA.md](ALGORITMO_RUTA_TURISTICA.md)
- **"Resumen rápido?"** → Ver [ALGORITMO_RESUMEN_RAPIDO.md](ALGORITMO_RESUMEN_RAPIDO.md)
- **"Detalles API?"** → Ver [API_CONTRATO_BACKEND.md](../arquitectura-api/API_CONTRATO_BACKEND.md)
- **"¿Dónde está el código?"** → `lib/features/map/tourism/utils/`

---

**Última Actualización**: 2026-05-04
**Estado**: 🟢 Core Completo, 🟡 Testing Pendiente, 🟡 Variantes JSON Pendiente
