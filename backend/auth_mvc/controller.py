from functools import wraps

import pymysql
from flask import Blueprint, jsonify, request
from itsdangerous import BadSignature, SignatureExpired


def create_auth_blueprint(auth_service):
    auth_bp = Blueprint('auth', __name__)

    def _extract_bearer_token():
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return None
        return auth_header.replace('Bearer ', '', 1).strip()

    def auth_required(allow_guest=False):
        def decorator(fn):
            @wraps(fn)
            def wrapper(*args, **kwargs):
                token = _extract_bearer_token()
                if not token:
                    return jsonify({'error': 'Token requerido'}), 401
                try:
                    data = auth_service.parse_token(token)
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

    @auth_bp.route('/auth/register', methods=['POST'])
    def auth_register():
        try:
            body = request.get_json(silent=True) or {}
            email = str(body.get('email', '')).strip().lower()
            username = str(body.get('username', '')).strip()
            password = str(body.get('password', ''))

            payload, status = auth_service.register(email=email, username=username, password=password)
            return jsonify(payload), status
        except pymysql.err.IntegrityError:
            return jsonify({'error': 'Usuario ya existe (email o username en uso)'}), 409
        except Exception as e:
            return jsonify({'error': f'No se pudo registrar: {e}'}), 500

    @auth_bp.route('/auth/login', methods=['POST'])
    def auth_login():
        try:
            body = request.get_json(silent=True) or {}
            identifier = str(body.get('identifier', '')).strip()
            password = str(body.get('password', ''))

            payload, status = auth_service.login(identifier=identifier, password=password)
            return jsonify(payload), status
        except Exception as e:
            return jsonify({'error': f'No se pudo iniciar sesion: {e}'}), 500

    @auth_bp.route('/auth/guest', methods=['POST'])
    def auth_guest():
        payload, status = auth_service.guest()
        return jsonify(payload), status

    @auth_bp.route('/auth/me', methods=['GET'])
    @auth_required(allow_guest=True)
    def auth_me():
        payload, status = auth_service.me(request.auth)
        return jsonify(payload), status

    @auth_bp.route('/auth/me', methods=['PATCH'])
    @auth_required(allow_guest=False)
    def auth_update_me():
        try:
            body = request.get_json(silent=True) or {}
            payload, status = auth_service.update_profile(request.auth, body)
            return jsonify(payload), status
        except pymysql.err.IntegrityError as e:
            raw = str(e).lower()
            if 'email' in raw:
                return jsonify({'error': 'El email ya está en uso'}), 409
            if 'username' in raw:
                return jsonify({'error': 'El nombre de usuario ya está en uso'}), 409
            return jsonify({'error': 'Email o nombre de usuario ya en uso'}), 409
        except Exception as e:
            return jsonify({'error': f'No se pudo actualizar el perfil: {e}'}), 500

    @auth_bp.route('/auth/me/password', methods=['POST'])
    @auth_required(allow_guest=False)
    def auth_change_password():
        try:
            body = request.get_json(silent=True) or {}
            payload, status = auth_service.change_password(request.auth, body)
            return jsonify(payload), status
        except Exception as e:
            return jsonify({'error': f'No se pudo cambiar la contraseña: {e}'}), 500

    @auth_bp.route('/auth/tickets/purchase', methods=['POST'])
    @auth_required(allow_guest=False)
    def auth_purchase_ticket():
        try:
            body = request.get_json(silent=True) or {}
            payload, status = auth_service.purchase_ticket(request.auth, body)
            return jsonify(payload), status
        except ValueError:
            return jsonify({'error': 'Datos de compra inválidos'}), 400
        except Exception as e:
            return jsonify({'error': f'No se pudo registrar la compra: {e}'}), 500

    @auth_bp.route('/auth/notifications', methods=['GET'])
    @auth_required(allow_guest=False)
    def auth_notifications():
        try:
            unread_only = str(request.args.get('unreadOnly', 'false')).lower() in {'1', 'true', 'yes'}
            payload, status = auth_service.list_notifications(request.auth.get('uid'), unread_only=unread_only)
            return jsonify(payload), status
        except Exception as e:
            return jsonify({'error': f'No se pudieron cargar las notificaciones: {e}'}), 500

    @auth_bp.route('/auth/notifications/<int:notification_id>/read', methods=['POST'])
    @auth_required(allow_guest=False)
    def auth_mark_notification_read(notification_id):
        try:
            payload, status = auth_service.mark_notification_read(request.auth.get('uid'), notification_id)
            return jsonify(payload), status
        except Exception as e:
            return jsonify({'error': f'No se pudo actualizar la notificación: {e}'}), 500

    @auth_bp.route('/auth/notifications/<int:notification_id>', methods=['DELETE'])
    @auth_required(allow_guest=False)
    def auth_delete_notification(notification_id):
        try:
            payload, status = auth_service.delete_notification(request.auth.get('uid'), notification_id)
            return jsonify(payload), status
        except Exception as e:
            return jsonify({'error': f'No se pudo eliminar la notificación: {e}'}), 500

    return auth_bp
