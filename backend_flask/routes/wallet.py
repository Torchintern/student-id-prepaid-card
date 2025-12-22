from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from db import cursor

wallet = Blueprint('wallet', __name__)

@wallet.route('/wallet', methods=['GET'])
@jwt_required()
def get_wallet():
    user_id = int(get_jwt_identity())

    cursor.execute(
        "SELECT balance FROM wallets WHERE user_id=%s",
        (user_id,)
    )
    wallet = cursor.fetchone()

    return jsonify(wallet), 200
