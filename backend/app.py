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
@app.route("/merchant/transactions/filter", methods=["POST"])
def merchant_transactions_filter():
    data = request.json
    mobile = data.get("mobile")
    filter_type = data.get("filter")  # today / week / month / all
    credit_only = data.get("creditOnly", False)

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify([]), 200

    merchant_id = merchant["id"]

    conditions = ["merchant_id=%s"]
    params = [merchant_id]

    # CREDIT + SUCCESS
    if credit_only:
        conditions.append("type='CREDIT'")
        conditions.append("status='SUCCESS'")

    # DATE FILTER
    if filter_type == "today":
        conditions.append("DATE(created_at)=CURDATE()")
    elif filter_type == "week":
        conditions.append("YEARWEEK(created_at,1)=YEARWEEK(CURDATE(),1)")
    elif filter_type == "month":
        conditions.append(
            "MONTH(created_at)=MONTH(CURDATE()) AND YEAR(created_at)=YEAR(CURDATE())"
        )

    where_clause = " AND ".join(conditions)

    query = f"""
        SELECT payer_name, amount, type, status, created_at
        FROM transactions
        WHERE {where_clause}
        ORDER BY created_at DESC
    """

    cur.execute(query, tuple(params))
    return jsonify(cur.fetchall()), 200


# Merchant collection
@app.route("/merchant/collection-summary", methods=["POST"])
def merchant_collection_summary():
    data = request.json
    mobile = data.get("mobile")
    filter_type = data.get("filter")  # today / week / month

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify({"total": 0, "count": 0}), 200

    merchant_id = merchant["id"]

    date_condition = ""
    if filter_type == "today":
        date_condition = "DATE(created_at) = CURDATE()"
    elif filter_type == "week":
        date_condition = "YEARWEEK(created_at, 1) = YEARWEEK(CURDATE(), 1)"
    elif filter_type == "month":
        date_condition = (
            "MONTH(created_at)=MONTH(CURDATE()) "
            "AND YEAR(created_at)=YEAR(CURDATE())"
        )

    query = f"""
        SELECT
            IFNULL(SUM(amount),0) AS total,
            COUNT(*) AS count
        FROM transactions
        WHERE merchant_id=%s
          AND type='CREDIT'
          AND status='SUCCESS'
          AND {date_condition}
    """

    cur.execute(query, (merchant_id,))
    result = cur.fetchone()

    return jsonify({
        "total": float(result["total"]),
        "count": result["count"]
    }), 200

# ================= BUSINESS INSIGHTS (TODAY) =================
@app.route("/merchant/insights/today", methods=["POST"])
def merchant_insights_today():
    mobile = request.json.get("mobile")
    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify({"data": {}, "growth": 0}), 200

    merchant_id = merchant["id"]

    cur.execute("""
        SELECT
            DATE_FORMAT(grp_date,'%a') AS label,
            total
        FROM (
            SELECT
                DATE(created_at) AS grp_date,
                SUM(amount) AS total
            FROM transactions
            WHERE merchant_id=%s
              AND type='CREDIT'
              AND status='SUCCESS'
              AND created_at >= CURDATE() - INTERVAL 6 DAY
            GROUP BY DATE(created_at)
        ) t
        ORDER BY grp_date
    """, (merchant_id,))

    data = {row["label"]: float(row["total"]) for row in cur.fetchall()}

    return jsonify({"data": data, "growth": 0}), 200


# ================= BUSINESS INSIGHTS (MONTHLY) =================
@app.route("/merchant/insights/monthly", methods=["POST"])
def merchant_insights_monthly():
    mobile = request.json.get("mobile")
    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify({"data": {}, "growth": 0}), 200

    merchant_id = merchant["id"]

    cur.execute("""
        SELECT
            DATE_FORMAT(grp_month,'%b %Y') AS label,
            total
        FROM (
            SELECT
                DATE_FORMAT(created_at,'%Y-%m-01') AS grp_month,
                SUM(amount) AS total
            FROM transactions
            WHERE merchant_id=%s
              AND type='CREDIT'
              AND status='SUCCESS'
              AND created_at >= DATE_SUB(CURDATE(), INTERVAL 5 MONTH)
            GROUP BY DATE_FORMAT(created_at,'%Y-%m-01')
        ) t
        ORDER BY grp_month
    """, (merchant_id,))

    data = {row["label"]: float(row["total"]) for row in cur.fetchall()}

    return jsonify({"data": data, "growth": 0}), 200
