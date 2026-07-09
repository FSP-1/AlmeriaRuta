# Guía de instalación y ejecución de AlmeriaRuta

Este documento resume cómo preparar el entorno para seguir trabajando en el proyecto AlmeriaRuta, tanto en modo **local** como con las APIs desplegadas en un **servidor 24/7** accesible por DNS.

La guía se ha redactado a partir del TFG del proyecto y de la configuración real del repositorio, para que sirva como manual práctico de puesta en marcha y continuidad del desarrollo.

## 1. Qué hay que instalar

### 1.1 Flutter

Instala el SDK de Flutter en tu equipo y añádelo al `PATH`.

Recomendado:

- Flutter 3.x o superior.
- Git instalado.
- Visual Studio Code como editor principal, tal como se describe en el TFG.
- Android Studio para el SDK y el emulador Android.

Comprobación:

```bash
flutter doctor
```

El TFG indica que, además de Flutter, se usaron los plugins de **Flutter** y **Dart** en VS Code para autocompletado, depuración y ejecución directa del proyecto.

### 1.2 Android Studio

Android Studio se usa para tener el SDK de Android, el emulador y las herramientas de compilación.

Desde el instalador de Android Studio activa estos componentes:

- **Android SDK**
- **Android SDK Command-line Tools**
- **Android SDK Platform-Tools**
- **Android SDK Build-Tools**
- **Android Emulator**
- **Android Virtual Device (AVD)**
- Plugin de **Flutter**
- Plugin de **Dart**

Además, conviene tener al menos una imagen de sistema Android creada para probar la app en emulador.

El TFG cita como configuración habitual un emulador **Pixel 5 API 34** y también la instalación de **Android API 36** desde el SDK Manager.

### 1.3 Java / JDK

Flutter para Android necesita un JDK compatible.

Si Android Studio no lo deja resuelto automáticamente, instala un JDK reciente y verifica que `java -version` funciona.

### 1.4 Python

Las APIs del proyecto están hechas en Flask, así que necesitas Python 3.10 o superior.

Según el TFG, el backend se monta con Flask, `flask-cors`, `pandas`, `pymysql`, `cryptography` e `itsdangerous`.

### 1.5 MySQL

La API de autenticación usa MySQL para usuarios, tickets, notificaciones y operario.

Tienes dos formas habituales de prepararlo:

- **Con Docker + MySQL Workbench**: levantas un contenedor MySQL, gestionas la base de datos desde Workbench y luego arrancas la API de autenticación contra ese servidor.
- **Instalado de forma nativa en Linux**: instalas MySQL directamente en una distribución Linux, dejas el servicio activo y después ejecutas la API de autenticación contra esa instancia.

Necesitas:

- Servidor MySQL local o remoto.
- Usuario y contraseña con permisos para crear tablas.
- Base de datos accesible desde el backend.

Después de tener MySQL funcionando, arranca la API de autenticación para que cree las tablas y empiece a atender peticiones.

Si quieres dejarlo automatizado en un servidor Linux, este es el bloque de instalación y configuración que recoge la idea del TFG:

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

Después de ejecutar ese bloque, ya puedes lanzar la API de autenticación contra MySQL.

## 2. Estructura del proyecto

El repositorio está dividido en dos partes principales:

- `V2/almeriarutav02/`: aplicación móvil Flutter.
- `backend/`: APIs Flask.

La app móvil consume dos servicios:

- API de buses y paradas.
- API de autenticación, tickets, notificaciones y operario.

## 3. Ejecución en local

### 3.1 Modo local recomendado para desarrollar

En desarrollo local, la app Flutter puede apuntar a las APIs que corren en tu propia máquina usando `10.0.2.2` desde el emulador Android.

En el TFG se explica también que la app se ejecuta con `flutter emulators --launch Pixel_5` y luego `flutter run`.

La configuración local es esta:

```dart
class AppConstants {
  static const String appName = 'AlmeriaRuta V2';
  static const String apiBaseUrl = 'http://10.0.2.2:5000';
  static const String authApiBaseUrl = 'http://10.0.2.2:5001';
}
```

Importante:

- `10.0.2.2` funciona **solo en el emulador Android** para apuntar al `localhost` del PC anfitrión.
- Si pruebas en un móvil físico, usa la IP local del ordenador o el dominio público del servidor.

### 3.2 Arrancar el backend de buses

Desde la raíz del repositorio:

```bash
cd backend
pip install -r requirements.txt
python almeria_busmaps_api.py
```

Esta API arranca por defecto en el puerto `5000`.

### 3.3 Arrancar el backend de autenticación

En otra terminal:

```bash
cd backend
python almeria_auth_api.py
```

Esta API arranca por defecto en el puerto `5001` y expone autenticación, notificaciones, tickets, recargas y operario.

### 3.4 Arrancar la app Flutter

Desde la carpeta del cliente móvil:

```bash
cd V2/almeriarutav02
flutter pub get
flutter run
```

Si estás usando emulador Android, la app hablará con las APIs locales mediante `10.0.2.2`.

## 4. Modo con servidor público 24/7

Cuando las APIs no se quieren levantar manualmente en local y se necesita que estén siempre disponibles, lo recomendable es desplegarlas en un servidor/VPS con DNS público.

