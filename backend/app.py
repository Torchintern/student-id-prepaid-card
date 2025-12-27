from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime
import re

from werkzeug.security import generate_password_hash, check_password_hash

from db import get_db
from otp_service import send_otp, verify_otp

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
    data = request.json
    mobile = data.get("mobile")
    role = data.get("role")

    if not re.match(MOBILE_REGEX, mobile):
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

    if not re.match(MOBILE_REGEX, mobile):
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
    name = data.get("name")
    email = data.get("email")
    mobile = data.get("mobile")

    if not name or not re.match(EMAIL_REGEX, email):
        return jsonify({"message": "Invalid name or email"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

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
    data = request.json
    merchant_name = data.get("merchant_name")
    company_name = data.get("company_name")
    business_type = data.get("business_type")
    mobile = data.get("mobile")

    if not all([merchant_name, company_name, business_type]):
        return jsonify({"message": "All merchant fields are required"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Merchant"}), 409

    cur.execute("SELECT id FROM students WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Mobile already registered as Student"}), 409

    cur.execute(
        """
        INSERT INTO merchants (merchant_name, company_name, business_type, mobile)
        VALUES (%s,%s,%s,%s)
        """,
        (merchant_name, company_name, business_type, mobile)
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


# ================= MERCHANT PROFILE =================
@app.route("/merchant/profile", methods=["POST"])
def merchant_profile():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute(
        "SELECT merchant_name, company_name FROM merchants WHERE mobile=%s",
        (mobile,)
    )
    merchant = cur.fetchone()

    if not merchant:
        return jsonify({"message": "Merchant not found"}), 404

    return jsonify(merchant), 200


# ================= CHANGE MERCHANT PIN =================
@app.route("/merchant/change-pin", methods=["POST"])
def change_merchant_pin():
    data = request.json
    mobile = data.get("mobile")
    otp = data.get("otp")
    pin = data.get("pin")

    if not verify_otp(mobile, otp):
        return jsonify({"message": "Invalid OTP"}), 400

    if not pin or not pin.isdigit() or len(pin) != 4:
        return jsonify({"message": "PIN must be 4 digits"}), 400

    pin_hash = generate_password_hash(pin)

    db = get_db()
    cur = db.cursor()
    cur.execute(
        "UPDATE merchants SET pin_hash=%s, pin_attempts=0 WHERE mobile=%s",
        (pin_hash, mobile)
    )
    db.commit()

    return jsonify({"message": "PIN updated successfully"}), 200


# ================= MERCHANT PAY (DEBIT) =================
@app.route("/merchant/pay", methods=["POST"])
def merchant_pay():
    data = request.json
    mobile = data.get("mobile")
    receiver = data.get("receiver")
    amount = data.get("amount")
    pin = data.get("pin")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute(
        "SELECT id, pin_hash, pin_attempts FROM merchants WHERE mobile=%s",
        (mobile,)
    )
    merchant = cur.fetchone()

    if not merchant:
        return jsonify({"message": "Merchant not found"}), 404

    if not merchant["pin_hash"]:
        return jsonify({"message": "PIN not set"}), 403

    if merchant["pin_attempts"] >= 3:
        _insert_txn(cur, merchant["id"], receiver, amount, "DEBIT", "FAILED")
        db.commit()
        return jsonify({"message": "PIN locked"}), 403

    if not check_password_hash(merchant["pin_hash"], pin):
        cur.execute(
            "UPDATE merchants SET pin_attempts = pin_attempts + 1 WHERE id=%s",
            (merchant["id"],)
        )
        _insert_txn(cur, merchant["id"], receiver, amount, "DEBIT", "FAILED")
        db.commit()
        return jsonify({"message": "Invalid PIN"}), 403

    cur.execute(
        "UPDATE merchants SET pin_attempts = 0 WHERE id=%s",
        (merchant["id"],)
    )

    _insert_txn(cur, merchant["id"], receiver, amount, "DEBIT", "SUCCESS")
    db.commit()

    return jsonify({"message": "Payment successful"}), 200


# ================= CREATE QR =================
@app.route("/qr/create", methods=["POST"])
def create_qr():
    data = request.json
    mobile = data.get("mobile")
    amount = data.get("amount")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()

    if not merchant:
        return jsonify({"message": "Merchant not found"}), 404

    cur.execute(
        """
        INSERT INTO qr_payments (merchant_id, amount, expires_at, status)
        VALUES (%s,%s, NOW() + INTERVAL 2 MINUTE, 'PENDING')
        """,
        (merchant["id"], amount)
    )
    db.commit()

    return jsonify({"qr_id": cur.lastrowid}), 200


# ================= CANCEL QR =================
@app.route("/qr/cancel", methods=["POST"])
def cancel_qr():
    qr_id = request.json.get("qr_id")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT status FROM qr_payments WHERE id=%s", (qr_id,))
    qr = cur.fetchone()

    if not qr or qr["status"] != "PENDING":
        return jsonify({"message": "QR cannot be cancelled"}), 400

    cur.execute(
        "UPDATE qr_payments SET status='CANCELLED' WHERE id=%s",
        (qr_id,)
    )
    db.commit()

    return jsonify({"message": "QR cancelled"}), 200


# ================= PAY QR (CREDIT) =================
@app.route("/qr/pay", methods=["POST"])
def pay_qr():
    data = request.json
    qr_id = data.get("qr_id")
    payer_name = data.get("payer_name")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT * FROM qr_payments WHERE id=%s", (qr_id,))
    qr = cur.fetchone()

    if not qr:
        return jsonify({"message": "Invalid QR"}), 404

    if qr["status"] != "PENDING":
        return jsonify({"message": "QR already used"}), 400

    if qr["expires_at"] < datetime.now():
        cur.execute(
            "UPDATE qr_payments SET status='EXPIRED' WHERE id=%s",
            (qr_id,)
        )
        db.commit()
        return jsonify({"message": "QR expired"}), 400

    _insert_txn(
        cur,
        qr["merchant_id"],
        payer_name,
        qr["amount"],
        "CREDIT",
        "SUCCESS"
    )

    cur.execute(
        "UPDATE qr_payments SET status='SUCCESS' WHERE id=%s",
        (qr_id,)
    )
    db.commit()

    return jsonify({"message": "Payment successful"}), 200


# ================= MERCHANT TRANSACTIONS =================
@app.route("/merchant/transactions", methods=["POST"])
def merchant_transactions():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()

    if not merchant:
        return jsonify([]), 200

    cur.execute(
        """
        SELECT payer_name, amount, type, status, created_at
        FROM transactions
        WHERE merchant_id=%s
        ORDER BY created_at DESC
        """,
        (merchant["id"],)
    )

    rows = cur.fetchall()

    # ✅ FINAL DISPLAY LOGIC
    for r in rows:
        if r["status"] != "SUCCESS":
            r["display"] = "FAILED"
        else:
            r["display"] = "Credited" if r["type"] == "CREDIT" else "Debited"

    return jsonify(rows), 200


# ================= MERCHANT DAILY SUMMARY =================
@app.route("/merchant/daily-summary", methods=["POST"])
def merchant_daily_summary():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()

    if not merchant:
        return jsonify({"total": 0, "count": 0}), 200

    cur.execute(
        """
        SELECT IFNULL(SUM(amount),0) AS total, COUNT(*) AS count
FROM transactions
WHERE merchant_id=%s
  AND status='SUCCESS'
  AND type='CREDIT'
  AND DATE(created_at)=CURDATE()

        """,
        (merchant["id"],)
    )

    return jsonify(cur.fetchone()), 200


# ================= HELPER =================
def _insert_txn(cur, merchant_id, payer_name, amount, txn_type, status):
    cur.execute(
        """
        INSERT INTO transactions
        (merchant_id, payer_name, amount, type, status)
        VALUES (%s,%s,%s,%s,%s)
        """,
        (merchant_id, payer_name, amount, txn_type, status)
    )


if __name__ == "__main__":
    app.run(debug=True)