# Merchant MY INFO
@app.route('/merchant/my-info', methods=['POST'])
def merchant_my_info():
    data = request.json
    mobile = data['mobile']

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("""
        SELECT merchant_name, company_name, business_type,
               mobile, email, aadhaar,
               email_verified, aadhaar_verified,
               allow_sensitive_edit
        FROM merchants
        WHERE mobile=%s
    """, (mobile,))
    merchant = cur.fetchone()
    cur.close()

    if not merchant:
        return jsonify({'message': 'Merchant not found'}), 404

    return jsonify(merchant), 200
# Merchant Update INFO
@app.route('/merchant/update-info', methods=['POST'])
def update_merchant_info():
    data = request.json
    mobile = data.get('mobile')
    email = data.get('email')
    aadhaar = data.get('aadhaar')

    if not mobile:
        return jsonify({'message': 'Mobile is required'}), 400

    db = get_db()
    cur = db.cursor()

    # Allow edit after OTP verification
    cur.execute(
        "UPDATE merchants SET allow_sensitive_edit=1 WHERE mobile=%s",
        (mobile,)
    )

    if email:
        cur.execute("""
            UPDATE merchants
            SET email=%s,
                email_verified=1,
                allow_sensitive_edit=0
            WHERE mobile=%s
        """, (email, mobile))

    if aadhaar:
        cur.execute("""
            UPDATE merchants
            SET aadhaar=%s,
                aadhaar_verified=1,
                allow_sensitive_edit=0
            WHERE mobile=%s
        """, (aadhaar, mobile))

    db.commit()
    cur.close()

    return jsonify({'message': 'Information updated successfully'}), 200
# ================= BANKS (STATIC LIST) =================
@app.route("/banks/list", methods=["GET"])
def banks_list():
    return jsonify([
        {"name": "ICICI Bank"},
        {"name": "HDFC Bank"},
        {"name": "Punjab National Bank"},
        {"name": "Kotak Mahindra Bank"},
        {"name": "Indian Bank"},
        {"name": "State Bank of India"},
        {"name": "IDFC First Bank"},
        {"name": "YES Bank"},
        {"name": "Axis Bank"},
    ]), 200


# ================= CHECK BANK LINK (DB BASED) =================
@app.route("/bank/check-linked", methods=["POST"])
def check_bank_linked():
    data = request.json
    mobile = data.get("mobile")
    bank_name = data.get("bank_name")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("""
        SELECT account_number, ifsc_code, account_holder_name
        FROM bank_accounts
        WHERE mobile=%s AND bank_name=%s
    """, (mobile, bank_name))

    account = cur.fetchone()

    if not account:
        return jsonify({
            "linked": False,
            "message": "Mobile number not linked with this bank"
        }), 200

    return jsonify({
        "linked": True,
        "account": account
    }), 200


# ================= ADD MERCHANT BANK =================
@app.route("/merchant/bank/add", methods=["POST"])
def add_merchant_bank():
    data = request.json

    db = get_db()
    cur = db.cursor()

    cur.execute("""
        INSERT INTO merchant_bank_accounts
        (merchant_mobile, bank_name, account_number, ifsc_code)
        VALUES (%s,%s,%s,%s)
    """, (
        data["mobile"],
        data["bank_name"],
        data["account_number"],
        data["ifsc_code"],
    ))

    db.commit()
    return jsonify({"message": "Bank account linked successfully"}), 200
# verification OTP for bank
@app.route("/bank/send-otp", methods=["POST"])
def send_bank_otp():
    mobile = request.json.get("mobile")

    if not mobile:
        return jsonify({"message": "Mobile required"}), 400

    send_otp(mobile)
    return jsonify({"message": "OTP sent to registered mobile"}), 200
# VERIFY OTP + LINK BANK
@app.route("/merchant/bank/link", methods=["POST"])
def link_bank_account():
    data = request.json

    mobile = data.get("mobile")
    bank_name = data.get("bank_name")
    account_number = data.get("account_number")
    ifsc_code = data.get("ifsc_code")

    db = get_db()
    cur = db.cursor()

    # Prevent duplicate linking
    cur.execute("""
        SELECT id FROM merchant_bank_accounts
        WHERE merchant_mobile=%s AND bank_name=%s
    """, (mobile, bank_name))

    if cur.fetchone():
        return jsonify({"message": "Bank already linked"}), 409

    cur.execute("""
        INSERT INTO merchant_bank_accounts
        (merchant_mobile, bank_name, account_number, ifsc_code)
        VALUES (%s,%s,%s,%s)
    """, (mobile, bank_name, account_number, ifsc_code))

    db.commit()
    cur.close()

    return jsonify({"message": "Bank linked successfully"}), 200
