# API Conexión App y Optimización - Documentación Técnica Completa

## Objetivo

Este documento explica complétamente:

1. **Arquitectura del Backend** - APIs Python/Flask disponibles, endpoints y lógica de negocio
2. **Código del Backend** - Archivos, rutas, controladores y repositories
3. **Integración con Frontend** - Cómo Flutter consume cada endpoint
4. **Arquitectura de Datos** - Modelos, cachés y optimizaciones
5. **Flujo End-to-End** - Desde UI hasta base de datos y vuelta

---

## PARTE 1: ARQUITECTURA DEL BACKEND

### 1.1 Visión General de Servicios

El backend está dividido en **2 APIs Flask independientes**:

| API                   | Puerto | Responsabilidad                                   | BD                |
| --------------------- | ------ | ------------------------------------------------- | ----------------- |
| **BusMaps API** | 5000   | Líneas, paradas, llegadas (GTFS)                 | Datos GTFS (ALSA) |
| **Auth API**    | 5001   | Autenticación, usuarios, tickets, notificaciones | MySQL             |

Ambas corren en `0.0.0.0` para aceptar conexiones desde cualquier IP.

### 1.2 Stack Tecnológico Backend

**requirements.txt:**

```
flask>=3.0.0              # Framework web
flask-cors>=4.0.0         # CORS para consumo desde Flutter
pandas>=2.0.0             # Análisis de datos GTFS
pymysql>=1.1.0            # Driver MySQL
cryptography>=43.0.0      # Hashing de contraseñas (PBKDF2)
itsdangerous>=2.2.0       # Firmado de tokens JWT-like
```

---

## PARTE 2: BUS MAPS API (Puerto 5000)

### 2.1 Archivo: `almeria_busmaps_api.py`

**Propósito:** Servir datos de líneas urbanas y paradas basados en GTFS (General Transit Feed Specification) de ALSA.

#### Inicialización

```python
app = Flask(__name__)
CORS(app)

class BusMapsClient:
    def __init__(self):
        gtfs_path = os.path.join(os.path.dirname(__file__), "alsa-autobuses.zip")
      
        # Carga datos desde ZIP de GTFS
        with zipfile.ZipFile(gtfs_path) as z:
            self.routes = pd.read_csv(z.open("routes.txt"))      # Líneas
            self.stops = pd.read_csv(z.open("stops.txt"))         # Paradas
            self.trips = pd.read_csv(z.open("trips.txt"))         # Viajes
            self.stop_times = pd.read_csv(z.open("stop_times.txt")) # Horarios
```

**Datos GTFS cargados:**

- **routes.txt**: Todas las líneas (incluyendo rurales)
- **stops.txt**: Todas las paradas de España
- **trips.txt**: Cada viaje único (combinación de ruta + dirección)
- **stop_times.txt**: Horarios de paso en cada parada

#### Normalización de Stop IDs

```python
def normalize_stop_id(stop_id):
    """Normaliza IDs de parada: quita letras (E000..., S000...) y solo deja dígitos"""
    if pd.isna(stop_id):
        return None
    stop_id = ''.join(filter(str.isdigit, str(stop_id)))
    return str(int(stop_id))
```

#### Filtrado de Líneas de Almería

```python
# IDs conocidos de líneas urbanas de Almería
almeria_route_ids = {
    2330, 2331, 2333, 2334, 2335, 2336, 2337, 2338, 2339, 2340, 
    2341, 2344, 2487, 2488, 3561, 3562
}

# Filtrado por coordenadas (respaldo)
almeria_stops = self.stops[
    (self.stops['stop_lat'].between(36.75, 36.90)) &
    (self.stops['stop_lon'].between(-2.55, -2.35))
]
```

#### Cálculo de Tiempo Actual

```python
def parse_gtfs_time_to_seconds(time_str):
    """Convierte HH:MM:SS a segundos desde inicio del día (soporta HH>=24)"""
    if pd.isna(time_str):
        return None
    try:
        hh, mm, ss = str(time_str).split(':')
        return int(hh) * 3600 + int(mm) * 60 + int(ss)
    except Exception:
        return None

def _now_seconds_service_day(self):
    """Calcula segundos desde inicio del día de servicio"""
    now = datetime.now()
    return now.hour * 3600 + now.minute * 60 + now.second
```

### 2.2 ENDPOINTS BUS MAPS API

#### **GET /lines**

Retorna todas las líneas urbanas de Almería con todas sus paradas.

**Request:**

```http
GET http://localhost:5000/lines
```

**Response (200 OK):**

