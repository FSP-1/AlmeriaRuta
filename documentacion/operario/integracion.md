# Integración Frontend y API de Operario

## Objetivo de la integración
La integración entre frontend y backend en el módulo de operario busca que cualquier acción operativa en la app tenga un reflejo inmediato, coherente y seguro en servidor. No se trata solo de “mandar peticiones”, sino de mantener sincronizado el estado de avisos y paradas con una experiencia de uso clara para quien opera la red.

## Pieza principal en el frontend: notices_api_service
El archivo [V2/almeriarutav02/lib/shared/services/notices_api_service.dart](../../V2/almeriarutav02/lib/shared/services/notices_api_service.dart) es la pieza central de comunicación con backend para este módulo.

Su papel es importante por tres motivos:
1. Centraliza las rutas y evita que la vista conozca detalles HTTP.
2. Aplica reglas comunes de cabeceras y serialización.
3. Devuelve respuestas en modelos que el viewmodel puede usar directamente.

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
