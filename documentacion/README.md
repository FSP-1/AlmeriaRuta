# Documentacion de AlmeriaRuta

Este indice organiza la documentacion tecnica del repositorio. La fuente principal del proyecto esta en el README raiz; este archivo sirve como mapa para encontrar rapido arquitectura, APIs, algoritmo turistico, pruebas y cambios historicos.

## Lectura recomendada

1. [README del repositorio](../README.md): vision general, arquitectura y ejecucion.
2. [Funcionalidades y MVVM](producto/5-Funcionalidades-de-la-aplicacion-y-mvvm.md): resumen funcional alineado con la arquitectura Flutter.
3. [Integracion API y dependencias](arquitectura-api/6-Integracion-API-y-Dependencias.md): conexion Flutter-backend y dependencias activas.
4. [Contrato del backend](arquitectura-api/API_CONTRATO_BACKEND.md): endpoints y payloads esperados.
5. [Estrategia y cobertura de tests](calidad/8-Estrategia-y-cobertura-de-tests.md): criterio de validacion y estado de la suite.

## Arquitectura y producto

- [producto/5-Funcionalidades-de-la-aplicacion-y-mvvm.md](producto/5-Funcionalidades-de-la-aplicacion-y-mvvm.md): documento principal recomendado para explicar funcionalidades y MVVM.
- [producto/5-Funcionalidades-de-la-aplicacion.md](producto/5-Funcionalidades-de-la-aplicacion.md): version funcional extendida.
- [producto/5-Funcionalidades-de-la-aplicacion.docx](producto/5-Funcionalidades-de-la-aplicacion.docx): version Word del documento funcional.
- [producto/CAMBIOS_PERFIL_USUARIO_Y_HOME.md](producto/CAMBIOS_PERFIL_USUARIO_Y_HOME.md): historial del perfil de usuario y Home.
- [producto/CAMBIOS_REFACTOR_TICKETS_Y_PERSISTENCIA.md](producto/CAMBIOS_REFACTOR_TICKETS_Y_PERSISTENCIA.md): historial de tickets y persistencia.

## Backend e integraciones

- [arquitectura-api/API_CONTRATO_BACKEND.md](arquitectura-api/API_CONTRATO_BACKEND.md): contrato principal de endpoints.
- [arquitectura-api/API_CONEXION_Y_OPTIMIZACION.md](arquitectura-api/API_CONEXION_Y_OPTIMIZACION.md): conexion app-backend, cache y optimizacion.
- [arquitectura-api/API_EXTRA_OSRM_GEOCODIFICACION_Y_DEPENDENCIAS.md](arquitectura-api/API_EXTRA_OSRM_GEOCODIFICACION_Y_DEPENDENCIAS.md): OSRM, Nominatim, mapa y servicios HTTP auxiliares.
- [arquitectura-api/6-Integracion-API-y-Dependencias.md](arquitectura-api/6-Integracion-API-y-Dependencias.md): resumen tecnico de dependencias y flujos.
- [operario/api.md](operario/api.md): API del modulo de operario.
- [operario/frontend.md](operario/frontend.md): frontend del modulo de operario.
- [operario/integracion.md](operario/integracion.md): integracion completa del modulo de operario.

## Mapa, turismo y rutas

- [mapa-turismo/README_ALGORITMO.md](mapa-turismo/README_ALGORITMO.md): punto de entrada para el algoritmo turistico.
- [mapa-turismo/ALGORITMO_RUTA_TURISTICA.md](mapa-turismo/ALGORITMO_RUTA_TURISTICA.md): explicacion detallada del planificador.
- [mapa-turismo/ALGORITMO_RESUMEN_RAPIDO.md](mapa-turismo/ALGORITMO_RESUMEN_RAPIDO.md): resumen corto del algoritmo.
- [mapa-turismo/CHECKLIST_IMPLEMENTACION.md](mapa-turismo/CHECKLIST_IMPLEMENTACION.md): estado de implementacion y pendientes del algoritmo.
- [mapa-turismo/CAMBIOS_TURISMO_RUTAS_Y_CACHE.md](mapa-turismo/CAMBIOS_TURISMO_RUTAS_Y_CACHE.md): cambios especificos del cliente Flutter.

## Testing y calidad

- [calidad/8-Estrategia-y-cobertura-de-tests.md](calidad/8-Estrategia-y-cobertura-de-tests.md): estrategia vigente de tests.
- [calidad/stress_gets_1000_users_20s.md](calidad/stress_gets_1000_users_20s.md): prueba de estres documentada.

Estado actual validado: `flutter test` pasa con 202 tests.

## Diagramas y recursos

- [diagramas/bus_api_arquitectura.puml](diagramas/bus_api_arquitectura.puml): diagrama PlantUML de la API de buses.
- [diagramas/user_api_arquitectura.puml](diagramas/user_api_arquitectura.puml): diagrama PlantUML de la API de usuarios.
- [diagramas/busapiarquitectura.svg](diagramas/busapiarquitectura.svg): diagrama renderizado de buses.
- [diagramas/AuthAPI_Arquitectura.svg](diagramas/AuthAPI_Arquitectura.svg): diagrama renderizado de autenticacion.
- [recursos/HU-AlmeríaRuta.docx](recursos/HU-AlmeríaRuta.docx): historias de usuario en formato Word.
- [recursos/README_SCREENSHOTS.md](recursos/README_SCREENSHOTS.md): guia de nombres para capturas de pantalla.

## Notas de mantenimiento

- Preferir documentos Markdown como fuente viva; los `.docx` se mantienen como entregables o versiones de apoyo.
- Antes de entregar una version, ejecutar `flutter test` desde `V2/almeriarutav02`.
- Los documentos de cambios (`CAMBIOS_*.md`) son historicos: si contradicen el README o este indice, priorizar la documentacion principal actualizada.