```json
[
  {
    "id": "1",
    "name": "1",
    "fullName": "Centro - Teatro",
    "description": "Línea urbana principal",
    "color": "#002786",
    "frequency": "15-30 min",
    "firstService": "06:30",
    "lastService": "22:30",
    "totalStops": 18,
    "stops": [
      {
        "id": "123456",
        "name": "Estación de Autobuses",
        "lat": 36.8381,
        "lon": -2.4597,
        "zone": "Centro"
      },
      {
        "id": "123457",
        "name": "Plaza Vieja",
        "lat": 36.8392,
        "lon": -2.4602,
        "zone": "Centro"
      }
    ]
  },
  {
    "id": "2",
    "name": "2",
    "fullName": "Centro - San Antón",
    ...
  }
]
```

**Lógica interna:**

1. Itera sobre líneas urbanas de Almería (`urban_routes_almeria`)
2. Para cada línea, obtiene trips (viajes) agrupados por dirección
3. Para cada trip, obtiene paradas desde `stop_times`
4. Enriquece cada parada con zona calculada por GPS
5. Elimina duplicados manteniendo orden
6. **Cache en memoria** en `self.lines_cache`

#### **GET /lines//stops**

Retorna solo las paradas de una línea.

**Request:**

```http
GET http://localhost:5000/lines/1/stops
```

**Response (200 OK):**

```json
[
  {
    "id": "123456",
    "name": "Estación de Autobuses",
    "lat": 36.8381,
    "lon": -2.4597,
    "zone": "Centro"
  },
  {
    "id": "123457",
    "name": "Plaza Vieja",
    "lat": 36.8392,
    "lon": -2.4602,
    "zone": "Centro"
  }
]
```

#### **GET /lines//arrivals**

Retorna tiempos de llegada programados por parada para una línea.

**Request:**

```http
GET http://localhost:5000/lines/1/arrivals
```

**Response (200 OK):**

```json
{
  "lineId": "1",
  "generatedAt": "2026-04-09T14:32:15.123456",
  "arrivals": [
    {
      "stopId": "123456",
      "minutes": 5
    },
    {
      "stopId": "123457",
      "minutes": 12
    }
  ]
}
```

**Lógica:**

1. Obtiene hora actual en segundos desde inicio de día
2. Para cada parada de la línea, calcula llegada más próxima
3. Si llegada pasada, suma 86400 segundos (día siguiente)
4. Convierte a minutos redondeados (min 1)
5. **Cache con expiry:** Se reutiliza si fue hace <30 segundos

#### **GET /stops/**

Retorna detalles de una parada.

**Request:**

```http
GET http://localhost:5000/stops/123456
```

**Response (200 OK):**

```json
{
  "id": "123456",
  "name": "Estación de Autobuses",
  "lat": 36.8381,
  "lon": -2.4597,
  "zone": "Centro",
  "arrivals": [
    {
      "lineId": "1",
      "minutes": 5
    },
    {
      "lineId": "2",
      "minutes": 10
    }
  ]
}
```

#### **GET /stops//arrivals**

Retorna próximas llegadas de líneas en una parada.

**Request:**

```http
GET http://localhost:5000/stops/123456/arrivals?limit=3
```

**Query Params:**

- `limit` (int, default=3): Número máximo de llegadas a retornar

**Response (200 OK):**

```json
[
  {
    "lineId": "1",
    "minutes": 5
  },
  {
    "lineId": "2",
    "minutes": 10
  },
  {
    "lineId": "3",
    "minutes": 18
  }
]
```

---

## PARTE 3: AUTH API (Puerto 5001)

### 3.1 Archivos del Módulo `auth_mvc`

#### **3.1.1 repository.py** - Capa de Datos

Gestiona conexión MySQL y operaciones CRUD.

```python
class AuthRepository:
    def __init__(self):
        self.host = os.getenv('MYSQL_HOST', '127.0.0.1')
        self.port = int(os.getenv('MYSQL_PORT', '3306'))
        self.user = os.getenv('MYSQL_USER', 'root')
        self.password = os.getenv('MYSQL_PASSWORD', 'root')
        self.database = os.getenv('MYSQL_DATABASE', 'db')
  
    def _conn(self):
        """Retorna conexión MySQL con autocommit"""
        return pymysql.connect(
            host=self.host,
            port=self.port,
            user=self.user,
            password=self.password,
            database=self.database,
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=True,
        )
```

**Tablas creadas por `init_schema()`:**

```sql
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    username VARCHAR(80) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE app_notifications (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    user_id BIGINT NOT NULL,
    title VARCHAR(180) NOT NULL,
    body VARCHAR(500) NOT NULL,
    payload_json LONGTEXT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_notifications_user (user_id),
    CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) 
        REFERENCES users(id) ON DELETE CASCADE
);
```

**Métodos clave:**

- `create_user(email, username, password_hash)` → BIGINT (user_id)
- `find_user_by_email_or_username(value)` → Dict o None
- `find_user_by_id(user_id)` → Dict o None
- `create_notification(user_id, title, body, payload_json)` → BIGINT (notification_id)
- `list_notifications(user_id, unread_only=False, limit=50)` → List[Dict]
- `mark_notification_read(user_id, notification_id)` → int (affected rows)
- `find_notification(user_id, notification_id)` → Dict o None
- `delete_notification(user_id, notification_id)` → int (affected rows)

