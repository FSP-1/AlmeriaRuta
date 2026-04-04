from flask import Flask, jsonify, request
from flask_cors import CORS
import json
from datetime import datetime
import os
import hashlib
import hmac
import secrets
import re
from functools import wraps
from itsdangerous import URLSafeTimedSerializer, BadSignature, SignatureExpired
import pymysql

app = Flask(__name__)
CORS(app)

app.config['SECRET_KEY'] = os.getenv('APP_SECRET_KEY', 'almeriaruta-dev-secret-change-me')
TOKEN_TTL_SECONDS = 60 * 60 * 24 * 7  # 7 dias


class AuthRepository:
    def __init__(self):
        self.host = os.getenv('MYSQL_HOST', '127.0.0.1')
        self.port = int(os.getenv('MYSQL_PORT', '3306'))
        self.user = os.getenv('MYSQL_USER', 'root')
        self.password = os.getenv('MYSQL_PASSWORD', 'root')
        self.database = os.getenv('MYSQL_DATABASE', 'db')

    def _conn(self):
        return pymysql.connect(
            host=self.host,
            port=self.port,
            user=self.user,
            password=self.password,
            database=self.database,
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=True,
        )

    def init_schema(self):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS users (
                        id BIGINT PRIMARY KEY AUTO_INCREMENT,
                        email VARCHAR(255) NOT NULL UNIQUE,
                        username VARCHAR(80) NOT NULL UNIQUE,
                        password_hash VARCHAR(255) NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                    """
                )
                cur.execute(
                    """
                    SELECT COUNT(*) AS idx_count
                    FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'users'
                      AND COLUMN_NAME = 'email'
                      AND NON_UNIQUE = 0
                    """
                )
                has_unique_email = cur.fetchone()['idx_count'] > 0
                if not has_unique_email:
                    cur.execute(
                        """
                        SELECT LOWER(TRIM(email)) AS value, COUNT(*) AS total
                        FROM users
                        GROUP BY LOWER(TRIM(email))
                        HAVING COUNT(*) > 1
                        LIMIT 1
                        """
                    )
                    duplicate_email = cur.fetchone()
                    if duplicate_email:
                        raise RuntimeError(
                            f"No se puede aplicar unicidad de email: hay duplicados ({duplicate_email['value']})"
                        )
                    cur.execute("ALTER TABLE users ADD UNIQUE INDEX uq_users_email (email)")

                cur.execute(
                    """
                    SELECT COUNT(*) AS idx_count
                    FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'users'
                      AND COLUMN_NAME = 'username'
                      AND NON_UNIQUE = 0
                    """
                )
                has_unique_username = cur.fetchone()['idx_count'] > 0
                if not has_unique_username:
                    cur.execute(
                        """
                        SELECT LOWER(TRIM(username)) AS value, COUNT(*) AS total
                        FROM users
                        GROUP BY LOWER(TRIM(username))
                        HAVING COUNT(*) > 1
                        LIMIT 1
                        """
                    )
                    duplicate_username = cur.fetchone()
                    if duplicate_username:
                        raise RuntimeError(
                            f"No se puede aplicar unicidad de username: hay duplicados ({duplicate_username['value']})"
                        )
                    cur.execute("ALTER TABLE users ADD UNIQUE INDEX uq_users_username (username)")

                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS app_notifications (
                        id BIGINT PRIMARY KEY AUTO_INCREMENT,
                        user_id BIGINT NOT NULL,
                        title VARCHAR(180) NOT NULL,
                        body VARCHAR(500) NOT NULL,
                        payload_json LONGTEXT NULL,
                        is_read TINYINT(1) DEFAULT 0,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        INDEX idx_notifications_user (user_id),
                        CONSTRAINT fk_notifications_user FOREIGN KEY (user_id) REFERENCES users(id)
                            ON DELETE CASCADE
                    )
                    """
                )
                cur.execute(
                    """
                    SELECT COUNT(*) AS column_count
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'app_notifications'
                      AND COLUMN_NAME = 'payload_json'
                    """
                )
                column_exists = cur.fetchone()['column_count'] > 0
                if not column_exists:
                    cur.execute("ALTER TABLE app_notifications ADD COLUMN payload_json LONGTEXT NULL")

    def create_user(self, email, username, password_hash):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO users (email, username, password_hash) VALUES (%s, %s, %s)",
                    (email, username, password_hash),
                )
                return cur.lastrowid

    def find_user_by_email_or_username(self, value):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, email, username, password_hash "
                    "FROM users "
                    "WHERE LOWER(email)=LOWER(%s) OR LOWER(username)=LOWER(%s) "
                    "LIMIT 1",
                    (value, value),
                )
                return cur.fetchone()

    def find_user_by_id(self, user_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, email, username, created_at FROM users WHERE id=%s LIMIT 1",
                    (user_id,),
                )
                return cur.fetchone()

    def create_notification(self, user_id, title, body, payload_json=None):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO app_notifications (user_id, title, body, payload_json) VALUES (%s, %s, %s, %s)",
                    (user_id, title, body, payload_json),
                )
                return cur.lastrowid

    def list_notifications(self, user_id, unread_only=False, limit=50):
        with self._conn() as conn:
            with conn.cursor() as cur:
                sql = (
                    "SELECT id, title, body, payload_json, is_read, created_at "
                    "FROM app_notifications WHERE user_id=%s"
                )
                params = [user_id]
                if unread_only:
                    sql += " AND is_read=0"
                sql += " ORDER BY created_at DESC, id DESC LIMIT %s"
                params.append(limit)
                cur.execute(sql, params)
                return cur.fetchall()

    def mark_notification_read(self, user_id, notification_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE app_notifications SET is_read=1 WHERE id=%s AND user_id=%s",
                    (notification_id, user_id),
                )
                return cur.rowcount

    def find_notification(self, user_id, notification_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, is_read FROM app_notifications WHERE id=%s AND user_id=%s LIMIT 1",
                    (notification_id, user_id),
                )
                return cur.fetchone()

    def delete_notification(self, user_id, notification_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "DELETE FROM app_notifications WHERE id=%s AND user_id=%s",
                    (notification_id, user_id),
                )
                return cur.rowcount