En el TFG la arquitectura final queda descrita como:

`Flutter App -> HTTPS (443) -> NGINX Reverse Proxy -> API principal Flask (5000) + API autenticación Flask (5001)`

La configuración usada por la app para ese caso es esta:

```dart
class AppConstants {
  static const String appName = 'AlmeriaRuta V2';
  static const String apiBaseUrl = 'https://c65277d8-ca60-4115-a023-14bb96542132.clouding.host';
  static const String authApiBaseUrl = 'https://c65277d8-ca60-4115-a023-14bb96542132.clouding.host/api';
}
```

### 4.1 Qué significa cada URL

- `apiBaseUrl`: servicio público de buses, líneas, paradas y llegadas.
- `authApiBaseUrl`: servicio de autenticación, notificaciones, tickets, recargas y operario.

### 4.2 Qué necesita el servidor

Para tener las APIs expuestas a internet las 24 horas, el servidor debe tener:

- Una IP pública o un DNS apuntando al servidor.
- Python 3 y las dependencias instaladas.
- MySQL accesible desde el backend de autenticación.
- Puertos abiertos en el firewall.
- Un proceso que arranque automáticamente al reiniciar el sistema.

### 4.3 Despliegue recomendado en producción

Aunque en local se puede lanzar con `python archivo.py`, en servidor conviene evitar el servidor de desarrollo de Flask.

Lo recomendado es:

- Ejecutar cada API como servicio del sistema.
- Usar un proceso persistente como `gunicorn` o similar para el backend Python.
- Colocar un proxy inverso como Nginx delante si se quiere publicar por `80/443`.
- Gestionar el arranque automático con `systemd`.

El TFG muestra unidades `systemd` con `Restart=always` y `RestartSec=5` para mantener las APIs activas las 24 horas.

### 4.4 Ejemplo de puesta en marcha en servidor

Flujo habitual:

1. Instalar Python, MySQL y dependencias.
2. Subir el código al VPS.
3. Crear un entorno virtual de Python.
4. Instalar paquetes con `pip`.
5. Configurar variables de entorno si aplica.
6. Crear servicios `systemd` para que las APIs arranquen al inicio.
7. Abrir el DNS o IP pública para que Flutter consuma las URLs.

En el documento original también se deja constancia de que la API pública de buses se expone en `5000`, la de autenticación en `5001`, y que Nginx puede enrutar `/lines` hacia buses y `/api` hacia autenticación.

### 4.5 Ejemplo de servicios persistentes

Idea general:

- Un servicio para la API de buses en `5000`.
- Un servicio para la API de autenticación en `5001`.

Si prefieres publicar todo por un dominio único, el proxy inverso puede enrutar:

- `/` o `/lines` hacia la API de buses.
- `/api` hacia la API de autenticación.

Eso encaja con la configuración actual de `authApiBaseUrl`, que ya incluye `/api`.

### 4.6 Recomendación de seguridad mínima

Si las APIs van a estar expuestas en internet:

- Usa HTTPS.
- No dejes credenciales en el código.
- Protege MySQL con contraseña fuerte y acceso restringido.
- Abre solo los puertos necesarios.
- Mantén el backend detrás de un proxy si vas a usar un dominio público.

## 5. Qué cambiar entre local y servidor

### 5.1 Desarrollo local

Usa estas URLs:

```dart
static const String apiBaseUrl = 'http://10.0.2.2:5000';
static const String authApiBaseUrl = 'http://10.0.2.2:5001';
```

### 5.2 Servidor con DNS público

Usa estas URLs:

```dart
static const String apiBaseUrl = 'https://c65277d8-ca60-4115-a023-14bb96542132.clouding.host';
static const String authApiBaseUrl = 'https://c65277d8-ca60-4115-a023-14bb96542132.clouding.host/api';
```

## 6. Comandos útiles

### Flutter

```bash
flutter doctor
flutter pub get
flutter run
flutter test
```

### Backend de buses

```bash
cd backend
python almeria_busmaps_api.py
```

### Backend de autenticación

```bash
cd backend
python almeria_auth_api.py
```

## 7. Qué hacer si algo falla

- Si Flutter no detecta el SDK, revisa el `PATH`.
- Si Android Studio no compila, verifica que el SDK de Android y el emulador están instalados.
- Si la app no conecta con las APIs locales, revisa que estés usando emulador Android y `10.0.2.2`.
- Si el backend de autenticación no arranca, comprueba MySQL y las credenciales.
- Si las APIs están en servidor pero la app no responde, revisa el DNS, HTTPS y el firewall.

## 8. Resumen rápido

Para continuar trabajando en el proyecto:

1. Instala Flutter, VS Code con plugins de Flutter/Dart y Android Studio con el SDK y el emulador.
2. Usa `flutter doctor`, `flutter pub get`, `flutter emulators --launch Pixel_5` y `flutter run`.
3. Si trabajas en local, apunta a `http://10.0.2.2:5000` y `http://10.0.2.2:5001`.
4. Si trabajas contra servidor, usa las URLs públicas de Clouding y mantén las APIs vivas con `systemd` + Nginx.