#### **3.1.2 service.py** - Lógica de Negocio

```python
class AuthService:
    def __init__(self, repository, secret_key: str, token_ttl_seconds: int):
        self.repo = repository
        self.token_ttl_seconds = token_ttl_seconds
        self._token_serializer = URLSafeTimedSerializer(secret_key)
```

**Métodos de autenticación:**

```python
# Hash de contraseñas con PBKDF2-SHA256
def hash_password(self, password: str) -> str:
    """
    Genera hash seguro: SALT$DIGEST donde:
    - SALT: 32 caracteres aleatorios hexadecimales
    - DIGEST: PBKDF2-HMAC-SHA256 con 100,000 iteraciones
    """
    salt = secrets.token_hex(16)  # 32 chars
    digest = hashlib.pbkdf2_hmac(
        'sha256', 
        password.encode('utf-8'), 
        salt.encode('utf-8'), 
        100_000
    )
    return f"{salt}${digest.hex()}"

def verify_password(self, password: str, encoded: str) -> bool:
    """Verifica contraseña contra hash usando HMAC timing-safe"""
    ...

# Manejo de tokens
def issue_token(self, payload: dict) -> str:
    """Crea token firmado con TTL de 7 días"""
    return self._token_serializer.dumps(payload)

def parse_token(self, token: str):
    """Valida y parsea token, lanza SignatureExpired o BadSignature"""
    return self._token_serializer.loads(token, max_age=self.token_ttl_seconds)
```

**Métodos de validación:**

```python
@staticmethod
def is_valid_email(email: str) -> bool:
    return bool(re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email))

@staticmethod
def is_valid_username(username: str) -> bool:
    # 3-20 caracteres, permite acentos y números
    return bool(re.match(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9_ ]{3,20}$', username))

@staticmethod
def is_strong_password(password: str) -> bool:
    # Mínimo 8 caracteres, debe tener letra y número
    if len(password) < 8:
        return False
    has_letter = re.search(r'[A-Za-z]', password)
    has_number = re.search(r'[0-9]', password)
    return bool(has_letter and has_number)
```

**Métodos principales de negocio:**

```python
def register(self, email: str, username: str, password: str) -> tuple:
    """
    Registra nuevo usuario.
  
    Validaciones:
    - Email válido y único
    - Username válido (3-20 chars), único, sin mayúsculas
    - Contraseña fuerte (8+ chars, letra+número)
  
    Retorna (payload: dict, status_code: int)
    """

def login(self, identifier: str, password: str) -> tuple:
    """
    Login por email o username + contraseña.
  
    Retorna token JWT-like + user info si es válido.
    """

def guest(self) -> tuple:
    """
    Crea sesión anónima.
  
    Retorna token con username 'Invitado-XXXXX' y guest=True
    """

def me(self, auth_data: dict) -> tuple:
    """Retorna info del usuario autenticado"""

def purchase_ticket(self, auth_data: dict, body: dict) -> tuple:
    """
    Registra compra de ticket.
  
    Params:
    - recipientIdentifier: email o username del destinatario
    - validateOnly: bool (solo valida sin crear)
    - type: 'Individual', 'Multiple', 'MonthPass'
    - paymentMethod: 'Google Pay', 'Card'
    - quantity: int
    - amount: float
  
    Crea notificación al destinatario si aplica.
    """

def list_notifications(self, user_id: int, unread_only: bool = False) -> tuple:
    """Retorna notificaciones del usuario"""
```

#### **3.1.3 controller.py** - Rutas HTTP

Define blueprint con decoradores de autenticación.

```python
def _extract_bearer_token():
    """
    Extrae token del header Authorization: Bearer <token>
    """

def auth_required(allow_guest=False):
    """
    Decorador que:
    1. Extrae token del header
    2. Lo parsea (valida firma y TTL)
    3. Lo coloca en request.auth
    4. Rechaza si guest=True sin allow_guest
    """
```

### 3.2 ENDPOINTS AUTH API

#### **POST /auth/register**

Registra nuevo usuario.

**Request:**

```http
POST http://localhost:5001/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "username": "mi_usuario",
  "password": "Password123"
}
```

**Response (200 OK):**

```json
{
  "token": "eyJ0eXAiOiJKV1QiLC... (long token)",
  "user": {
    "id": 1,
    "email": "user@example.com",
    "username": "mi_usuario",
    "guest": false
  }
}
```

**Error responses:**

- `400`: Email/username/password inválido
- `409`: Usuario ya existe
- `500`: Error en BD

#### **POST /auth/login**

Inicia sesión.

**Request:**

