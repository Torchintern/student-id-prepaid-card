from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import cursor

dashboard = Blueprint('dashboard', __name__)

@dashboard.route('/dashboard', methods=['GET'])
@jwt_required()
def dashboard_data():
    user = get_jwt_identity()

    cursor.execute("""
        SELECT u.name, u.mobile, w.balance, w.tier
        FROM users u
        JOIN wallets w ON u.id = w.user_id
        WHERE u.id=%s
    """, (user['id'],))

    data = cursor.fetchone()
    return jsonify(data), 200
