# Stress test GETs — 1000 usuarios / 20s

## Resumen de resultados

```
[summary]
requests: total=10664 ok=3816 non_200=0 errors=6848
throughput: 468.6 req/s, 8.58 MiB/s
latency_ms(sample): p50=2044.6 p95=2740.3 p99=2984.6 (n=5000 sample_limit=5000)
```

## Qué significa cada métrica

- **total=10664**: número total de peticiones que intentó hacer el test durante 20 segundos.
- **ok=3816**: peticiones que devolvieron HTTP 200.
- **non_200=0**: respuestas HTTP recibidas con código distinto de 200 (404, 500, etc.). En este caso: *ninguna*.
- **errors=6848**: fallos de red/timeout/excepción donde *no se llegó a obtener una respuesta HTTP*.

  - En este script, `errors` suele significar: **timeout**, **conexión rechazada**, **socket/URLError**, o saturación local por demasiados threads.
- **throughput: 468.6 req/s**: promedio de peticiones por segundo (RPS) que el test consiguió generar (contando OK + errors).
- **8.58 MiB/s**: volumen de datos transferidos por segundo (solo cuenta lo que realmente se llegó a leer en respuestas).
- **latency_ms(sample)**: percentiles de latencia (en milisegundos) de una muestra de hasta 5000 peticiones.

  - **p50=2044.6 ms**: la mitad de las peticiones tardó ~2.0s o menos.
  - **p95=2740.3 ms**: el 95% tardó ~2.7s o menos.
  - **p99=2984.6 ms**: el 99% tardó ~3.0s o menos.

## Interpretación (lo importante)

1. **La API se mantiene estable a nivel de códigos HTTP**

   - `non_200=0` sugiere que *cuando la API responde*, lo hace con 200 (no se están viendo 500/404).
2. **El cuello de botella está en la capacidad de servir tantas conexiones simultáneas**

   - `errors=6848` es muy alto (~64% de las peticiones).
   - En una carga de 1000 “usuarios” (threads) esto suele pasar por:
     - **timeouts** (el servidor no responde antes del `--timeout`),
     - **saturación del servidor Flask dev** (single-process / limitado),
     - **limitaciones del SO/cliente** (demasiados sockets/threads),
     - o una mezcla de todo.
3. **Latencia alta (2–3s) bajo carga**

   - p50 ≈ 2s significa que, incluso en las peticiones exitosas, el tiempo de respuesta ya está degradado.
   - Esto es esperable cuando se llega a saturación: las peticiones se encolan y se retrasan.

## Conclusiones

- Con esta carga (1000 usuarios/20s) el sistema **no sostiene** el volumen: hay muchos timeouts/fallos de conexión.
- Bajo saturación, la experiencia de usuario sería: tiempos de espera muy altos o “no carga” intermitente.

## Impacto del caché en cliente (importante)

En la app Flutter se cachean datos estáticos (líneas/paradas) en cliente durante horas. Eso significa que, en uso real:

- **`/lines` y `/lines/<id>/stops` se consultan muy poco** (normalmente al abrir la app, cuando expira el TTL, o si fuerzas refresco).
- La carga continua suele venir de endpoints “dinámicos”, especialmente **`/lines/<id>/arrivals`**.

Por tanto, este test con una mezcla general de endpoints (incluyendo stops y detalles) es un **peor caso** y puede sobreestimar la presión real del sistema si en producción el cliente está usando caché correctamente.

## Nota sobre el script

Este stress test usa threads y `urllib` (std-lib). Con 1000 threads, parte de los `errors` puede venir del propio cliente/Windows (más que del servidor). Aun así, el resultado es válido como señal de saturación general.
