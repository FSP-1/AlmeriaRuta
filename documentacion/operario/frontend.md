# Documentación Frontend Operario

## Qué hace esta parte en la app
El frontend de operario está pensado para dar control operativo diario dentro de la misma app, sin depender de una consola externa. El objetivo no es solo crear avisos, sino también reaccionar rápido ante incidencias reales de servicio: obras, desvíos, cortes de calle o paradas fuera de servicio.

En la práctica, el panel de operario permite tres bloques de trabajo:
1. Publicar y gestionar avisos para que el usuario final vea información actualizada.
2. Deshabilitar y re-habilitar paradas cuando su estado operativo cambia.
3. Revisar solicitudes de tarjeta y aprobarlas o denegarlas segun la documentacion recibida.

## Cómo está organizado en el frontend
La vista principal está en [V2/almeriarutav02/lib/features/operario/views/operario_panel_view.dart](../../V2/almeriarutav02/lib/features/operario/views/operario_panel_view.dart) y se divide por pestañas para separar claramente avisos, paradas y solicitudes de tarjeta.

La lógica de negocio y estado está en [V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart](../../V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart). Ahí se controla qué campos están rellenos, qué validaciones se cumplen, cuándo hay carga en curso y cómo se refrescan los listados tras cada operación.

La comunicación HTTP se centraliza en [V2/almeriarutav02/lib/shared/services/notices_api_service.dart](../../V2/almeriarutav02/lib/shared/services/notices_api_service.dart), para que la vista y el viewmodel no tengan dependencias directas con el detalle de endpoints.

## MVVM de Operario
Este bloque resume el reparto real de responsabilidades dentro del modulo de operario. La idea es que la vista solo pinte y capture acciones, el viewmodel concentre estado y reglas, y los servicios y modelos se encarguen de la lectura y escritura de datos.

### View
- [V2/almeriarutav02/lib/features/operario/views/operario_panel_view.dart](../../V2/almeriarutav02/lib/features/operario/views/operario_panel_view.dart): contenedor principal del panel. Crea las pestañas y carga el viewmodel al entrar.
- [V2/almeriarutav02/lib/features/operario/views/widgets/operario_notice_tab.dart](../../V2/almeriarutav02/lib/features/operario/views/widgets/operario_notice_tab.dart): pantalla para crear avisos y revisar el listado ordenado por prioridad de tipo.
- [V2/almeriarutav02/lib/features/operario/views/widgets/operario_stops_tab.dart](../../V2/almeriarutav02/lib/features/operario/views/widgets/operario_stops_tab.dart): pestaña para buscar paradas, deshabilitarlas, habilitarlas y mostrar las que siguen bloqueadas.
- [V2/almeriarutav02/lib/features/operario/views/widgets/operario_card_requests_tab.dart](../../V2/almeriarutav02/lib/features/operario/views/widgets/operario_card_requests_tab.dart): vista para revisar solicitudes de tarjeta, filtrarlas y aprobarlas o denegarlas.
- [V2/almeriarutav02/lib/features/operario/views/widgets/operario_notice_card.dart](../../V2/almeriarutav02/lib/features/operario/views/widgets/operario_notice_card.dart): tarjeta reutilizable para pintar cada aviso con su accion de desactivacion.
- [V2/almeriarutav02/lib/features/operario/views/widgets/operario_view_utils.dart](../../V2/almeriarutav02/lib/features/operario/views/widgets/operario_view_utils.dart): utilidades de presentacion como iconos, colores y formato de fecha.

### ViewModel
- [V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart](../../V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart): guarda el estado del panel, aplica validaciones, prepara los datos para cada tipo de aviso, gestiona paradas deshabilitadas y ejecuta las operaciones de crear, deshabilitar, habilitar y desactivar avisos.

### Modelo y servicios
- [V2/almeriarutav02/lib/shared/services/notices_api_service.dart](../../V2/almeriarutav02/lib/shared/services/notices_api_service.dart): cliente HTTP del modulo. Encapsula las llamadas al backend para avisos y paradas, y define el modelo de parada deshabilitada que consume el panel.
- [V2/almeriarutav02/lib/shared/services/line_models.dart](../../V2/almeriarutav02/lib/shared/services/line_models.dart): modelos de dominio que usa operario para lineas, paradas y avisos.
- [V2/almeriarutav02/lib/shared/services/bus_api_service.dart](../../V2/almeriarutav02/lib/shared/services/bus_api_service.dart): obtiene lineas y paradas para que el operario pueda seleccionar la linea afectada o buscar una parada concreta.

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

## Revisión de solicitudes de tarjeta
La pestaña de solicitudes de tarjeta permite al operario revisar las peticiones enviadas desde la pantalla de recarga. Cada solicitud muestra el tipo de tarjeta, estado, nombre completo, DNI/NIE, email, telefono, direccion y motivo de decision si ya existe.

El flujo operativo es:
1. El operario abre el panel y entra en la pestaña de solicitudes.
2. Puede filtrar por todas, pendientes, aprobadas o denegadas.
3. Abre una solicitud para revisar datos personales y documentos marcados por el usuario.
4. Si todo es correcto, pulsa Aprobar.
5. Si falta documentacion o los datos no encajan, pulsa Denegar y escribe el motivo.
6. Tras aprobar o denegar, el listado se recarga automaticamente para reflejar el nuevo estado.

La recarga manual tambien esta disponible mediante el boton de refrescar de la barra de filtro. Este boton vuelve a consultar al backend manteniendo el filtro activo, por lo que el operario puede comprobar si han entrado nuevas solicitudes sin salir de la pantalla.

## Reglas del formulario de solicitud de tarjeta
Antes de que una solicitud llegue al operario, el frontend guia al usuario con reglas de escritura en los campos principales:
1. Nombre completo: debe incluir nombre y apellidos, solo letras, espacios, guiones o apostrofes.
2. DNI/NIE: admite formatos como `12345678Z` o `X1234567L`.
3. Email: debe tener formato de correo valido; se envia en minusculas.
4. Telefono: requiere 9 digitos sin espacios ni prefijo.
5. Direccion: debe ser suficientemente completa e incluir numero de calle o portal.

Estas reglas reducen solicitudes incompletas y facilitan que el operario pueda validar o rechazar con un motivo claro.

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
- [V2/almeriarutav02/lib/features/operario/views/widgets/operario_card_requests_tab.dart](../../V2/almeriarutav02/lib/features/operario/views/widgets/operario_card_requests_tab.dart)
- [V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart](../../V2/almeriarutav02/lib/features/operario/viewmodels/operario_viewmodel.dart)
- [V2/almeriarutav02/lib/shared/services/notices_api_service.dart](../../V2/almeriarutav02/lib/shared/services/notices_api_service.dart)
- [V2/almeriarutav02/lib/features/recharge/requests/views/card_request_stepper_view.dart](../../V2/almeriarutav02/lib/features/recharge/requests/views/card_request_stepper_view.dart)
