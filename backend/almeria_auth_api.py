from flask import Flask
from flask_cors import CORS
import os

from auth_mvc import AuthRepository, AuthService, create_auth_blueprint

app = Flask(__name__)
CORS(app)

app.config['SECRET_KEY'] = os.getenv('APP_SECRET_KEY', 'almeriaruta-dev-secret-change-me')
TOKEN_TTL_SECONDS = 60 * 60 * 24 * 7  # 7 dias

auth_repo = AuthRepository()
auth_service = AuthService(
    repository=auth_repo,
    secret_key=app.config['SECRET_KEY'],
    token_ttl_seconds=TOKEN_TTL_SECONDS,
)
app.register_blueprint(create_auth_blueprint(auth_service))


if __name__ == '__main__':
    print('Iniciando API de autenticacion (MySQL) en puerto 5001...')
    auth_repo.init_schema()
    app.run(debug=True, host='0.0.0.0', port=5001)
