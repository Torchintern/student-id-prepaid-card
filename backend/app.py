from flask import Flask, request, jsonify
from flask_cors import CORS
from db import get_db
from otp_service import send_otp, verify_otp
import re

app = Flask(__name__)
CORS(app)

EMAIL_REGEX = r'^[\w\.-]+@[\w\.-]+\.\w+$'
MOBILE_REGEX = r'^\d{10}$'


@app.route("/", methods=["GET"])
def health():
    return jsonify({"status": "Backend running"}), 200


# ================= SEND OTP (LOGIN) =================
@app.route("/send-otp", methods=["POST"])
def send_otp_login():
    data = request.json or {}
    mobile = data.get("mobile")
    role = data.get("role")

    if not mobile or not re.match(MOBILE_REGEX, mobile):
        return jsonify({"message": "Enter valid 10-digit mobile number"}), 400

    table = {
        "student": "students",
        "merchant": "merchants",
        "admin": "admins"
    }.get(role)

    if not table:
        return jsonify({"message": "Invalid role"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute(f"SELECT id FROM {table} WHERE mobile=%s", (mobile,))
    if not cur.fetchone():
        return jsonify({"message": "Mobile number not registered"}), 403

    send_otp(mobile)
    return jsonify({"message": "OTP sent"}), 200


# ================= SEND OTP (REGISTER) =================
@app.route("/send-otp-register", methods=["POST"])
def send_otp_register():
    mobile = request.json.get("mobile")

    if not mobile or not re.match(MOBILE_REGEX, mobile):
        return jsonify({"message": "Enter valid 10-digit mobile number"}), 400

    send_otp(mobile)
    return jsonify({"message": "OTP sent"}), 200


# ================= VERIFY OTP =================
@app.route("/verify-otp", methods=["POST"])
def verify_otp_api():
    data = request.json or {}
    mobile = data.get("mobile")
    otp = data.get("otp")

    if not mobile or not otp:
        return jsonify({"message": "Mobile and OTP required"}), 400

    if verify_otp(mobile, otp):
        return jsonify({"message": "OTP verified"}), 200
    return jsonify({"message": "Invalid OTP"}), 400


# ================= STUDENT REGISTRATION =================
@app.route("/register/student", methods=["POST"])
def register_student():
    data = request.json or {}
    name = data.get("name")
    email = data.get("email")
    mobile = data.get("mobile")

    if not name or not email or not re.match(EMAIL_REGEX, email):
        return jsonify({"message": "Invalid name or email"}), 400

    if not mobile or not re.match(MOBILE_REGEX, mobile):
        return jsonify({"message": "Enter valid 10-digit mobile number"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    # Check duplicates
    cur.execute("SELECT id FROM students WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Student"}), 409

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Merchant"}), 409

    cur.execute(
        "INSERT INTO students (name, email, mobile) VALUES (%s,%s,%s)",
        (name, email, mobile)
    )
    db.commit()

    return jsonify({"message": "Student registered successfully"}), 200


# ================= MERCHANT REGISTRATION =================
@app.route("/register/merchant", methods=["POST"])
def register_merchant():
    data = request.json or {}
    merchant = data.get("merchant_name")
    company = data.get("company_name")
    business_type = data.get("business_type")
    mobile = data.get("mobile")

    if not all([merchant, company, business_type, mobile]):
        return jsonify({"message": "All merchant fields are required"}), 400

    if not re.match(MOBILE_REGEX, mobile):
        return jsonify({"message": "Enter valid 10-digit mobile number"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    # Check duplicates
    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Merchant"}), 409

    cur.execute("SELECT id FROM students WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Student"}), 409

    cur.execute(
        """INSERT INTO merchants
        (merchant_name, company_name, business_type, mobile)
        VALUES (%s,%s,%s,%s)""",
        (merchant, company, business_type, mobile)
    )
    db.commit()

    return jsonify({"message": "Merchant registered successfully"}), 200


# ================= LOGIN =================
@app.route("/login", methods=["POST"])
def login():
    data = request.json or {}
    mobile = data.get("mobile")
    otp = data.get("otp")

    if not mobile or not otp:
        return jsonify({"message": "Mobile and OTP required"}), 400

    if not verify_otp(mobile, otp):
        return jsonify({"message": "Invalid OTP"}), 400
    return jsonify({"message": "Login success"}), 200


# ================= MERCHANT TRANSACTIONS =================
@app.route("/merchant/transactions/<mobile>", methods=["GET"])
def get_transactions(mobile):
    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("""
        SELECT payer_name, amount, created_at
        FROM transactions
        WHERE merchant_mobile=%s
        ORDER BY created_at DESC
        LIMIT 5
    """, (mobile,))

    rows = cur.fetchall()
    return jsonify(rows), 200


@app.route("/merchant/transaction", methods=["POST"])
def add_transaction():
    data = request.json or {}
    merchant_mobile = data.get("merchant_mobile")
    payer_name = data.get("payer_name")
    amount = data.get("amount")

    if not all([merchant_mobile, payer_name, amount]):
        return jsonify({"message": "All transaction fields are required"}), 400

    db = get_db()
    cur = db.cursor()

    cur.execute("""
        INSERT INTO transactions (merchant_mobile, payer_name, amount)
        VALUES (%s,%s,%s)
    """, (merchant_mobile, payer_name, amount))

    db.commit()
    return jsonify({"message": "Transaction added"}), 200


if __name__ == "__main__":
    app.run(debug=True)
