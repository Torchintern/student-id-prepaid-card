from flask import Flask, request, jsonify
from flask_cors import CORS
from db import get_db
from otp_service import send_otp, verify_otp
import re

app = Flask(__name__)
CORS(app)

GSTIN_REGEX = r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][0-9]Z[A-Z0-9]$'

@app.route("/", methods=["GET"])
def health():
    return jsonify({"status": "Backend running"}), 200


# ================= SEND OTP (LOGIN) =================
@app.route("/send-otp", methods=["POST"])
def send_otp_login():
    data = request.json
    mobile = data.get("mobile")
    role = data.get("role")

    if not mobile or not re.fullmatch(r"\d{10}", mobile):
        return jsonify({"message": "Enter valid 10-digit mobile number"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    table = {
        "student": "students",
        "merchant": "merchants",
        "admin": "admins"
    }.get(role)

    if not table:
        return jsonify({"message": "Invalid role"}), 400

    cur.execute(f"SELECT id FROM {table} WHERE mobile=%s", (mobile,))
    if not cur.fetchone():
        return jsonify({"message": "Mobile number not registered"}), 403

    send_otp(mobile)
    return jsonify({"message": "OTP sent"}), 200


# ================= SEND OTP (REGISTRATION) =================
@app.route("/send-otp-register", methods=["POST"])
def send_otp_register():
    mobile = request.json.get("mobile")

    if not mobile or not re.fullmatch(r"\d{10}", mobile):
        return jsonify({"message": "Enter valid 10-digit mobile number"}), 400

    send_otp(mobile)
    return jsonify({"message": "OTP sent"}), 200


# ================= VERIFY OTP =================
@app.route("/verify-otp", methods=["POST"])
def verify_otp_api():
    data = request.json
    if verify_otp(data.get("mobile"), data.get("otp")):
        return jsonify({"message": "OTP verified"}), 200
    return jsonify({"message": "Invalid OTP"}), 400


# ================= STUDENT REGISTRATION =================
@app.route("/register/student", methods=["POST"])
def register_student():
    data = request.json
    mobile = data.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM students WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Student"}), 409

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Merchant"}), 409

    cur.execute(
        "INSERT INTO students (name, college_id, mobile) VALUES (%s,%s,%s)",
        (data.get("name"), data.get("college_id"), mobile)
    )
    db.commit()

    return jsonify({"message": "Student registered successfully"}), 200


# ================= MERCHANT REGISTRATION =================
@app.route("/register/merchant", methods=["POST"])
def register_merchant():
    data = request.json
    mobile = data.get("mobile")
    gstin = data.get("gstin")

    if not re.fullmatch(GSTIN_REGEX, gstin):
        return jsonify({
            "message": "Invalid GSTIN format. Example: 22AAAAA0000A1Z5"
        }), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Merchant"}), 409

    cur.execute("SELECT id FROM students WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Student"}), 409

    cur.execute(
        """INSERT INTO merchants
        (merchant_name, company_name, gstin, mobile)
        VALUES (%s,%s,%s,%s)""",
        (
            data.get("merchant_name"),
            data.get("company_name"),
            gstin,
            mobile
        )
    )
    db.commit()

    return jsonify({"message": "Merchant registered successfully"}), 200


# ================= LOGIN =================
@app.route("/login", methods=["POST"])
def login():
    data = request.json
    if not verify_otp(data.get("mobile"), data.get("otp")):
        return jsonify({"message": "Invalid OTP"}), 400
    return jsonify({"message": "Login success"}), 200


if __name__ == "__main__":
    app.run(debug=True)