auth_repo = AuthRepository()
token_serializer = URLSafeTimedSerializer(app.config['SECRET_KEY'])


def _hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100_000)
    return f"{salt}${digest.hex()}"


def _verify_password(password: str, encoded: str) -> bool:
    try:
        salt, hex_digest = encoded.split('$', 1)
    except ValueError:
        return False
    digest = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100_000).hex()
    return hmac.compare_digest(digest, hex_digest)


def _issue_token(payload: dict) -> str:
    return token_serializer.dumps(payload)


def _parse_token(token: str):
    return token_serializer.loads(token, max_age=TOKEN_TTL_SECONDS)


def _extract_bearer_token():
    auth_header = request.headers.get('Authorization', '')
    if not auth_header.startswith('Bearer '):
        return None
    return auth_header.replace('Bearer ', '', 1).strip()


def _is_valid_email(email: str) -> bool:
    return bool(re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email))


def _is_valid_username(username: str) -> bool:
    return bool(re.match(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9_ ]{3,20}$', username))


def _is_strong_password(password: str) -> bool:
    if len(password) < 8:
        return False
    has_letter = re.search(r'[A-Za-z]', password)
    has_number = re.search(r'[0-9]', password)
    return bool(has_letter and has_number)


def auth_required(allow_guest=False):
    def decorator(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            token = _extract_bearer_token()
            if not token:
                return jsonify({'error': 'Token requerido'}), 401
            try:
                data = _parse_token(token)
            except SignatureExpired:
                return jsonify({'error': 'Token expirado'}), 401
            except BadSignature:
                return jsonify({'error': 'Token invalido'}), 401

            if data.get('guest') and not allow_guest:
                return jsonify({'error': 'Acceso solo para usuarios registrados'}), 403

            request.auth = data
            return fn(*args, **kwargs)

        return wrapper

    return decorator


@app.route('/auth/register', methods=['POST'])
def auth_register():
    try:
        body = request.get_json(silent=True) or {}
        email = str(body.get('email', '')).strip().lower()
        username = str(body.get('username', '')).strip()
        normalized_username = username.lower()
        password = str(body.get('password', ''))

        if not _is_valid_email(email):
            return jsonify({'error': 'Email no válido'}), 400

        if not _is_valid_username(username):
            return jsonify({'error': 'Usuario inválido: usa 3 a 20 letras, números, espacios o guiones bajos'}), 400

        if not _is_strong_password(password):
            return jsonify({'error': 'Contraseña inválida: mínimo 8 caracteres y debe incluir letras y números'}), 400

        exists = auth_repo.find_user_by_email_or_username(email) or auth_repo.find_user_by_email_or_username(normalized_username)
        if exists:
            return jsonify({'error': 'Usuario ya existe'}), 409

        user_id = auth_repo.create_user(email, normalized_username, _hash_password(password))
        token = _issue_token({'uid': user_id, 'email': email, 'username': normalized_username, 'guest': False})
        return jsonify({
            'token': token,
            'user': {'id': user_id, 'email': email, 'username': normalized_username, 'guest': False},
        })
    except pymysql.err.IntegrityError:
        return jsonify({'error': 'Usuario ya existe (email o username en uso)'}), 409
    except Exception as e:
        return jsonify({'error': f'No se pudo registrar: {e}'}), 500


@app.route('/auth/login', methods=['POST'])
def auth_login():
    try:
        body = request.get_json(silent=True) or {}
        identifier = str(body.get('identifier', '')).strip()
        password = str(body.get('password', ''))
        if not identifier or not password:
            return jsonify({'error': 'Credenciales requeridas'}), 400

        user = auth_repo.find_user_by_email_or_username(identifier)
        if not user or not _verify_password(password, user['password_hash']):
            return jsonify({'error': 'Credenciales incorrectas'}), 401

        token = _issue_token({
            'uid': user['id'],
            'email': user['email'],
            'username': user['username'],
            'guest': False,
        })
        return jsonify({
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'username': user['username'],
                'guest': False,
            },
        })
    except Exception as e:
        return jsonify({'error': f'No se pudo iniciar sesion: {e}'}), 500


@app.route('/auth/guest', methods=['POST'])
def auth_guest():
    guest_name = f"Invitado-{secrets.token_hex(3)}"
    token = _issue_token({'uid': None, 'email': None, 'username': guest_name, 'guest': True})
    return jsonify({
        'token': token,
        'user': {'id': None, 'email': None, 'username': guest_name, 'guest': True},
    })


@app.route('/auth/me', methods=['GET'])
@auth_required(allow_guest=True)
def auth_me():
    data = request.auth
    if data.get('guest'):
        return jsonify({'id': None, 'email': None, 'username': data.get('username'), 'guest': True})

    user = auth_repo.find_user_by_id(data.get('uid'))
    if not user:
        return jsonify({'error': 'Usuario no encontrado'}), 404
    return jsonify({'id': user['id'], 'email': user['email'], 'username': user['username'], 'guest': False})


@app.route('/auth/tickets/purchase', methods=['POST'])
@auth_required(allow_guest=False)
def auth_purchase_ticket():
    try:
        body = request.get_json(silent=True) or {}
        sender_id = request.auth.get('uid')
        sender_username = request.auth.get('username') or 'Usuario'
        recipient_identifier = str(body.get('recipientIdentifier', '')).strip()
        validate_only = str(body.get('validateOnly', 'false')).lower() in {'1', 'true', 'yes'}
        ticket_type = str(body.get('type', 'Individual')).strip() or 'Individual'
        payment_method = str(body.get('paymentMethod', 'Google Pay')).strip() or 'Google Pay'
        quantity = int(body.get('quantity', 1) or 1)
        amount = float(body.get('amount', 0) or 0)

        if quantity < 1:
            return jsonify({'error': 'Cantidad inválida'}), 400

        recipient = None
        if recipient_identifier:
            recipient = auth_repo.find_user_by_email_or_username(recipient_identifier)
            if not recipient:
                return jsonify({'error': 'Usuario destinatario no encontrado'}), 404

        if validate_only:
            if not recipient_identifier:
                return jsonify({'error': 'Destinatario requerido'}), 400
            return jsonify({
                'success': True,
                'validateOnly': True,
                'recipient': {
                    'id': recipient['id'],
                    'email': recipient['email'],
                    'username': recipient['username'],
                },
            })

        notification = None
        if recipient and recipient['id'] != sender_id:
            title = 'Nuevo ticket recibido'
            ticket_id = f"TK-{secrets.token_hex(5).upper()}"
            body_text = (
                f"{sender_username} te ha comprado {quantity} ticket{'s' if quantity != 1 else ''} {ticket_type}."
            )
            payload = {
                'ticket': {
                    'id': ticket_id,
                    'type': ticket_type,
                    'quantity': quantity,
                    'remainingUses': quantity,
                    'purchaseDate': datetime.now().isoformat(),
                    'amount': amount,
                    'status': 'Activo',
                },
                'sourceUser': {
                    'id': sender_id,
                    'username': sender_username,
                },
            }
            notification_id = auth_repo.create_notification(
                recipient['id'],
                title,
                body_text,
                json.dumps(payload, ensure_ascii=False),
            )
            notification = {
                'id': notification_id,
                'userId': recipient['id'],
                'title': title,
                'body': body_text,
                'payloadJson': payload,
            }

        return jsonify({
            'success': True,
            'ticket': {
                'type': ticket_type,
                'quantity': quantity,
                'amount': amount,
                'paymentMethod': payment_method,
                'recipientIdentifier': recipient_identifier or None,
            },
            'notification': notification,
        })
    except ValueError:
        return jsonify({'error': 'Datos de compra inválidos'}), 400
    except Exception as e:
        return jsonify({'error': f'No se pudo registrar la compra: {e}'}), 500


@app.route('/auth/notifications', methods=['GET'])
@auth_required(allow_guest=False)
def auth_notifications():
    try:
        unread_only = str(request.args.get('unreadOnly', 'false')).lower() in {'1', 'true', 'yes'}
        notifications = auth_repo.list_notifications(request.auth.get('uid'), unread_only=unread_only)
        for notification in notifications:
            raw_payload = notification.pop('payload_json', None)
            if raw_payload:
                try:
                    notification['payloadJson'] = json.loads(raw_payload)
                except Exception:
                    notification['payloadJson'] = None
            else:
                notification['payloadJson'] = None
        return jsonify({'notifications': notifications})
    except Exception as e:
        return jsonify({'error': f'No se pudieron cargar las notificaciones: {e}'}), 500


@app.route('/auth/notifications/<int:notification_id>/read', methods=['POST'])
@auth_required(allow_guest=False)
def auth_mark_notification_read(notification_id):
    try:
        user_id = request.auth.get('uid')
        updated = auth_repo.mark_notification_read(user_id, notification_id)
        if updated == 0:
            existing = auth_repo.find_notification(user_id, notification_id)
            if not existing:
                return jsonify({'error': 'Notificación no encontrada'}), 404
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': f'No se pudo actualizar la notificación: {e}'}), 500


@app.route('/auth/notifications/<int:notification_id>', methods=['DELETE'])
@auth_required(allow_guest=False)
def auth_delete_notification(notification_id):
    try:
        deleted = auth_repo.delete_notification(request.auth.get('uid'), notification_id)
        if deleted == 0:
            return jsonify({'error': 'Notificación no encontrada'}), 404
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'error': f'No se pudo eliminar la notificación: {e}'}), 500


if __name__ == '__main__':
    print('Iniciando API de autenticacion (MySQL) en puerto 5001...')
    auth_repo.init_schema()
    app.run(debug=True, host='0.0.0.0', port=5001)
