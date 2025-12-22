from flask import Flask
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from routes.auth import auth
from routes.wallet import wallet

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = 'super-secret-key'

CORS(app)
JWTManager(app)

app.register_blueprint(auth)
app.register_blueprint(wallet)

@app.route('/')
def home():
    return "Backend Running"

if __name__ == '__main__':
    app.run(debug=True)
