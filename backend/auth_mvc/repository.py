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
                    "SELECT id, email, username, password_hash, created_at FROM users WHERE id=%s LIMIT 1",
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
