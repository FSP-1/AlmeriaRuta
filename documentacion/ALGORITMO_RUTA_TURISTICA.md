# Algoritmo Planeador de Rutas Turísticas en Autobús

## Descripción General

El **Planeador de Rutas Turísticas en Autobús** es un algoritmo basado en **Dijkstra (shortest-path)** que optimiza rutas multi-segmento desde la ubicación del usuario hasta un destino turístico, minimizando **transbordos** mediante una penalización pesada y respetando las secuencias reales de rutas de autobús desde JSON.

**Tipo de Algoritmo**: Dynamic Programming (Dijkstra variant) con estado consciente de transbordos

---

## ¿Qué Cambió?

### Enfoque Anterior (Deprecado)

- Selección de rutas heurística mezclando líneas innecesariamente
- Énfasis en minimizar *paradas* en lugar de *cambios de línea*
- Acumulación de penalizaciones y reglas que generaban fragilidad
- Sin ordenamiento estructurado de rutas JSON

### Enfoque Actual (Route-First)

1. **Selección Route-First**: Para cada línea, selecciona la mejor variante de ruta JSON ANTES de computar caminos

   - Las variantes se pre-computan de `todas_las_lineas.json` (secuencias reales de paradas)
   - Criterio de selección: variante que incluye la parada de destino, prefiriendo índices anteriores
   - Fallback: si no hay variantes JSON, usa `line.stops` directamente
2. **Expansión Forward-Only**: Viaja solo hacia adelante en la secuencia de ruta seleccionada

   - Paso de expansión: `nextIndex = currentIndex + 1` solamente
   - Sin pasos hacia atrás, sin reordenamiento arbitrario de paradas
   - Respeta el comportamiento real de las líneas de autobús (paradas secuenciales)
3. **Estado Consciente de Transbordos**: Rastrea transbordos explícitamente en el estado DP

   - Penalización pesada de transbordo: 25,000 metros (desalienta cambios de línea)
   - Estado del nodo incluye: `stopId`, `line`, `transfers` count
   - Prioriza rutas con menos cambios de línea
4. **Seeding Inteligente**: Solo sube a bordo en la primera parada por línea dentro del radio de caminata del usuario

   - `boardingRadiusMeters = 200m` por defecto
   - Para cada línea, busca la *primera* parada en la secuencia JSON dentro de este radio
   - Previene boarding arbitrario en medio de la ruta
   - El usuario no sube a "la parada más cercana globalmente"

---

## ¿Qué Hace?

### Ejecución Paso a Paso

#### 1. **Preparación de Datos**

- Carga todas las paradas, líneas y destinos desde `StopModel` y `LineModel`
- Construye índice `stopById` para búsqueda O(1)
- Si está disponible, carga mapa `lineRouteVariantsByLine` desde JSON
  - Estructura: `Map<String, List<List<String>>>` donde key=lineId, value=lista de secuencias de ruta

#### 2. **Selección de Variante de Ruta** (`selectLineSequence()`)

Para cada línea:

- Si existen variantes JSON para esta línea:
  - Materializa cada variante (convierte IDs de parada a objetos `StopModel`)
  - Puntúa cada variante materializada: `destinationIndex` (menor = mejor)
  - Selecciona variante con puntuación más baja
- Si no hay variantes: usa fallback `line.stops` (todas las paradas de la línea)
- Resultado: `lineSequenceById[lineId]` = lista ordenada de paradas para esa línea

#### 3. **Seeding** (Inicializa frontera Dijkstra)

Para cada línea:

- Obtiene la secuencia de ruta pre-seleccionada para esta línea
- Escanea hacia adelante a través de la secuencia
- Busca la *primera* parada dentro de `boardingRadiusMeters` de ubicación del usuario
- Empuja a priority queue: `_Node(stopId=firstBoardingStop, cost=walkDistanceToStop, line=null, transfers=0)`
- Si no hay parada encontrada en radio, salta esta línea

