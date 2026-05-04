# Resumen Rápido - Algoritmo de Ruta Turística

## TL;DR (Too Long; Didn't Read)

**¿Qué es?**: Dijkstra shortest-path con estado consciente de transbordos
**¿Objetivo?**: Encontrar ruta óptima de autobús usuario → lugar turístico con **MÍNIMOS transbordos**
**Truco Principal**: Route-first (elige variante JSON por línea) + forward-only (respeta secuencia bus) + penalización pesada por transbordo

---

## Cambios Respecto a Versión Anterior

| Aspecto              | Antes                      | Ahora                              |
| -------------------- | -------------------------- | ---------------------------------- |
| Selección de ruta   | Heurística caótica       | Route-first desde JSON             |
| Recorrido de paradas | Cualquier dirección       | Forward-only (respeta secuencia)   |
| Costo de transbordo  | Medio/variable             | 25,000 metros (pesado)             |
| Seeding              | Parada más cercana global | Primera parada por línea en radio |
| Optimización        | Minimizar paradas          | Minimizar transbordos              |
| Código              | Heurísticas acumuladas    | Dijkstra DP limpio                 |

---

## Algoritmo en Una Imagen

```
UBICACIÓN USUARIO
    ↓
[Seed] Busca 1ª parada por línea dentro de 200m
    ↓
[Dijkstra] Expande forward en secuencia JSON de cada línea
    ↓
[Opción Transbordo] Cambiar línea (costo + 25,000)
    ↓
[Rastrea Mejor] Ruta con menor (distancia + transbordos*penalización)
    ↓
[Reconstruye] Agrupa paradas por línea en segmentos
    ↓
PLAN DE RUTA TURÍSTICA
```

---

## Parámetros Clave

```dart
buildPlan(
  boardingRadiusMeters: 200,           // Camina hasta 200m a 1ª parada
  transferPenaltyMeters: 25_000,       // Cada cambio de línea cuesta 25km de penalización
  maxTransfers: 2,                     // Máximo 2 cambios de línea
  maxWalkToBoardMeters: 1200,          // Camina hasta 1.2km para subir
  maxBusHopMeters: 5000,               // Paradas no pueden estar >5km aparte
)
```

---

## Estado DP

```dart
// Cada nodo en búsqueda:
class _Node {
  stopId,        // Dónde estamos
  cost,          // Distancia caminada + bus + penalizaciones
  line,          // Línea de autobús actual (null = caminando)
  transfers,     // Número de cambios de línea hasta aquí
}
```

---

## Salida

```dart
// Plan de ruta multi-segmento:
TouristBusRoutePlan {
  segments: [
    Segment(line: L1, board: Stop2, alight: Stop5, stops: [2,3,4,5]),
    Segment(line: L3, board: Stop5, alight: Stop9, stops: [5,6,7,8,9]),
  ],
  totalDistanceMeters: 2500,
  totalDurationMinutes: 18,
}
```

---

## Flujo de Datos

```
JSON Routes (todas_las_lineas.json)
    ↓
lineRouteVariantsByLine: Map<String, List<List<String>>>
    ↓
buildPlan()
  → selectLineSequence() → elige mejor variante por línea
  → Dijkstra DP expansion
  → Reconstruye ruta
    ↓
TouristBusRoutePlan + marcadores visuales + instrucciones
```

---

## Cuándo Falla

- **`buildPlan()` retorna `null`** si:
  - No hay parada alcanzable dentro de `boardingRadiusMeters` por línea
  - Ruta muy fragmentada (transbordos > `maxTransfers`)
  - Destino inalcanzable por combinación de líneas

---

## Puntos de Integración

1. **Obtener líneas & paradas**: `BusApiService` o `MapViewModel`
2. **Obtener variantes JSON**: `MapViewModel._loadLineRouteVariants()` (deshabilitado, pendiente)
3. **Llamar planeador**: `TouristBusRoutePlanner.buildPlan()`
4. **Mostrar resultado**: `TouristBusRouteSheet` (renderiza segmentos, transbordos, instrucciones)
5. **Renderizado mapa**: `MapLayersBuilder` (polilíneas por segmento, marcadores de transbordo)

---

## Checklist de Testing

- [X] Ruta 1 línea (sin transbordo)
- [X] Ruta 2 líneas (1 transbordo)
- [X] Ruta larga con muchas paradas (>10)
- [X] Usuario lejos de paradas (>200m)
- [X] Destino inalcanzable (debe retornar null)
- [X] Transbordo preferido sobre 1 línea larga (sintonización de penalización)

---

## Archivos Relevantes

- **Algoritmo**: `lib/features/map/tourism/utils/tourist_bus_route_planner_core.dart`
- **Modelos**: `lib/features/map/tourism/utils/tourist_bus_route_planner_models.dart`
- **Backend**: `backend/almeria_busmaps_api.py`

---

**Última Actualización**: 2026-05-04
**Estado**:  Estable, route-first + forward-only implementados
