# Documentación Frontend Operario

## Qué hace esta parte en la app
El frontend de operario está pensado para dar control operativo diario dentro de la misma app, sin depender de una consola externa. El objetivo no es solo crear avisos, sino también reaccionar rápido ante incidencias reales de servicio: obras, desvíos, cortes de calle o paradas fuera de servicio.

En la práctica, el panel de operario permite dos bloques de trabajo:
1. Publicar y gestionar avisos para que el usuario final vea información actualizada.
2. Deshabilitar y re-habilitar paradas cuando su estado operativo cambia.

## Cómo está organizado en el frontend
La vista principal está en [V2/almeriarutav02/lib/features/operario/views/operario_panel_view.dart](../../V2/almeriarutav02/lib/features/operario/views/operario_panel_view.dart) y se divide por pestañas para separar claramente avisos y paradas.

La lógica de negocio y estado está en [V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart](../../V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart). Ahí se controla qué campos están rellenos, qué validaciones se cumplen, cuándo hay carga en curso y cómo se refrescan los listados tras cada operación.

La comunicación HTTP se centraliza en [V2/almeriarutav02/lib/shared/services/notices_api_service.dart](../../V2/almeriarutav02/lib/shared/services/notices_api_service.dart), para que la vista y el viewmodel no tengan dependencias directas con el detalle de endpoints.

## Qué flujo sigue un operario dentro de la app
Cuando entra un usuario con rol operario, abre el panel y puede crear avisos de cuatro tipos: GENERAL, TURISMO, LINEA y PARADA. Esta clasificación se usa para que la información se muestre con prioridad y contexto: primero mensajes globales, luego turismo, y por último avisos de afectación puntual por línea o parada.

La app no muestra solo un formulario plano. Según el tipo de aviso, cambia el contenido:
1. Si es LINEA, se habilita la selección de línea y la selección de paradas afectadas mediante toggles.
2. Si es PARADA, aparece búsqueda por nombre, id o coordenadas para localizar rápidamente la parada concreta.
3. Si es GENERAL o TURISMO, se prioriza texto claro y, opcionalmente, identificador relacionado.

Esto evita errores de operación porque guía al operario por contexto, no por campos genéricos.

## Gestión de paradas en tiempo real
En la pestaña de paradas, el operario registra una deshabilitación con id, nombre y razón. Después, la parada queda listada como deshabilitada y se puede revertir con un botón de habilitar.

Este diseño cubre el ciclo completo de incidencia:
1. Marcar parada fuera de servicio.
2. Informar razón operativa.
3. Visualizar histórico activo de paradas deshabilitadas.
4. Restaurar parada cuando vuelve a estar disponible.

## Feedback y experiencia de uso
El frontend muestra mensajes de estado en dos niveles:
1. Mensaje visible en la propia pantalla (éxito o error).
2. SnackBar tras operaciones asíncronas para confirmar resultado inmediato.

También bloquea acciones durante peticiones en curso y enseña indicadores de carga en botones para evitar dobles envíos.

## Validaciones y robustez
Se validan campos obligatorios y tamaños de texto antes de llamar al backend. Además, tras cualquier operación asíncrona se comprueba `context.mounted` antes de tocar UI, lo que evita errores de ciclo de vida en Flutter.

## Relación con el mapa
Las paradas deshabilitadas no se quedan solo en el panel: también se reflejan visualmente en el mapa con estilo atenuado. Con esto, la información operativa y la visualización geográfica quedan sincronizadas y el estado de la red se entiende mejor por parte de los usuarios.

## Archivos clave
- [V2/almeriarutav02/lib/features/operario/views/operario_panel_view.dart](../../V2/almeriarutav02/lib/features/operario/views/operario_panel_view.dart)
- [V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart](../../V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart)
- [V2/almeriarutav02/lib/shared/services/notices_api_service.dart](../../V2/almeriarutav02/lib/shared/services/notices_api_service.dart)
