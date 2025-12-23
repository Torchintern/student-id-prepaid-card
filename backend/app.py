from flask import Flask, request, jsonify
from flask_cors import CORS
from db import get_db
from otp_service import send_otp, verify_otp

app = Flask(__name__)
CORS(app)

# HEALTH CHECK
@app.route("/", methods=["GET"])
def health():
    return jsonify({"status": "Backend running"}), 200
# SEND OTP FOR LOGIN
# (Checks registration for student/merchant)

@app.route("/send-otp", methods=["POST"])
def send_otp_login():
    data = request.json
    mobile = data.get("mobile")
    role = data.get("role")

    if not mobile or len(mobile) != 10:
        return jsonify({"message": "Invalid mobile number"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    if role == "student":
        cur.execute("SELECT id FROM students WHERE mobile=%s", (mobile,))
        if not cur.fetchone():
            return jsonify({"message": "Student not registered"}), 403

    elif role == "merchant":
        cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
        if not cur.fetchone():
            return jsonify({"message": "Merchant not registered"}), 403

    # Admin → no registration check
    send_otp(mobile)
    return jsonify({"message": "OTP sent"}), 200

# SEND OTP FOR REGISTRATION
@app.route("/send-otp-register", methods=["POST"])
def send_otp_register():
    data = request.json
    mobile = data.get("mobile")

    if not mobile or len(mobile) != 10:
        return jsonify({"message": "Invalid mobile number"}), 400

    send_otp(mobile)
    return jsonify({"message": "OTP sent for registration"}), 200

# VERIFY OTP

@app.route("/verify-otp", methods=["POST"])
def verify_otp_api():
    data = request.json
    mobile = data.get("mobile")
    otp = data.get("otp")

    if verify_otp(mobile, otp):
        return jsonify({"message": "OTP verified"}), 200

    return jsonify({"message": "Invalid OTP"}), 400



# STUDENT REGISTRATION
@app.route("/register/student", methods=["POST"])
def register_student():
    data = request.json
    name = data.get("name")
    college_id = data.get("college_id")
    mobile = data.get("mobile")

    if not name or not mobile:
        return jsonify({"message": "Missing required fields"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM students WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Student already registered"}), 409

    cur.execute(
        "INSERT INTO students (name, college_id, mobile) VALUES (%s,%s,%s)",
        (name, college_id, mobile),
    )
    db.commit()

    return jsonify({"message": "Student registered successfully"}), 200



# MERCHANT REGISTRATION
@app.route("/register/merchant", methods=["POST"])
def register_merchant():
    data = request.json
    merchant_name = data.get("merchant_name")
    company_name = data.get("company_name")
    tax_id = data.get("tax_id")
    mobile = data.get("mobile")

    if not merchant_name or not company_name or not tax_id or not mobile:
        return jsonify({"message": "Missing required fields"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    if cur.fetchone():
        return jsonify({"message": "Merchant already registered"}), 409

    cur.execute(
        """
        INSERT INTO merchants (merchant_name, company_name, tax_id, mobile)
        VALUES (%s,%s,%s,%s)
        """,
        (merchant_name, company_name, tax_id, mobile),
    )
    db.commit()

    return jsonify({"message": "Merchant registered successfully"}), 200

# LOGIN
@app.route("/login", methods=["POST"])
def login():
    data = request.json
    mobile = data.get("mobile")
    otp = data.get("otp")

    if not verify_otp(mobile, otp):
        return jsonify({"message": "Invalid OTP"}), 400

    return jsonify({"message": "Login success"}), 200


if __name__ == "__main__":
    app.run(debug=True)
