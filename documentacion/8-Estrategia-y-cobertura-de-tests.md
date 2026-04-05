# 8. Estrategia y cobertura de tests

## Objetivo

Consolidar una base de pruebas por funcionalidad que permita:

- detectar regresiones al refactorizar ViewModels y servicios,
- validar reglas de negocio criticas (tickets, notificaciones, mapa),
- mantener feedback rapido en cambios incrementales.

## Enfoque aplicado

Se ha seguido un flujo iterativo y seguro:

1. Añadir bloque pequeno de tests en una funcionalidad concreta.
2. Ejecutar test focalizado del archivo/modulo afectado.
3. Ejecutar suite completa (`flutter test`).
4. Corregir inmediatamente cualquier fallo de compilacion o asercion.

## Nota operativa importante

En este workspace se detecto que el runner generico interno puede devolver `passed=0 failed=0` sin ejecutar realmente la suite Flutter.

Por ello, la validacion oficial de resultados se establece con:

```bash
flutter test
```

## Cobertura funcional incorporada en esta fase

Se ampliaron y estabilizaron tests en:

- `features/lines` (ViewModel + modelos auxiliares).
- `features/notifications` (ViewModel y servicios de persistencia/observacion).
- `features/map` (ViewModel y capa turismo: modelos + data).
- `features/tickets` (servicio API de compra).
- `shared/services` (onboarding).
- `core` (constantes y tema).
- `features/home` y `features/recharge` (modelos).

## Refactor minimo para habilitar testeo de casos dificiles

Para poder testear servicios con dependencias externas sin introducir cambios funcionales, se aplicaron ajustes de inyeccion de dependencias:

### 1) ArrivalObserverService

Archivo:
- `lib/features/notifications/services/arrival_observer_service.dart`

Cambios:
- Constructor de testing con inyeccion de `BusApiService` y `LocalNotificationService`.
- Metodo `stopObserving()` para cancelar timer y limpiar estado interno en tests.
- Se mantiene el `factory` singleton para runtime productivo.

Valor:
- Permite tests deterministas de ramas de scheduling/disparo inmediato.

### 2) TicketPurchaseApiService

Archivo:
- `lib/features/tickets/services/ticket_purchase_api_service.dart`

Cambios:
- Constructor con inyeccion opcional de `http.Client`.

Valor:
- Permite testear payloads HTTP, manejo de codigos 2xx/no-2xx y propagacion de errores backend.

## Resultado de la fase

- Suite completa validada en verde: **109 tests pasando**.
- Reduccion de archivos `lib/` sin test espejo (`test/..._test.dart`):
  - Estado inicial de esta subfase: **58**
  - Estado tras iteraciones: **46**

## Recomendaciones para la siguiente fase

1. Continuar por quick wins en vistas/widgets (tests de render y comportamiento simple).
2. Priorizar servicios de red compartidos (`BusApiService`) con un refactor de inyeccion similar.
3. Mantener criterio de validacion doble (focal + suite completa) en cada bloque.
4. Evitar mezclar cambios funcionales con cambios de testeo en una misma PR cuando sea posible.
