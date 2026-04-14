import hashlib
import hmac
import json
import re
import secrets
from datetime import datetime

from itsdangerous import URLSafeTimedSerializer


class AuthService:
    def __init__(self, repository, secret_key: str, token_ttl_seconds: int):
        self.repo = repository
        self.token_ttl_seconds = token_ttl_seconds
        self._token_serializer = URLSafeTimedSerializer(secret_key)

    def hash_password(self, password: str) -> str:
        salt = secrets.token_hex(16)
        digest = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100_000)
        return f"{salt}${digest.hex()}"

    def verify_password(self, password: str, encoded: str) -> bool:
        try:
            salt, hex_digest = encoded.split('$', 1)
        except ValueError:
            return False
        digest = hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt.encode('utf-8'), 100_000).hex()
        return hmac.compare_digest(digest, hex_digest)

    def issue_token(self, payload: dict) -> str:
        return self._token_serializer.dumps(payload)

    def parse_token(self, token: str):
        return self._token_serializer.loads(token, max_age=self.token_ttl_seconds)

    @staticmethod
    def is_valid_email(email: str) -> bool:
        return bool(re.match(r'^[^\s@]+@[^\s@]+\.[^\s@]+$', email))

    @staticmethod
    def is_valid_username(username: str) -> bool:
        return bool(re.match(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ0-9_ ]{3,20}$', username))

    @staticmethod
    def is_strong_password(password: str) -> bool:
        if len(password) < 8:
            return False
        has_letter = re.search(r'[A-Za-z]', password)
        has_number = re.search(r'[0-9]', password)
        return bool(has_letter and has_number)

    @staticmethod
    def _default_transport_profile() -> dict:
        return {
            'cardKey': 'mensual_ordinaria',
            'cardLabel': 'Mensual Ordinaria',
            'rechargeMode': 'mensual',
            'ageGroup': 'general',
            'travelCount': None,
            'paymentMethod': 'Saldo',
            'saldoBalance': 0.0,
            'hasSaldoCard': False,
            'cardState': 'active',
            'configured': False,
        }

    def register(self, email: str, username: str, password: str):
        normalized_username = username.lower()

        if not self.is_valid_email(email):
            return {'error': 'Email no válido'}, 400

        if not self.is_valid_username(username):
            return {'error': 'Usuario inválido: usa 3 a 20 letras, números, espacios o guiones bajos'}, 400

        if not self.is_strong_password(password):
            return {'error': 'Contraseña inválida: mínimo 8 caracteres y debe incluir letras y números'}, 400

        exists = self.repo.find_user_by_email_or_username(email) or self.repo.find_user_by_email_or_username(normalized_username)
        if exists:
            return {'error': 'Usuario ya existe'}, 409

        user_id = self.repo.create_user(email, normalized_username, self.hash_password(password))
        token = self.issue_token({'uid': user_id, 'email': email, 'username': normalized_username, 'guest': False})

        return {
            'token': token,
            'user': {'id': user_id, 'email': email, 'username': normalized_username, 'guest': False},
        }, 200

    def login(self, identifier: str, password: str):
        if not identifier or not password:
            return {'error': 'Credenciales requeridas'}, 400

        user = self.repo.find_user_by_email_or_username(identifier)
        if not user or not self.verify_password(password, user['password_hash']):
            return {'error': 'Credenciales incorrectas'}, 401

        token = self.issue_token({
            'uid': user['id'],
            'email': user['email'],
            'username': user['username'],
            'guest': False,
        })

        return {
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'username': user['username'],
                'guest': False,
            },
        }, 200

    def guest(self):
        guest_name = f"Invitado-{secrets.token_hex(3)}"
        token = self.issue_token({'uid': None, 'email': None, 'username': guest_name, 'guest': True})
        return {
            'token': token,
            'user': {'id': None, 'email': None, 'username': guest_name, 'guest': True},
        }, 200

    def me(self, auth_data: dict):
        if auth_data.get('guest'):
            return {'id': None, 'email': None, 'username': auth_data.get('username'), 'guest': True}, 200

        user = self.repo.find_user_by_id(auth_data.get('uid'))
        if not user:
            return {'error': 'Usuario no encontrado'}, 404

        return {'id': user['id'], 'email': user['email'], 'username': user['username'], 'guest': False}, 200

    def update_profile(self, auth_data: dict, body: dict):
        user_id = auth_data.get('uid')
        if not user_id:
            return {'error': 'Usuario no autenticado'}, 401

        email = str(body.get('email', '')).strip().lower()
        username = str(body.get('username', '')).strip().lower()

        if not self.is_valid_email(email):
            return {'error': 'Email no válido'}, 400

        if not self.is_valid_username(username):
            return {'error': 'Usuario inválido: usa 3 a 20 letras, números, espacios o guiones bajos'}, 400

        if self.repo.email_exists_for_other_user(email, user_id):
            return {'error': 'El email ya está en uso'}, 409

        if self.repo.username_exists_for_other_user(username, user_id):
            return {'error': 'El nombre de usuario ya está en uso'}, 409

        self.repo.update_user_profile(user_id, email, username)
        updated_user = self.repo.find_user_by_id(user_id)
        if not updated_user:
            return {'error': 'Usuario no encontrado'}, 404

        token = self.issue_token(
            {
                'uid': updated_user['id'],
                'email': updated_user['email'],
                'username': updated_user['username'],
                'guest': False,
            }
        )

        return {
            'token': token,
            'user': {
                'id': updated_user['id'],
                'email': updated_user['email'],
                'username': updated_user['username'],
                'guest': False,
            },
        }, 200

    def change_password(self, auth_data: dict, body: dict):
        user_id = auth_data.get('uid')
        if not user_id:
            return {'error': 'Usuario no autenticado'}, 401

        current_password = str(body.get('currentPassword', ''))
        new_password = str(body.get('newPassword', ''))

        if not current_password or not new_password:
            return {'error': 'Contraseña actual y nueva requeridas'}, 400

        if not self.is_strong_password(new_password):
            return {'error': 'Contraseña inválida: mínimo 8 caracteres y debe incluir letras y números'}, 400

        user = self.repo.find_user_by_id(user_id)
        if not user:
            return {'error': 'Usuario no encontrado'}, 404

        if not self.verify_password(current_password, user['password_hash']):
            return {'error': 'Contraseña actual incorrecta'}, 401

        if self.verify_password(new_password, user['password_hash']):
            return {'error': 'La nueva contraseña debe ser distinta a la actual'}, 400

        self.repo.update_user_password(user_id, self.hash_password(new_password))
        return {'success': True}, 200

    def purchase_ticket(self, auth_data: dict, body: dict):
        sender_id = auth_data.get('uid')
        sender_username = auth_data.get('username') or 'Usuario'
        recipient_identifier = str(body.get('recipientIdentifier', '')).strip()
        validate_only = str(body.get('validateOnly', 'false')).lower() in {'1', 'true', 'yes'}
        ticket_type = str(body.get('type', 'Individual')).strip() or 'Individual'
        payment_method = str(body.get('paymentMethod', 'Google Pay')).strip() or 'Google Pay'
        quantity = int(body.get('quantity', 1) or 1)
        amount = float(body.get('amount', 0) or 0)

        if quantity < 1:
            return {'error': 'Cantidad inválida'}, 400

        recipient = None
        if recipient_identifier:
            recipient = self.repo.find_user_by_email_or_username(recipient_identifier)
            if not recipient:
                return {'error': 'Usuario destinatario no encontrado'}, 404

        if validate_only:
            if not recipient_identifier:
                return {'error': 'Destinatario requerido'}, 400
            return {
                'success': True,
                'validateOnly': True,
                'recipient': {
                    'id': recipient['id'],
                    'email': recipient['email'],
                    'username': recipient['username'],
                },
            }, 200

        notification = None
        if recipient and recipient['id'] != sender_id:
            title = 'Nuevo ticket recibido'
            ticket_id = f"TK-{secrets.token_hex(5).upper()}"
            body_text = f"{sender_username} te ha comprado {quantity} ticket{'s' if quantity != 1 else ''} {ticket_type}."
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
            notification_id = self.repo.create_notification(
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

        return {
            'success': True,
            'ticket': {
                'type': ticket_type,
                'quantity': quantity,
                'amount': amount,
                'paymentMethod': payment_method,
                'recipientIdentifier': recipient_identifier or None,
            },
            'notification': notification,
        }, 200

    def list_notifications(self, user_id: int, unread_only: bool):
        notifications = self.repo.list_notifications(user_id, unread_only=unread_only)
        for notification in notifications:
            raw_payload = notification.pop('payload_json', None)
            if raw_payload:
                try:
                    notification['payloadJson'] = json.loads(raw_payload)
                except Exception:
                    notification['payloadJson'] = None
            else:
                notification['payloadJson'] = None
        return {'notifications': notifications}, 200

    def mark_notification_read(self, user_id: int, notification_id: int):
        updated = self.repo.mark_notification_read(user_id, notification_id)
        if updated == 0:
            existing = self.repo.find_notification(user_id, notification_id)
            if not existing:
                return {'error': 'Notificación no encontrada'}, 404
        return {'success': True}, 200

    def delete_notification(self, user_id: int, notification_id: int):
        deleted = self.repo.delete_notification(user_id, notification_id)
        if deleted == 0:
            return {'error': 'Notificación no encontrada'}, 404
        return {'success': True}, 200

    def get_transport_profile(self, auth_data: dict):
        user_id = auth_data.get('uid')
        if not user_id:
            return {'error': 'Usuario no autenticado'}, 401

        profile = self.repo.get_transport_profile(user_id)
        if not profile:
            return {'profile': self._default_transport_profile()}, 200

        return {
            'profile': {
                'cardKey': profile['card_key'],
                'cardLabel': profile['card_label'],
                'rechargeMode': profile['recharge_mode'],
                'ageGroup': profile['age_group'],
                'travelCount': profile['travel_count'],
                'paymentMethod': profile['payment_method'],
                'saldoBalance': float(profile.get('saldo_balance') or 0),
                'hasSaldoCard': bool(profile.get('has_saldo_card') or 0),
                'cardState': profile['card_state'],
                'configured': True,
            }
        }, 200

    def update_transport_profile(self, auth_data: dict, body: dict):
        user_id = auth_data.get('uid')
        if not user_id:
            return {'error': 'Usuario no autenticado'}, 401

        card_key = str(body.get('cardKey', '')).strip().lower()
        card_label = str(body.get('cardLabel', '')).strip()
        recharge_mode = str(body.get('rechargeMode', '')).strip().lower()
        age_group_raw = body.get('ageGroup')
        age_group = str(age_group_raw).strip().lower() if age_group_raw is not None else None
        travel_count_raw = body.get('travelCount')
        payment_method = str(body.get('paymentMethod', '')).strip()
        saldo_balance_raw = body.get('saldoBalance', 0)
        has_saldo_card = bool(body.get('hasSaldoCard', card_key == 'saldo_virtual'))
        card_state = str(body.get('cardState', 'active')).strip().lower() or 'active'

        if not card_key or not card_label:
            return {'error': 'cardKey y cardLabel son obligatorios'}, 400

        allowed_modes = {'saldo', 'mensual', 'bonobus', 'gratis'}
        if recharge_mode not in allowed_modes:
            return {'error': 'rechargeMode no válido'}, 400

        allowed_payments = {'Saldo', 'Android Pay', 'Visa'}
        if payment_method and payment_method not in allowed_payments:
            return {'error': 'paymentMethod no válido'}, 400

        allowed_states = {'active', 'paused', 'expired'}
        if card_state not in allowed_states:
            return {'error': 'cardState no válido'}, 400

        travel_count = None
        if travel_count_raw is not None and str(travel_count_raw).strip() != '':
            try:
                travel_count = int(travel_count_raw)
            except (ValueError, TypeError):
                return {'error': 'travelCount debe ser numérico'}, 400
            if travel_count < 0:
                return {'error': 'travelCount no puede ser negativo'}, 400

        try:
            saldo_balance = float(saldo_balance_raw or 0)
        except (ValueError, TypeError):
            return {'error': 'saldoBalance debe ser numérico'}, 400

        if saldo_balance < 0:
            return {'error': 'saldoBalance no puede ser negativo'}, 400

        self.repo.upsert_transport_profile(
            user_id=user_id,
            card_key=card_key,
            card_label=card_label,
            recharge_mode=recharge_mode,
            age_group=age_group,
            travel_count=travel_count,
            payment_method=payment_method or None,
            saldo_balance=saldo_balance,
            has_saldo_card=has_saldo_card,
            card_state=card_state,
        )

        return self.get_transport_profile(auth_data)
