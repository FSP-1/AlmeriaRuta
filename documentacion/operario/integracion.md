# Integración Frontend y API de Operario

## Objetivo de la integración
La integración entre frontend y backend en el módulo de operario busca que cualquier acción operativa en la app tenga un reflejo inmediato, coherente y seguro en servidor. No se trata solo de “mandar peticiones”, sino de mantener sincronizado el estado de avisos y paradas con una experiencia de uso clara para quien opera la red.

## Piezas principales en el frontend
El archivo [V2/almeriarutav02/lib/shared/services/notices_api_service.dart](../../V2/almeriarutav02/lib/shared/services/notices_api_service.dart) es la pieza central de comunicación con backend para avisos y paradas.

Las solicitudes de tarjeta usan [V2/almeriarutav02/lib/features/recharge/requests/services/card_request_service.dart](../../V2/almeriarutav02/lib/features/recharge/requests/services/card_request_service.dart), compartido entre el flujo de usuario que solicita una tarjeta y la pestaña de operario que revisa esas solicitudes.

Su papel es importante por tres motivos:
1. Centraliza las rutas y evita que la vista conozca detalles HTTP.
2. Aplica reglas comunes de cabeceras y serialización.
3. Devuelven respuestas en modelos que el viewmodel o la pestaña operativa pueden usar directamente.

Esto reduce duplicación y evita que cada pantalla implemente su propia forma de llamar a la API.

## Flujo completo de llamada: de la UI al backend y vuelta
Cuando el operario pulsa una acción, la vista delega en el viewmodel. El viewmodel valida campos y decide si puede avanzar. Si todo es correcto, delega en notices_api_service. El servicio realiza la llamada HTTP, interpreta respuesta y devuelve resultado estructurado.

Después, el viewmodel actualiza estado local y la vista reacciona automáticamente mostrando éxito, error o datos refrescados. Este patrón evita lógica de red en la capa visual y mantiene el comportamiento predecible.

## Cómo se gestionan avisos
La creación de avisos pasa por validación previa en frontend y validación de negocio en backend. Si el tipo es LINEA o PARADA, el payload contiene más contexto y el backend aplica reglas específicas. Al completar, el frontend recarga avisos activos y mantiene el orden de prioridad visual.

La desactivación de avisos sigue una lógica similar: acción del usuario, llamada a API, confirmación y actualización de la lista sin necesidad de reiniciar pantalla.

## Cómo se gestionan paradas deshabilitadas
Al deshabilitar parada, el flujo no termina en el formulario: además de persistir el cambio, el frontend actualiza la lista de paradas deshabilitadas y fuerza coherencia visual en mapa. Cuando se habilita de nuevo, ocurre el ciclo inverso.

Esto garantiza que panel y mapa no queden desalineados, algo crítico en operación real.

## Cómo se gestionan solicitudes de tarjeta
El usuario inicia la solicitud desde recarga, elige tipo de tarjeta y completa datos personales. El formulario aplica reglas de escritura antes de enviar: nombre completo con apellidos, DNI/NIE con formato valido, email valido, telefono de 9 digitos y direccion con numero de calle o portal.

Al enviar, `CardRequestService.submit` manda el payload al backend con token de usuario. La solicitud queda en estado pendiente y aparece en el panel de operario.

El operario consulta el listado con `CardRequestService.listOperario`, opcionalmente filtrado por estado. Desde la tarjeta expandible revisa datos y decide:
1. Aprobar si los datos y documentos son correctos.
2. Denegar si falta informacion o hay incoherencias, indicando motivo.

Tras cada decision se ejecuta una recarga del listado para que la pantalla muestre el estado actualizado. El boton de refrescar permite repetir esa consulta manualmente manteniendo el filtro elegido.

## Autenticación en integración
En este módulo hay diferencia entre lectura y escritura. Lecturas como avisos pueden permitirse sin token según política de producto. En cambio, cualquier escritura requiere token con rol operario. notices_api_service contempla este comportamiento para incluir cabeceras de autorización cuando corresponde.

## Manejo de errores de extremo a extremo
La integración está diseñada para no esconder errores. Cuando backend devuelve fallo, el servicio lo propaga de forma legible y el viewmodel lo transforma en feedback de interfaz. Así el operario entiende qué falló y puede corregir sin repetir acciones a ciegas.

Además, en Flutter se protege la actualización de UI tras tareas asíncronas con comprobación de contexto montado para evitar errores de ciclo de vida.

## Resultado funcional
Con esta integración, el módulo de operario consigue:
1. Acciones rápidas con feedback inmediato.
2. Estado coherente entre panel, backend y mapa.
3. Separación limpia de responsabilidades entre vista, lógica y red.
4. Base mantenible para futuros cambios de endpoints o reglas.
5. Control de solicitudes de tarjeta con validacion previa para reducir errores operativos.
