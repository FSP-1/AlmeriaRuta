# 6.2.3 Servidor y Despliegue de las APIs

Este documento recoge, de forma práctica, el contenido del apartado 6.2.3 del TFG sobre el despliegue de las APIs del proyecto AlmeriaRuta.

El objetivo es dejar por escrito:

- cómo se ejecutan las APIs en desarrollo local,
- cómo se configura la app Flutter para consumirlas,
- cómo se despliegan en producción,
- qué papel juegan Nginx, Let’s Encrypt y `systemd`,
- y qué pasos siguen para mantener las APIs activas 24/7.

## 1. Ejecución simultánea en desarrollo

Durante el desarrollo, las dos APIs se levantan en terminales distintas:

- API BusMaps: `http://localhost:5000`
- API Auth: `http://localhost:5001`

### 1.1 Arranque manual

```bash
python3 almeria_busmaps_api.py
python3 almeria_auth_api.py
```

La aplicación Flutter consume cada servicio por separado usando las URLs definidas en `app_constants.dart`.

### 1.2 Configuración local de Flutter

En modo local, la app apunta al `localhost` del equipo anfitrión usando `10.0.2.2` desde el emulador Android:

```dart
class AppConstants {
  static const String appName = 'AlmeriaRuta V2';
  static const String apiBaseUrl = 'http://10.0.2.2:5000';
  static const String authApiBaseUrl = 'http://10.0.2.2:5001';
}
```

Notas importantes:

- `10.0.2.2` funciona en emulador Android para llegar al `localhost` del PC.
- En un dispositivo físico hay que usar la IP local del ordenador o la URL pública del servidor.

## 2. Despliegue en producción

El TFG indica que el despliegue se hizo sobre una máquina virtual Linux alojada en Clouding.io.

La idea fue centralizar el acceso con Nginx para exponer las APIs por HTTPS y no publicar los puertos internos directamente.

### 2.1 Arquitectura final

```text
Aplicación Flutter
        ↓
HTTPS (443)
        ↓
NGINX Reverse Proxy
   ├──> API principal Flask (5000)
   └──> API autenticación Flask (5001)
```

Esta arquitectura permite:

- centralizar el tráfico HTTPS,
- ocultar los puertos internos,
- mejorar la seguridad,
- simplificar el mantenimiento,
- automatizar el despliegue del backend.

### 2.2 URLs públicas usadas por Flutter

```dart
class AppConstants {
  static const String appName = 'AlmeriaRuta V2';
  static const String apiBaseUrl = 'https://c65277d8-ca60-4115-a023-14bb96542132.clouding.host';
  static const String authApiBaseUrl = 'https://c65277d8-ca60-4115-a023-14bb96542132.clouding.host/api';
}
```

Uso:

- `apiBaseUrl`: buses, líneas, paradas y llegadas.
- `authApiBaseUrl`: autenticación, notificaciones, tickets, recargas y operario.

## 3. Configuración de Nginx

El dominio se publica con una configuración que redirige HTTP a HTTPS y enruta las peticiones a cada API.

### 3.1 Redirección HTTP a HTTPS

```nginx
server {
    listen 80;
    server_name c65277d8-ca60-4115-a023-14bb96542132.clouding.host;

    return 301 https://$host$request_uri;
}
```

### 3.2 Servidor HTTPS

```nginx
server {
    listen 443 ssl;
    server_name c65277d8-ca60-4115-a023-14bb96542132.clouding.host;

    ssl_certificate /etc/letsencrypt/live/c65277d8-ca60-4115-a023-14bb96542132.clouding.host/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/c65277d8-ca60-4115-a023-14bb96542132.clouding.host/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:5001/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3.3 Qué enruta cada bloque

- `/` va a la API principal en `5000`.
- `/api/` va a la API de autenticación en `5001`.

## 4. Certificados SSL

Para habilitar HTTPS se usan certificados gratuitos de Let’s Encrypt.

### 4.1 Instalación de Certbot

```bash
sudo apt install certbot python3-certbot-nginx
```

### 4.2 Generación del certificado

```bash
sudo certbot --nginx -d c65277d8-ca60-4115-a023-14bb96542132.clouding.host
```

## 5. Preparación de MySQL

La API de autenticación necesita MySQL para usuarios, tickets, notificaciones y operario. En el TFG se deja un script de instalación y configuración que resume la puesta en marcha básica en Linux:

```bash
#!/bin/bash
set -x
#----------------------------------------------------

#----------------------------------------------------
# Variables de configuración 
#----------------------------------------------------

MYSQL_ROOT_PASSWORD=root

#----------------------------------------------------

#----------------------------------------------------
# Instalacíon de la pila LAMP
#----------------------------------------------------
# Actualizamos el sistema
apt update
apt upgrade -y


# Instalamos MySQL Server
apt install mysql-server -y

# Cambiamos la contraseña del usuario root
 mysql <<< "ALTER USER root@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD';"

# Configuramos MySQL para aceptar conexiones desde cualquier interfaz de red
sed -i "s/127.0.0.1/0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# Reiniciamos el servicio de MySQL
systemctl restart mysql
```

Después de dejar MySQL listo, se puede arrancar la API de autenticación para que cree o use las tablas necesarias.

## 6. Automatización del arranque

Al principio las APIs se iniciaban manualmente, pero después se automatizó su arranque con `systemd` para que quedaran activas tras reiniciar la máquina virtual.

### 6.1 Servicio para la API principal

```ini
[Unit]
Description=Almeria BusMaps API
After=network.target

[Service]
User=xrdpuser
WorkingDirectory=/home/xrdpuser/backend
ExecStart=/home/xrdpuser/backend/venv/bin/python /home/xrdpuser/backend/almeria_busmaps_api.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

### 6.2 Servicio para la API de autenticación

```ini
[Unit]
Description=Almeria Auth API
After=network.target

[Service]
User=xrdpuser
WorkingDirectory=/home/xrdpuser/backend
ExecStart=/home/xrdpuser/backend/venv/bin/python /home/xrdpuser/backend/almeria_auth_api.py
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
```

### 6.3 Activación de servicios

```bash
sudo systemctl daemon-reload
sudo systemctl enable almeria-busmaps
sudo systemctl enable almeriaruta-auth
sudo systemctl start almeria-busmaps
sudo systemctl start almeriaruta-auth
```

## 7. Flujo completo de despliegue

Resumen del flujo recomendado:

1. Subir el backend a la máquina Linux.
2. Crear el entorno virtual de Python.
3. Instalar dependencias.
4. Configurar MySQL.
5. Crear y activar los servicios `systemd`.
6. Configurar Nginx como reverse proxy.
7. Instalar y renovar certificados SSL con Let’s Encrypt.
8. Actualizar `app_constants.dart` para apuntar al dominio público.

## 8. Relación con la app Flutter

La app Flutter no necesita conocer los puertos internos cuando trabaja contra producción.

Solo consume:

- `https://c65277d8-ca60-4115-a023-14bb96542132.clouding.host`
- `https://c65277d8-ca60-4115-a023-14bb96542132.clouding.host/api`

Eso simplifica el despliegue y hace que la app tenga una única configuración de producción.

## 9. Resumen corto

- En local se usa `10.0.2.2:5000` y `10.0.2.2:5001`.
- En producción se usa un dominio HTTPS con Nginx como reverse proxy.
- Certbot genera los certificados SSL.
- `systemd` mantiene las APIs activas 24/7.
- Flutter cambia las URLs en `app_constants.dart` según el entorno.