```http
POST http://localhost:5001/auth/login
Content-Type: application/json

{
  "identifier": "user@example.com",
  "password": "Password123"
}
```

**Response (200 OK):**

```json
{
  "token": "...",
  "user": { ... }
}
```

**Error responses:**

- `400`: Credenciales requeridas
- `401`: Credenciales incorrectas

#### **POST /auth/guest**

Crea sesión anónima (sin credenciales).

**Request:**

```http
POST http://localhost:5001/auth/guest
```

**Response (200 OK):**

```json
{
  "token": "...",
  "user": {
    "id": null,
    "email": null,
    "username": "Invitado-a1b2c3",
    "guest": true
  }
}
```

#### **GET /auth/me** *(Requiere token)*

Obtiene info del usuario autenticado.

**Request:**

```http
GET http://localhost:5001/auth/me
Authorization: Bearer eyJ0eXAiOiJKV1QiLC...
```

**Response (200 OK - Usuario registrado):**

```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "mi_usuario",
  "guest": false
}
```

**Response (200 OK - Invitado):**

```json
{
  "id": null,
  "email": null,
  "username": "Invitado-a1b2c3",
  "guest": true
}
```

**Error responses:**

- `401`: Token expirado o inválido
- `404`: Usuario no encontrado

#### **POST /auth/tickets/purchase** *(Requiere token registrado)*

Compra de tickets con opción de envío a otro usuario.

**Request:**

```http
POST http://localhost:5001/auth/tickets/purchase
Authorization: Bearer eyJ0eXAiOiJKV1QiLC...
Content-Type: application/json

{
  "recipientIdentifier": "otro_usuario@example.com",
  "type": "Individual",
  "paymentMethod": "Google Pay",
  "quantity": 5,
  "amount": 12.50,
  "validateOnly": false
}
```

**Response (200 OK - Validación):**

```json
{
  "success": true,
  "validateOnly": true,
  "recipient": {
    "id": 2,
    "email": "otro_usuario@example.com",
    "username": "otro_usuario"
  }
}
```

**Response (200 OK - Compra realizada):**

```json
{
  "success": true,
  "ticket": {
    "id": "TK-a1b2c3d4e5",
    "type": "Individual",
    "quantity": 5,
    "remainingUses": 5,
    "purchaseDate": "2026-04-09T14:32:15.123456",
    "amount": 12.50,
    "status": "Activo"
  },
  "notification": {
    "id": 1,
    "userId": 2,
    "title": "Nuevo ticket recibido",
    "body": "usuario_comprador te ha comprado 5 tickets Individual."
  }
}
```

**Error responses:**

- `400`: Datos inválidos, destinatario no especificado
- `403`: Acceso solo para registrados
- `404`: Destinatario no encontrado
- `500`: Error en BD

#### **GET /auth/notifications** *(Requiere token registrado)*

Lista notificaciones del usuario.

**Request:**

```http
GET http://localhost:5001/auth/notifications?unreadOnly=false
Authorization: Bearer eyJ0eXAiOiJKV1QiLC...
```

**Query Params:**

- `unreadOnly` (bool, default=false): Solo no leídas

**Response (200 OK):**

```json
[
  {
    "id": 1,
    "title": "Nuevo ticket recibido",
    "body": "usuario_x te ha comprado 5 tickets Individual.",
    "payload_json": "{\"ticket\": {...}}",
    "is_read": false,
    "created_at": "2026-04-09T14:32:15.123456"
  }
]
```

---

## PARTE 4: SERVICIOS DE API FLUTTER

### 4.1 Archivo: `lib/shared/services/bus_api_service.dart`

**Propósito:** Encapsular todas las llamadas HTTP a ambas APIs con caching y deduplicación.

```dart
class BusApiService {
  static final http.Client _client = http.Client();

  // Cache de líneas (cargar una sola vez por sesión)
  static List<LineModel>? _linesCache;
  static Future<List<LineModel>>? _inFlightLines;

  // Cache de paradas por línea
  static final Map<String, List<StopModel>> _stopsCache = {};
  static final Map<String, Future<List<StopModel>>> _inFlightStops = {};

  // Cache de llegadas por línea (con expiración)
  static final Map<String, Map<String, int>> _lineArrivalsCache = {};
  static final Map<String, DateTime> _lineArrivalsFetchedAt = {};
  static final Map<String, Future<Map<String, int>>> _inFlightLineArrivals = {};
```

#### Métodos de Líneas