#### 4. **Expansión Dijkstra** (Loop DP principal)

Mientras priority queue no esté vacía:

- Extrae nodo de menor costo de la cola
- Calcula puntuación: `current.cost + distanceToDestination(currentStop)`
- Si es mejor que `bestScore`, actualiza `bestNode`
- Si `current.transfers >= maxTransfers`, salta expansión
- Para cada línea:
  - Encuentra índice de parada actual en secuencia de esa línea
  - Si se encuentra:
    - **Opción A (Transbordo)**: Si ya está en línea diferente, empuja nodo de transbordo
      - Costo: `current.cost + 25000` (penalización pesada)
      - Línea: la nueva línea
      - Transbordos: `current.transfers + 1`
    - **Opción B (Continuar)**: Si está en misma línea o iniciando, empuja siguiente parada adelante
      - Siguiente índice: `currentIndex + 1` SOLO (dirección hacia adelante)
      - Costo: `current.cost + busHopDistance + penalizaciones`
      - Transbordos: sin cambios (misma línea)

#### 5. **Reconstrucción de Ruta**

Desde `bestNode`, camina hacia atrás vía punteros `prev` para reconstruir ruta

- Recopila todos los nodos en orden inverso
- Materializa como `TouristBusRoutePlan` con segmentos

#### 6. **Segmentación** (Agrupa por línea)

- Camina hacia adelante a través de nodos de ruta
- Agrupa nodos consecutivos con misma línea → un `TouristBusSegment`
- Cada segmento: parada de boarding, parada de destino, paradas intermedias

---

## ¿Qué Tipo Es?

### Tipo de Algoritmo

- **Primario**: Algoritmo Dijkstra shortest-path (DP codicioso)
- **Variante**: Variante multi-estado donde cada estado es `(stopId, lineId, transferCount)`
- **Optimización**: Minimización de conteo de transbordos vía rastreo explícito de estado

### Complejidad Temporal

- **Peor caso**: `O((V * L * T) log(V * L * T))` donde:
  - `V` = número de paradas (paradas de todas las líneas, con duplicados por línea)
  - `L` = número de líneas
  - `T` = máximo de transbordos (típicamente 2–3)
  - Factor log de operaciones de priority queue
- **Típico**: Mucho más rápido debido a:
  - Seeding basado en radio (pocos puntos de inicio)
  - Expansión forward-only (ramificación limitada)
  - Terminación temprana cuando destino alcanzado

### Complejidad Espacial

- `O(V * L * T)` para rastreo de estado DP (`bestCostByState` map)
- `O(number_of_stops)` para índice `stopById`

---

## Parámetros Clave

| Parámetro                | Defecto | Propósito                                                              |
| ------------------------- | ------- | ----------------------------------------------------------------------- |
| `boardingRadiusMeters`  | 200     | Máxima distancia de caminata desde usuario a primera parada por línea |
| `transferPenaltyMeters` | 25,000  | Costo de penalización por cambio de línea (desalienta transbordos)    |
| `maxTransfers`          | 2       | Máximo número de cambios de línea permitidos                         |
| `maxWalkToBoardMeters`  | 1200    | Máxima caminata desde usuario a parada de boarding                     |
| `maxBusHopMeters`       | 5000    | Máxima distancia entre paradas consecutivas en misma línea            |

---

## Estructuras de Datos

### `_Node` (Estado DP Interno)

```dart
class _Node {
  final String stopId;           // Parada actual
  final double cost;              // Costo acumulado (distancia + penalizaciones)
  final _Node? prev;              // Nodo anterior en ruta (para reconstrucción)
  final LineModel? line;          // Línea siendo viajada (null = caminando)
  final int transfers;            // Número de cambios de línea hasta aquí
}
```

### `TouristBusRoutePlan` (Salida)

```dart
class TouristBusRoutePlan {
  final List<TouristBusSegment> segments;  // Lista de (línea, parada_boarding, parada_destino, rutas)
  final bool hasTransfer;                   // true si segments.length > 1
  final String linesLabel;                  // "L1 -> L2" para display
  // ... + estimaciones de caminata/autobús/tiempo
}
```

