import os

import pymysql


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
                        recovery_pin_hash VARCHAR(255) NULL,
                        is_operario TINYINT(1) DEFAULT 0,
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
                    SELECT COUNT(*) AS column_count
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'users'
                      AND COLUMN_NAME = 'recovery_pin_hash'
                    """
                )
                has_recovery_pin_hash = cur.fetchone()['column_count'] > 0
                if not has_recovery_pin_hash:
                    cur.execute("ALTER TABLE users ADD COLUMN recovery_pin_hash VARCHAR(255) NULL")

                cur.execute(
                    """
                    SELECT COUNT(*) AS column_count
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'users'
                      AND COLUMN_NAME = 'is_operario'
                    """
                )
                has_is_operario = cur.fetchone()['column_count'] > 0
                if not has_is_operario:
                    cur.execute("ALTER TABLE users ADD COLUMN is_operario TINYINT(1) DEFAULT 0")

                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS notices (
                        id BIGINT PRIMARY KEY AUTO_INCREMENT,
                        title VARCHAR(100) NOT NULL,
                        message TEXT NOT NULL,
                        type VARCHAR(50) NOT NULL,
                        related_id VARCHAR(50) NULL,
                        is_active TINYINT(1) DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        INDEX idx_notices_active (is_active),
                        INDEX idx_notices_type (type)
                    )
                    """
                )

                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS disabled_stops (
                        id BIGINT PRIMARY KEY AUTO_INCREMENT,
                        stop_id VARCHAR(100) NOT NULL,
                        stop_name VARCHAR(255) NOT NULL,
                        reason TEXT NULL,
                        disabled_by BIGINT NOT NULL,
                        is_active TINYINT(1) DEFAULT 1,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        UNIQUE KEY uq_disabled_stops_stop_id (stop_id),
                        INDEX idx_disabled_stops_active (is_active),
                        CONSTRAINT fk_disabled_stops_user FOREIGN KEY (disabled_by) REFERENCES users(id)
                            ON DELETE CASCADE
                    )
                    """
                )

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

                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS user_transport_profile (
                        id BIGINT PRIMARY KEY AUTO_INCREMENT,
                        user_id BIGINT NOT NULL,
                        card_key VARCHAR(60) NOT NULL,
                        card_label VARCHAR(120) NOT NULL,
                        recharge_mode VARCHAR(30) NOT NULL,
                        age_group VARCHAR(30) NULL,
                        travel_count INT NULL,
                        payment_method VARCHAR(40) NULL,
                        saldo_balance DECIMAL(10,2) NOT NULL DEFAULT 0.00,
                        has_saldo_card TINYINT(1) NOT NULL DEFAULT 0,
                        card_state VARCHAR(20) NOT NULL DEFAULT 'active',
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        UNIQUE KEY uq_transport_profile_user (user_id),
                        CONSTRAINT fk_transport_profile_user FOREIGN KEY (user_id) REFERENCES users(id)
                            ON DELETE CASCADE
                    )
                    """
                )

                cur.execute(
                    """
                    SELECT COUNT(*) AS idx_count
                    FROM information_schema.STATISTICS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'user_transport_profile'
                      AND INDEX_NAME = 'uq_transport_profile_user'
                    """
                )
                has_unique_user = cur.fetchone()['idx_count'] > 0
                if not has_unique_user:
                    cur.execute(
                        "ALTER TABLE user_transport_profile ADD UNIQUE INDEX uq_transport_profile_user (user_id)"
                    )

                cur.execute(
                    """
                    SELECT COUNT(*) AS column_count
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'user_transport_profile'
                      AND COLUMN_NAME = 'saldo_balance'
                    """
                )
                has_saldo_balance = cur.fetchone()['column_count'] > 0
                if not has_saldo_balance:
                    cur.execute("ALTER TABLE user_transport_profile ADD COLUMN saldo_balance DECIMAL(10,2) NOT NULL DEFAULT 0.00")

                cur.execute(
                    """
                    SELECT COUNT(*) AS column_count
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'user_transport_profile'
                      AND COLUMN_NAME = 'has_saldo_card'
                    """
                )
                has_saldo_card = cur.fetchone()['column_count'] > 0
                if not has_saldo_card:
                    cur.execute("ALTER TABLE user_transport_profile ADD COLUMN has_saldo_card TINYINT(1) NOT NULL DEFAULT 0")

                cur.execute(
                    """
                    CREATE TABLE IF NOT EXISTS card_requests (
                        id BIGINT PRIMARY KEY AUTO_INCREMENT,
                        user_id BIGINT NOT NULL,
                        card_id VARCHAR(120) NOT NULL,
                        payload_json LONGTEXT NOT NULL,
                        status VARCHAR(20) NOT NULL DEFAULT 'pending',
                        decision_reason VARCHAR(255) NULL,
                        reviewed_by BIGINT NULL,
                        reviewed_at TIMESTAMP NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                        INDEX idx_card_requests_user (user_id),
                        INDEX idx_card_requests_status (status),
                        CONSTRAINT fk_card_requests_user FOREIGN KEY (user_id) REFERENCES users(id)
                            ON DELETE CASCADE
                    )
                    """
                )

                cur.execute(
                    """
                    SELECT COUNT(*) AS column_count
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'card_requests'
                      AND COLUMN_NAME = 'decision_reason'
                    """
                )
                has_decision_reason = cur.fetchone()['column_count'] > 0
                if not has_decision_reason:
                    cur.execute("ALTER TABLE card_requests ADD COLUMN decision_reason VARCHAR(255) NULL")

                cur.execute(
                    """
                    SELECT COUNT(*) AS column_count
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'card_requests'
                      AND COLUMN_NAME = 'reviewed_by'
                    """
                )
                has_reviewed_by = cur.fetchone()['column_count'] > 0
                if not has_reviewed_by:
                    cur.execute("ALTER TABLE card_requests ADD COLUMN reviewed_by BIGINT NULL")

                cur.execute(
                    """
                    SELECT COUNT(*) AS column_count
                    FROM information_schema.COLUMNS
                    WHERE TABLE_SCHEMA = DATABASE()
                      AND TABLE_NAME = 'card_requests'
                      AND COLUMN_NAME = 'reviewed_at'
                    """
                )
                has_reviewed_at = cur.fetchone()['column_count'] > 0
                if not has_reviewed_at:
                    cur.execute("ALTER TABLE card_requests ADD COLUMN reviewed_at TIMESTAMP NULL")

    def create_user(self, email, username, password_hash, recovery_pin_hash=None):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO users (email, username, password_hash, recovery_pin_hash) VALUES (%s, %s, %s, %s)",
                    (email, username, password_hash, recovery_pin_hash),
                )
                return cur.lastrowid

    def find_user_by_email_or_username(self, value):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, email, username, password_hash, is_operario "
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
                    "SELECT id, email, username, password_hash, is_operario, created_at FROM users WHERE id=%s LIMIT 1",
                    (user_id,),
                )
                return cur.fetchone()

    def find_user_by_email_or_username_except_id(self, value, user_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, email, username "
                    "FROM users "
                    "WHERE (LOWER(email)=LOWER(%s) OR LOWER(username)=LOWER(%s)) "
                    "AND id<>%s "
                    "LIMIT 1",
                    (value, value, user_id),
                )
                return cur.fetchone()

    def email_exists_for_other_user(self, email, user_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id FROM users WHERE LOWER(email)=LOWER(%s) AND id<>%s LIMIT 1",
                    (email, user_id),
                )
                return cur.fetchone() is not None

    def username_exists_for_other_user(self, username, user_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id FROM users WHERE LOWER(username)=LOWER(%s) AND id<>%s LIMIT 1",
                    (username, user_id),
                )
                return cur.fetchone() is not None

    def update_user_profile(self, user_id, email, username):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE users SET email=%s, username=%s WHERE id=%s",
                    (email, username, user_id),
                )
                return cur.rowcount

    def update_user_password(self, user_id, new_password_hash):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE users SET password_hash=%s WHERE id=%s",
                    (new_password_hash, user_id),
                )
                return cur.rowcount

    def update_user_recovery_pin(self, user_id, recovery_pin_hash):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE users SET recovery_pin_hash=%s WHERE id=%s",
                    (recovery_pin_hash, user_id),
                )
                return cur.rowcount

    def find_user_by_email(self, email):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, email, username, password_hash, recovery_pin_hash, is_operario FROM users WHERE LOWER(email)=LOWER(%s) LIMIT 1",
                    (email,),
                )
                return cur.fetchone()

    def list_user_ids(self):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id FROM users")
                rows = cur.fetchall()
                return [r['id'] for r in rows]

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

    def list_operario_user_ids(self):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id FROM users WHERE is_operario=1")
                rows = cur.fetchall()
                return [r['id'] for r in rows]

    def create_card_request(self, user_id, card_id, payload_json):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO card_requests (user_id, card_id, payload_json) VALUES (%s, %s, %s)",
                    (user_id, card_id, payload_json),
                )
                return cur.lastrowid

    def list_card_requests_for_user(self, user_id, limit=50):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, user_id, card_id, payload_json, status, decision_reason, reviewed_by, reviewed_at, created_at "
                    "FROM card_requests WHERE user_id=%s ORDER BY created_at DESC, id DESC LIMIT %s",
                    (user_id, limit),
                )
                return cur.fetchall()

    def list_card_requests(self, status=None, limit=100):
        with self._conn() as conn:
            with conn.cursor() as cur:
                sql = (
                    "SELECT id, user_id, card_id, payload_json, status, decision_reason, reviewed_by, reviewed_at, created_at "
                    "FROM card_requests"
                )
                params = []
                if status:
                    sql += " WHERE status=%s"
                    params.append(status)
                sql += " ORDER BY created_at DESC, id DESC LIMIT %s"
                params.append(limit)
                cur.execute(sql, params)
                return cur.fetchall()

    def update_card_request_status(self, request_id, status, reviewed_by, reason=None):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "UPDATE card_requests SET status=%s, decision_reason=%s, reviewed_by=%s, reviewed_at=NOW() WHERE id=%s",
                    (status, reason, reviewed_by, request_id),
                )
                return cur.rowcount

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

    def get_transport_profile(self, user_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT card_key, card_label, recharge_mode, age_group, travel_count, payment_method, saldo_balance, has_saldo_card, card_state, updated_at "
                    "FROM user_transport_profile WHERE user_id=%s LIMIT 1",
                    (user_id,),
                )
                return cur.fetchone()

    def upsert_transport_profile(
        self,
        user_id,
        card_key,
        card_label,
        recharge_mode,
        age_group,
        travel_count,
        payment_method,
        saldo_balance,
        has_saldo_card,
        card_state,
    ):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO user_transport_profile (
                        user_id,
                        card_key,
                        card_label,
                        recharge_mode,
                        age_group,
                        travel_count,
                        payment_method,
                        saldo_balance,
                        has_saldo_card,
                        card_state
                    ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                    ON DUPLICATE KEY UPDATE
                        card_key=VALUES(card_key),
                        card_label=VALUES(card_label),
                        recharge_mode=VALUES(recharge_mode),
                        age_group=VALUES(age_group),
                        travel_count=VALUES(travel_count),
                        payment_method=VALUES(payment_method),
                        saldo_balance=VALUES(saldo_balance),
                        has_saldo_card=VALUES(has_saldo_card),
                        card_state=VALUES(card_state)
                    """,
                    (
                        user_id,
                        card_key,
                        card_label,
                        recharge_mode,
                        age_group,
                        travel_count,
                        payment_method,
                        saldo_balance,
                        has_saldo_card,
                        card_state,
                    ),
                )
                return cur.rowcount

    # ============ NOTICES (Avisos) ============
    def create_notice(self, title, message, notice_type, related_id=None):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO notices (title, message, type, related_id, is_active) VALUES (%s, %s, %s, %s, 1)",
                    (title, message, notice_type, related_id),
                )
                return cur.lastrowid

    def list_active_notices(self):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT id, title, message, type, related_id, created_at FROM notices WHERE is_active=1 ORDER BY created_at DESC LIMIT 50",
                )
                return cur.fetchall()

    def deactivate_notice(self, notice_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE notices SET is_active=0 WHERE id=%s", (notice_id,))
                return cur.rowcount

    # ============ DISABLED STOPS (Paradas Deshabilitadas) ============
    def disable_stop(self, stop_id, stop_name, reason, disabled_by_user_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO disabled_stops (stop_id, stop_name, reason, disabled_by, is_active) VALUES (%s, %s, %s, %s, 1) "
                    "ON DUPLICATE KEY UPDATE is_active=1, reason=%s, disabled_by=%s, updated_at=NOW()",
                    (stop_id, stop_name, reason, disabled_by_user_id, reason, disabled_by_user_id),
                )
                return cur.lastrowid

    def enable_stop(self, stop_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute("UPDATE disabled_stops SET is_active=0 WHERE stop_id=%s", (stop_id,))
                return cur.rowcount

    def list_disabled_stops(self):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute(
                    "SELECT stop_id, stop_name, reason, disabled_by, created_at FROM disabled_stops WHERE is_active=1 ORDER BY created_at DESC",
                )
                return cur.fetchall()

    def is_stop_disabled(self, stop_id):
        with self._conn() as conn:
            with conn.cursor() as cur:
                cur.execute("SELECT id FROM disabled_stops WHERE stop_id=%s AND is_active=1 LIMIT 1", (stop_id,))
                return cur.fetchone() is not None