```dart
Future<List<LineModel>> getLines({bool forceRefresh = false}) async {
  // 1. Si hay cache válido y no es force refresh, retorna cache
  if (!forceRefresh && _linesCache != null) {
    return _linesCache!;
  }

  // 2. Si hay petición en vuelo, reutiliza la Future
  if (!forceRefresh && _inFlightLines != null) {
    return _inFlightLines!;
  }

  // 3. Crea nueva petición y la marca como en vuelo
  final future = _fetchLines();
  _inFlightLines = future;
  
  try {
    final lines = await future;
    _linesCache = lines;
    return lines;
  } finally {
    _inFlightLines = null;  // Limpia referencia
  }
}

Future<List<LineModel>> _fetchLines() async {
  final response = await _getWithRetry(
    Uri.parse('${AppConstants.apiBaseUrl}/lines')
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => LineModel.fromJson(json)).toList();
  }
  
  throw Exception('Error al cargar lineas');
}
```

**Patrón de caching:**

- Cache persistente en variable estática
- Deduplicación con `_inFlightLines` (si dos vistas piden a la vez, comparten Future)
- `forceRefresh` para invalidar cache manualmente

#### Métodos de Paradas

```dart
Future<List<StopModel>> getLineStops(String lineId, {bool forceRefresh = false}) async {
  // Cache por línea
  if (!forceRefresh && _stopsCache.containsKey(lineId)) {
    return _stopsCache[lineId]!;
  }

  // Deduplicación por línea
  if (!forceRefresh && _inFlightStops.containsKey(lineId)) {
    return _inFlightStops[lineId]!;
  }

  final future = _fetchStops(lineId);
  _inFlightStops[lineId] = future;
  
  try {
    final stops = await future;
    _stopsCache[lineId] = stops;
    return stops;
  } finally {
    _inFlightStops.remove(lineId);
  }
}

Future<List<StopModel>> _fetchStops(String lineId) async {
  final response = await _getWithRetry(
    Uri.parse('${AppConstants.apiBaseUrl}/lines/$lineId/stops')
  );
  
  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => StopModel.fromJson(json)).toList();
  }
  
  throw Exception('Error al cargar paradas');
}
```

#### Métodos de Llegadas

```dart
Future<Map<String, int>> getLineArrivals(String lineId, {bool forceRefresh = false}) async {
  final fetchedAt = _lineArrivalsFetchedAt[lineId];
  // Cache con expiración: 30 segundos
  final isFresh = fetchedAt != null && 
      DateTime.now().difference(fetchedAt).inSeconds < 30;

  if (!forceRefresh && isFresh && _lineArrivalsCache.containsKey(lineId)) {
    return _lineArrivalsCache[lineId]!;
  }

  // Deduplicación
  if (!forceRefresh && _inFlightLineArrivals.containsKey(lineId)) {
    return _inFlightLineArrivals[lineId]!;
  }

  final future = _fetchLineArrivals(lineId);
  _inFlightLineArrivals[lineId] = future;
  
  try {
    final arrivals = await future;
    _lineArrivalsCache[lineId] = arrivals;
    _lineArrivalsFetchedAt[lineId] = DateTime.now();
    return arrivals;
  } finally {
    _inFlightLineArrivals.remove(lineId);
  }
}

Future<Map<String, int>> _fetchLineArrivals(String lineId) async {
  final response = await _getWithRetry(
    Uri.parse('${AppConstants.apiBaseUrl}/lines/$lineId/arrivals')
  );

  if (response.statusCode != 200) {
    throw Exception('Error al cargar tiempos');
  }

  final data = json.decode(response.body) as Map<String, dynamic>;
  final arrivals = (data['arrivals'] as List<dynamic>? ?? const []);

  final result = <String, int>{};
  for (final item in arrivals) {
    if (item is Map<String, dynamic>) {
      final stopId = item['stopId']?.toString();
      final minutes = item['minutes'];
      if (stopId != null && minutes is num) {
        result[stopId] = minutes.toInt();
      }
    }
  }
  return result;
}

Future<Map<String, int>> getStopArrivals(String stopId, {int limit = 3}) async {
  final response = await _getWithRetry(
    Uri.parse('${AppConstants.apiBaseUrl}/stops/$stopId/arrivals?limit=$limit')
  );

  if (response.statusCode != 200) {
    throw Exception('Error al cargar tiempos de llegada por parada');
  }

  final data = json.decode(response.body);
  if (data is! List) {
    return <String, int>{};
  }

  final result = <String, int>{};
  for (final item in data) {
    if (item is Map<String, dynamic>) {
      final lineId = item['lineId']?.toString();
      final minutes = item['minutes'];
      if (lineId != null && minutes is num) {
        result[lineId] = minutes.toInt();
      }
    }
  }
  return result;
}
```

#### Retry y Timeout

```dart
Future<http.Response> _getWithRetry(Uri uri) async {
  const maxRetries = 2;
  const timeout = Duration(seconds: 10);
  
  for (int i = 0; i <= maxRetries; i++) {
    try {
      return await _client
          .get(uri)
          .timeout(timeout);  // Timeout de 10 segundos
    } on SocketException {
      if (i == maxRetries) rethrow;  // Última vez, lanza error
      await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
    } on TimeoutException {
      if (i == maxRetries) rethrow;
      await Future.delayed(Duration(milliseconds: 200 * (i + 1)));
    }
  }
}
```