### `TouristBusSegment` (Un Tramo de Autobús)

```dart
class TouristBusSegment {
  final LineModel line;                 // La línea de autobús
  final StopModel boardingStop;         // Donde subirse
  final StopModel destinationStop;      // Donde bajarse
  final List<StopModel> routeStops;     // Todas las paradas en este tramo (incluyendo subida/bajada)
}
```

---

## Ejemplo Práctico

### Escenario

- Usuario en ubicación A, quiere llegar a lugar turístico P
- P está más cerca de parada D2
- Líneas disponibles: L1 (secuencia: S1→S2→D2→S4), L2 (secuencia: S3→S4→S5)
- Usuario está a 150m de S2, 300m de S3

### Ejecución

1. **Selección de Ruta**:

   - L1: S1→S2→D2→S4 (incluye D2, bueno)
   - L2: S3→S4→S5 (no incluye D2)
2. **Seeding**:

   - L1: S2 está a 150m (< 200m) → empuja `_Node(S2, cost=150, line=null, transfers=0)`
   - L2: S3 está a 300m (> 200m) → salta
3. **Expansión**:

   - Extrae S2 (cost=150)
   - Intenta L1: siguienteParada=D2 (150+heurística < mejor actual) → empuja `_Node(D2, ...)`
   - Intenta L2: transbordo necesario (cost += 25000) → probablemente peor
   - Extrae D2 (cost≈150+X)
   - Calcula puntuación: cost + dist(D2 → P) = ganador → actualiza `bestNode=D2`
4. **Salida**:

   - Segmento: L1, sube S2, baja D2, paradas=[S2, D2]
   - Plan: 150m caminata + viaje en autobús + caminata restante a P

---

## Integración con API Backend

### Variantes de Ruta (`todas_las_lineas.json`)

```json
{
  "lineas": [
    {
      "linea": "L1",
      "rutas": [
        {
          "ruta": "Rambla - Alcazaba",
          "paradas": [
            { "id": "478", "nombre": "Rambla" },
            { "id": "420", "nombre": "García Lorca" },
            { "id": "409", "nombre": "Alcazaba" }
          ]
        }
      ]
    }
  ]
}
```

### Puntos de Integración

1. **Obtener líneas & paradas**: `BusApiService` o `MapViewModel`
2. **Obtener variantes JSON**: `MapViewModel._loadLineRouteVariants()` (actualmente deshabilitado, pendiente)
3. **Llamar planeador**: `TouristBusRoutePlanner.buildPlan()`
4. **Mostrar resultado**: `TouristBusRouteSheet` (renderiza segmentos, transbordos, instrucciones)
5. **Renderizado en mapa**: `MapLayersBuilder` (polilíneas por segmento, marcadores de transbordo)

---

## Estado Actual

### ✅ Implementado & Estable

- Dijkstra DP con estado consciente de transbordos
- Selección de variante route-first
- Expansión forward-only en secuencias JSON
- Seeding inteligente basado en radio
- Penalización de transbordo pesada (25,000m)
- Construcción de plan multi-segmento
- Visualización de transbordos en UI (polilíneas por segmento, marcadores)
- Persistencia de filtros (SharedPreferences)


## Referencias de Archivos

- **Algoritmo Core**: `lib/features/map/tourism/utils/tourist_bus_route_planner_core.dart`
- **Modelos**: `lib/features/map/tourism/utils/tourist_bus_route_planner_models.dart`
- **API Backend**: `backend/almeria_busmaps_api.py`
- **Integración ViewModel**: `lib/features/map/viewmodels/map_viewmodel.dart`
- **UI Rutas**: `lib/features/map/tourism/widgets/tourist_bus_route_sheet/`

---

**Última Actualización**: 2026-05-04
**Versión**: 2.0 (Route-First + Forward-Only + Transfer Awareness)
