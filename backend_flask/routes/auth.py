from flask import Blueprint, request, jsonify
from flask_jwt_extended import create_access_token
from db import cursor, db
import random
from datetime import datetime, timedelta

auth = Blueprint('auth', __name__)

def generate_otp():
    return str(random.randint(100000, 999999))


@auth.route('/send-login-otp', methods=['POST'])
def send_login_otp():
    data = request.json
    otp = generate_otp()
    expiry = datetime.now() + timedelta(minutes=5)

    cursor.execute(
        "INSERT INTO otp_verification (mobile, otp, expires_at) VALUES (%s,%s,%s)",
        (data['mobile'], otp, expiry)
    )
    db.commit()

    print("LOGIN OTP:", otp)
    return jsonify({"message": "OTP sent"}), 200


@auth.route('/verify-login-otp', methods=['POST'])
def verify_login_otp():
    data = request.json

    cursor.execute(
        "SELECT * FROM users WHERE mobile=%s AND is_verified=TRUE",
        (data['mobile'],)
    )
    user = cursor.fetchone()

    cursor.execute(
        "SELECT * FROM otp_verification WHERE mobile=%s ORDER BY id DESC LIMIT 1",
        (data['mobile'],)
    )
    otp_record = cursor.fetchone()

    if not user or not otp_record or otp_record['otp'] != data['otp']:
        return jsonify({"error": "Invalid OTP"}), 401

    # 🔹 CREATE WALLET IF NOT EXISTS
    cursor.execute("SELECT * FROM wallets WHERE user_id=%s", (user['id'],))
    wallet = cursor.fetchone()

    if not wallet:
        cursor.execute(
            "INSERT INTO wallets (user_id, balance, tier) VALUES (%s, 0.00, 'Silver')",
            (user['id'],)
        )
        db.commit()

    token = create_access_token(identity={
        "id": user['id'],
        "role": user['role']
    })

    return jsonify({"token": token}), 200