---

## PARTE 5: VIEWMODELS Y CONSUMO DE API

### 5.1 Map ViewModel - `lib/features/map/viewmodels/map_viewmodel.dart`

**Propósito:** Gestionar estado del mapa de paradas.

```dart
class MapViewModel extends ChangeNotifier {
  final BusApiService _apiService = BusApiService();
  
  // Estado de negocio
  List<StopModel> _stops = [];
  List<LineModel> _lines = [];
  LatLng? _userLocation;
  bool _initialized = false;

  // Inicialización
  Future<void> initialize() async {
    if (_initialized) return;  // Guard contra reinicialización

    await getCurrentLocation();
    await loadStops();
    await refreshFavoriteStops();
    _initialized = true;
  }

  // Carga de paradas en paralelo
  Future<void> loadStops() async {
    if (_isLoadingStops) return;  // Guard contra recarga

    _isLoadingStops = true;
    notifyListeners();

    try {
      // Obtiene todas las líneas
      _lines = await _apiService.getLines();
    
      // Carga paradas de TODAS las líneas en paralelo
      final futures = _lines
          .map((line) => _apiService.getLineStops(line.id))
          .toList();
    
      final allStopsLists = await Future.wait(futures);
    
      // Agrega todas las paradas, eliminando duplicados
      final stopsSet = <String, StopModel>{};
      for (final stopsList in allStopsLists) {
        for (final stop in stopsList) {
          if (!stopsSet.containsKey(stop.id)) {
            stopsSet[stop.id] = stop;
          }
        }
      }
    
      _stops = stopsSet.values.toList();
    } catch (e) {
      _errorMessage = 'Error al cargar paradas: $e';
    } finally {
      _isLoadingStops = false;
      notifyListeners();
    }
  }
}
```

**Optimizaciones aplicadas:**

1. Guard `_initialized` evita recargar todo al navegar al mapa
2. Guard `_isLoadingStops` evita cargas concurrentes
3. `Future.wait()` para parallelismo (vs. cargas secuenciales)
4. Deduplicación manual de paradas (mismo stop en múltiples líneas)

### 5.2 Home ViewModel - `lib/features/home/viewmodels/home_viewmodel.dart`

**Propósito:** Cargar líneas para mostrar en home.

```dart
class HomeViewModel extends ChangeNotifier {
  final BusApiService _apiService = BusApiService();
  
  List<LineModel> _lines = [];
  bool _isLoading = false;

  Future<void> loadLines({bool forceRefresh = false}) async {
    if (!forceRefresh && _isLoading) return;  // Evita recarga concurrente
    if (!forceRefresh && _lines.isNotEmpty) return;  // Usa cache

    _isLoading = true;
    notifyListeners();

    try {
      _lines = await _apiService.getLines(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Muestra número de líneas en subtitle
  List<MobilityServiceModel> get busServices => [
    MobilityServiceModel(
      title: 'Líneas de Autobús',
      subtitle: _isLoading 
          ? 'Cargando...' 
          : '${_lines.length} líneas disponibles',
    ),
    // ... otros servicios
  ];
}
```

**Optimizaciones:**

1. No recarga si `_isLoading` es true
2. Usa cache local si ya hay líneas cargadas
3. `forceRefresh: true` solo desde botón explícito

### 5.3 Lines ViewModel - `lib/features/lines/viewmodels/lines_viewmodel.dart`

**Propósito:** Gestionar líneas y actualizar llegadas en tiempo real.

```dart
class LinesViewModel extends ChangeNotifier {
  final BusApiService _apiService = BusApiService();

  List<LineModel> _lines = [];
  final Map<String, List<StopModel>> _lineStopsCache = {};
  final Map<String, Map<String, int>> _arrivalsByLine = {};
  final Set<String> _watchedLines = {};  // Líneas viendo en tiempo real
  Timer? _clockTimer;  // Timer para actualizar cada 30 segundos

  Future<void> loadLines({bool forceRefresh = false}) async {
    _ensureClockRunning();  // Inicia timer si no está activo

    if (!forceRefresh && (_isLoading || _lines.isNotEmpty)) {
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _lines = await _apiService.getLines(forceRefresh: forceRefresh);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _ensureClockRunning() {
    _clockTimer ??= Timer.periodic(Duration(seconds: 30), (_) {
      // Cada 30 segundos, actualiza llegadas de líneas viendo
      for (final lineId in _watchedLines) {
        ensureLineArrivals(lineId, forceRefresh: true);
      }
      notifyListeners();
    });
  }

  Future<List<StopModel>> getLineStops(String lineId) async {
    final cached = _lineStopsCache[lineId];
    if (cached != null) {
      return cached;
    }

    final stops = await _apiService.getLineStops(lineId);
    _lineStopsCache[lineId] = stops;
    return stops;
  }

  Future<void> ensureLineArrivals(String lineId, {bool forceRefresh = false}) async {
    _watchedLines.add(lineId);  // Marca como viendo
  
    try {
      final arrivals = await _apiService.getLineArrivals(
        lineId, 
        forceRefresh: forceRefresh
      );
      _arrivalsByLine[lineId] = arrivals;
      notifyListeners();
    } catch (e) {
      print('Error cargando llegadas: $e');
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();  // Limpia timer al salir de pantalla
    super.dispose();
  }
}
```

