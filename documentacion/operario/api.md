# Documentación API Operario

## Visión general
La API de operario está diseñada para que el frontend pueda consultar información operativa y ejecutar acciones de control sobre el servicio. A nivel funcional, cubre cuatro áreas: avisos, estado de paradas, solicitudes de tarjeta y control de permisos por rol.

Para mantener el código ordenado y escalable, el backend separa responsabilidades en capas: controller, service y repository.

## Qué se hace en cada capa

### Controller
El controller es la puerta de entrada HTTP. Recibe la petición, valida formato básico, extrae token si existe, decide si la operación requiere autenticación obligatoria y traduce la respuesta del servicio a un código HTTP.

En esta capa se hace, por ejemplo:
1. Validar que exista el cuerpo JSON cuando la ruta es de escritura.
2. Comprobar que el usuario autenticado tenga rol operario antes de mutar datos.
3. Devolver errores de negocio de forma consistente, con mensajes claros para el frontend.

La idea es que el controller no contenga lógica compleja de negocio ni consultas SQL directas.

### Service
El service implementa las reglas de negocio. Es donde se decide cómo se crea un aviso, cuándo se puede desactivar, qué campos son obligatorios según tipo, y cómo impactan las operaciones de paradas en el estado global.

En esta capa se hace, por ejemplo:
1. Reglas por tipo de aviso (GENERAL, TURISMO, LINEA, PARADA).
2. Validaciones funcionales, no solo sintácticas.
3. Orquestación de operaciones que implican más de un dato o más de una tabla.
4. Preparación de respuestas limpias para frontend, sin exponer estructura interna de base de datos.

Es la capa más importante para mantener coherencia cuando el producto evolucione.

### Repository
El repository encapsula acceso a base de datos. Su responsabilidad es leer y escribir datos de forma segura y predecible, devolviendo al service objetos simples o estructuras normalizadas.

En esta capa se hace, por ejemplo:
1. Consultar avisos activos ordenados por criterios definidos.
2. Insertar avisos y actualizar su estado cuando se desactivan.
3. Insertar paradas deshabilitadas y revertirlas cuando se habilitan.
4. Aplicar filtros por id, tipo o estado sin mezclar lógica de interfaz.

Esta separación evita que el resto del backend dependa del detalle SQL.

## Endpoints operativos esperados

### Avisos
1. Lectura de avisos activos para mostrar en app.
2. Creación de aviso con control de rol operario.
3. Desactivación de aviso para retirar mensajes caducados o incorrectos.

### Paradas
1. Lectura de paradas deshabilitadas para panel y mapa.
2. Deshabilitar parada con motivo.
3. Volver a habilitar parada cuando finaliza la incidencia.

### Solicitudes de tarjeta
1. Creacion de solicitud desde el flujo de recarga del usuario.
2. Lectura de solicitudes por operario, con filtro opcional por estado.
3. Decision de solicitud: aprobar o denegar.
4. Registro de motivo cuando la solicitud se deniega.

El payload esperado incluye tipo de tarjeta, nombre completo, DNI/NIE, email, telefono, direccion, notas opcionales, documentos marcados y fecha de creacion. Aunque el frontend ya valida formato, backend debe tratar esos campos como entrada externa y volver a comprobar los obligatorios antes de persistir o decidir.

## Autenticación y autorización
La lectura de avisos puede ser abierta para mejorar accesibilidad al usuario final, pero toda acción que modifica estado debe exigir token válido y rol adecuado. Crear una solicitud requiere usuario autenticado. Listar, aprobar o denegar solicitudes requiere rol operario. No basta con validar que existe token; debe validarse también su autorización funcional.

## Contratos que cuidan la integración
Para mantener estable la integración con Flutter, la API devuelve formatos consistentes en fechas, tipos y errores. La app espera mensajes de error legibles y claves estables para poder mostrar feedback útil al operario.

## Trazabilidad y operación diaria
En este módulo es especialmente útil mantener trazabilidad de acciones: quién publica avisos, quién deshabilita paradas, cuándo se revierten cambios, quién revisa solicitudes de tarjeta y por qué motivo se deniegan. Esa trazabilidad ayuda tanto en soporte como en auditoría interna.

## Referencias de implementación
- [backend/almeria_busmaps_api.py](../../backend/almeria_busmaps_api.py)
- [backend/almeria_auth_api.py](../../backend/almeria_auth_api.py)
- [backend/auth_mvc/controller.py](../../backend/auth_mvc/controller.py)
- [backend/auth_mvc/service.py](../../backend/auth_mvc/service.py)
- [backend/auth_mvc/repository.py](../../backend/auth_mvc/repository.py)