#check any bank linked or not
@app.route("/merchant/bank/check-any", methods=["POST"])
def check_any_bank():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("""
        SELECT bank_name, account_number, ifsc_code
        FROM merchant_bank_accounts
        WHERE merchant_mobile=%s
        LIMIT 1
    """, (mobile,))

    account = cur.fetchone()

    if not account:
        return jsonify({"linked": False}), 200

    return jsonify({
        "linked": True,
        "account": account
    }), 200
    # check balance
@app.route("/merchant/bank/balance", methods=["POST"])
def merchant_check_balance():
    data = request.json

    mobile = data.get("mobile")
    pin = data.get("pin")
    bank_name = data.get("bank_name")

    if not all([mobile, pin, bank_name]):
        return jsonify({"message": "Missing required fields"}), 400

    db = get_db()
    cur = db.cursor(dictionary=True)

    # ================= VERIFY MERCHANT PIN =================
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
        return jsonify({"message": "PIN locked"}), 403

    if not check_password_hash(merchant["pin_hash"], pin):
        cur.execute(
            "UPDATE merchants SET pin_attempts = pin_attempts + 1 WHERE id=%s",
            (merchant["id"],)
        )
        db.commit()
        return jsonify({"message": "Invalid PIN"}), 403

    # Reset PIN attempts
    cur.execute(
        "UPDATE merchants SET pin_attempts=0 WHERE id=%s",
        (merchant["id"],)
    )

    # ================= FETCH BALANCE FROM BANK TABLE =================
    cur.execute("""
        SELECT available_balance
        FROM merchant_bank_accounts
        WHERE merchant_mobile=%s AND bank_name=%s
        LIMIT 1
    """, (mobile, bank_name))

    bank = cur.fetchone()

    if not bank:
        return jsonify({"message": "Bank account not found"}), 404

    balance = bank["available_balance"] or 0

    db.commit()
    cur.close()

    return jsonify({
        "bank_name": bank_name,
        "balance": float(balance),
    }), 200


    # ================= VERIFY MERCHANT =================
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
        return jsonify({"message": "PIN locked"}), 403

    if not check_password_hash(merchant["pin_hash"], pin):
        cur.execute(
            "UPDATE merchants SET pin_attempts = pin_attempts + 1 WHERE id=%s",
            (merchant["id"],)
        )
        db.commit()
        return jsonify({"message": "Invalid PIN"}), 403

    # Reset attempts
    cur.execute(
        "UPDATE merchants SET pin_attempts = 0 WHERE id=%s",
        (merchant["id"],)
    )

    # ================= BANK-SPECIFIC BALANCE =================
    cur.execute("""
        SELECT IFNULL(SUM(
          CASE 
            WHEN t.type='CREDIT' AND t.status='SUCCESS' THEN t.amount
            WHEN t.type='DEBIT'  AND t.status='SUCCESS' THEN -t.amount
            ELSE 0
          END
        ), 0) AS balance
        FROM transactions t
        JOIN merchant_bank_accounts b
          ON b.merchant_mobile=%s
         AND b.bank_name=%s
        WHERE t.merchant_id=%s
    """, (
        mobile,
        bank_name,
        merchant["id"],
    ))

    balance = cur.fetchone()["balance"]
    db.commit()

    return jsonify({
        "bank_name": bank_name,
        "balance": float(balance),
    }), 200

# fetch bank account
@app.route("/merchant/bank/list", methods=["POST"])
def list_merchant_banks():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("""
        SELECT bank_name, account_number, ifsc_code
        FROM merchant_bank_accounts
        WHERE merchant_mobile=%s
    """, (mobile,))

    accounts = cur.fetchall()
    return jsonify(accounts), 200
    

# ================= HELPER =================
def _insert_txn(cur, merchant_id, payer_name, amount, txn_type, status):
    cur.execute(
        """
        INSERT INTO transactions
        (merchant_id, payer_name, amount, type, status, created_at)
        VALUES (%s,%s,%s,%s,%s,NOW())
        """,
        (merchant_id, payer_name, amount, txn_type, status)
    )


if __name__ == "__main__":
    app.run(debug=True)