**Optimizaciones:**

1. Timer de 30 segundos para actualizar solo líneas viendo
2. `_watchedLines` para no actualizar líneas no visibles
3. Cache de paradas por línea

---

## PARTE 6: FLUJO COMPLETO END-TO-END

### Ejemplo: Usuario entra a ver mapa con filtro "Paradas cercanas"

```
┌─ Flutter UI (MapView)
│   └─ onInit(): mapViewModel.initialize()
│
├─ mapViewModel.initialize()
│   ├─ getCurrentLocation() → GPS 36.8381, -2.4597
│   └─ loadStops()
│       ├─ _apiService.getLines()
│       │   ├─ Uri: http://localhost:5000/lines
│       │   ├─ [Retry x2 si falla, TO 10s]
│       │   ├─ Parse JSON → List<LineModel>
│       │   ├─ Cache en _linesCache
│       │   └─ Retorna ~16 líneas
│       │
│       └─ Future.wait() → getLineStops para cada línea
│           ├─ Uri: http://localhost:5000/lines/1/stops
│           ├─ Uri: http://localhost:5000/lines/2/stops
│           ├─ ... (paralelo, no secuencial)
│           └─ Agregar ~500 paradas únicas
│
├─ mapViewModel._stops populated
│   └─ notifyListeners() → UI rebuild
│
└─ MapView renderiza
    ├─ 500 markers en los puntos {lat, lon} de paradas
    ├─ Al hacer tap en marker
    │   └─ Obtiene parada desde _stops
    │       └─ Muestra popup con arribos (desde cache de llegadas)
    │
    └─ Botón "Ver línea"
        └─ Navega a LinesView con lineId
            └─ LinesViewModel.ensureLineArrivals(lineId)
                ├─ _apiService.getLineArrivals(lineId)
                │   ├─ Uri: http://localhost:5000/lines/1/arrivals
                │   ├─ Calcula tiempos programados por parada
                │   ├─ Cache con expiración 30s
                │   └─ Retorna {stopId → minutes}
                │
                └─ Timer.periodic(30s) refrescaautomáticamente
                    └─ Mientras el usuario está viendo la línea
```

---

## PARTE 7: PROBLEMAS REALES Y MITIGACIONES

| Problema                                 | Síntoma                   | Mitigación                                 |
| ---------------------------------------- | -------------------------- | ------------------------------------------- |
| Múltiples GET /lines simultáneos       | `_inFlightLines` es null | Deduplicación con Future reutilizada       |
| Paradas sin cargar en mapa               | Estado no se actualiza     | Parallelismo con Future.wait()              |
| "Connection closed while receiving data" | Error intermitente red     | Retry automático x2 + backoff exponencial  |
| Llegadas sin refrescar en real-time      | Pantalla estática         | Timer cada 30s en LinesViewModel            |
| Código duplicado en vistas              | Múltiples http.get()      | BusApiService centralizada                  |
| Cache que no expira                      | Datos старый         | Cache con timestamp + TTL de 30s (llegadas) |

---

## PARTE 8: BUENAS PRÁCTICAS ACTUALES

✅ **Hacer:**

1. Usar `BusApiService` como única puerta de acceso HTTP
2. Guardar `_initialized` para evitar re-init del mapa
3. Usar `forceRefresh: true` solo desde botones de usuario
4. Cache persistente para líneas / paradas
5. Deduplicación con `_inFlightXXX` para peticiones concurrentes
6. Timer con `_watchedLines` para solo actualizar lo visible
7. Timeout de 10s + Retry x2 con backoff

❌ **Evitar:**

1. Calls HTTP directo desde vistas (rompe encapsulación)
2. Recargar líneas sin guardas
3. Peticiones secuenciales (usar Future.wait)
4. Cache sin expiración
5. Initialize() repetido sin check

---

## PARTE 9: REFERENCIAS RÁPIDAS

| Recurso         | Ubicación                                             |
| --------------- | ------------------------------------------------------ |
| BusApiService   | `lib/shared/services/bus_api_service.dart`           |
| LineModel       | `lib/shared/services/line_models.dart`               |
| StopModel       | `lib/shared/services/line_models.dart`               |
| MapViewModel    | `lib/features/map/viewmodels/map_viewmodel.dart`     |
| HomeViewModel   | `lib/features/home/viewmodels/home_viewmodel.dart`   |
| LinesViewModel  | `lib/features/lines/viewmodels/lines_viewmodel.dart` |
| Backend BusMaps | `backend/almeria_busmaps_api.py` (puerto 5000)       |
| Backend Auth    | `backend/almeria_auth_api.py` (puerto 5001)          |
| Auth Module     | `backend/auth_mvc/`                                  |

## 1. Conexion entre App y API

### Backend

- API Flask local (por defecto): `http://localhost:5000`
- Endpoints principales:
  - `GET /lines`
  - `GET /lines/{id}/stops`

### App Flutter

- Punto central de conexion: `lib/shared/services/bus_api_service.dart`
- La app usa `http` para consumir la API y transformar JSON a modelos:
  - `LineModel`
  - `StopModel`

### Flujo base de datos

1. La vista pide datos al ViewModel.
2. El ViewModel llama a `BusApiService`.
3. `BusApiService` consulta endpoint y parsea JSON.
4. Se actualiza estado con `notifyListeners()`.
5. La UI se reconstruye con datos nuevos.

## 2. Que se optimizo globalmente

## 2.1 Capa API central

Archivo: `lib/shared/services/bus_api_service.dart`

Se aplicaron estas mejoras:

- Cache en memoria de lineas y paradas.
- Deduplicacion de requests en vuelo (`_inFlight...`):
  - Si dos pantallas piden lo mismo al mismo tiempo, se reutiliza la misma `Future`.
- Timeout de red para evitar esperas indefinidas.
- Retry corto para fallos transitorios de conexion.

Impacto:

- Menos tormenta de conexiones.
- Menos errores intermitentes tipo "Connection closed while receiving data".
- Menor latencia percibida en segundas aperturas.

## 2.2 Inicializacion del mapa (ciclo de vida)

Archivo: `lib/features/map/viewmodels/map_viewmodel.dart`

Se aplicaron guardas de ciclo de vida:

- No reinicializar todo el mapa cada vez que se entra.
- No volver a pedir GPS si ya existe `userLocation`.
- No relanzar `loadStops()` si ya hay datos o si ya esta cargando.

Impacto:

- Menos llamadas repetidas al backend.
- Menos reconstrucciones innecesarias.
- Entrada al mapa mas estable.

## 2.3 Carga de paradas mas eficiente

Archivo: `lib/features/map/viewmodels/map_viewmodel.dart`

Antes:

- Carga secuencial por linea (mas lenta).

Ahora:

- Carga batched en paralelo con `Future.wait(...)` para paradas por linea.
- Agregacion de paradas unicas con union de `lineIds`.

Impacto:

- Menor tiempo total de carga inicial de mapa.
- Menor sensacion de bloqueo al entrar.

## 2.4 Popup de parada en Lineas

Archivo: `lib/features/lines/views/lines_view.dart`

Mejora aplicada:

- El `Future` del popup se calcula una sola vez por apertura.
- Ya no se recomputa en cada rebuild del bottom sheet.

Impacto:

- Menos trabajo redundante de UI.
- Popup mas fluido y consistente.

## 2.5 Estado de lineas en Home y modulo Lineas

Archivos:

- `lib/features/home/viewmodels/home_viewmodel.dart`
- `lib/features/lines/viewmodels/lines_viewmodel.dart`

Mejora aplicada:

- Guardas para no recargar lineas si ya existen en memoria.
- `forceRefresh: true` solo en acciones explicitas de reintento.

Impacto:

- Se evita mostrar cargas innecesarias.
- Menos peticiones duplicadas a `GET /lines`.

## 3. Problemas reales que se mitigaron

- Multiples `GET /lines` seguidos por navegacion entre vistas.
- Error intermitente: `ClientException: Connection closed while receiving data`.
- Estado de filtros que se sobreescribia por cargas tardias.

## 4. Buenas practicas para mantener esta mejora

- Mantener `BusApiService` como unica puerta de acceso HTTP.
- No hacer llamadas HTTP directas desde vistas.
- Reusar cache y `inFlight` para recursos compartidos.
- Forzar refresh solo por accion de usuario (boton Reintentar/actualizar).
- Evitar `initialize()` repetidos sin guardas.

## 5. Checklist rapido de verificacion

- Home muestra lineas sin multiples `GET /lines` repetidos.
- Pantalla de Lineas no recarga en cada apertura inmediata.Mapa no vuelve a pedir todo si ya esta inicializado.
- Paradas se cargan en paralelo y aparecen con menor demora.
- Reintentar hace refresh explicito cuando se necesita.

---

Documento generado para dejar trazabilidad tecnica de la conexion API-app y la optimizacion aplicada en AlmeriaRuta.
