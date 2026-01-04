from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
from datetime import datetime
import re
import uuid
import os
from werkzeug.utils import secure_filename
from flask import send_from_directory
from werkzeug.security import generate_password_hash, check_password_hash

from db import get_db
from otp_service import send_otp, verify_otp

app = Flask(__name__)
CORS(app)

EMAIL_REGEX = r'^[\w\.-]+@[\w\.-]+\.\w+$'
MOBILE_REGEX = r'^\d{10}$'


def admin_guard():
    token = request.headers.get("X-ADMIN-TOKEN")
    if not token:
        return False

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT id FROM admins WHERE token=%s", (token,))
    admin = cur.fetchone()

    return admin is not None


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
#=========== transaction Filter ==============
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
# Insights Custom filter
@app.route("/merchant/insights/custom", methods=["POST"])
def merchant_insights_custom():
    data = request.json
    mobile = data["mobile"]
    start = data["start"]
    end = data["end"]

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify({"data": {}}), 200

    cur.execute("""
        SELECT DATE(created_at) AS d, SUM(amount) AS total
        FROM transactions
        WHERE merchant_id=%s
          AND type='CREDIT'
          AND status='SUCCESS'
          AND DATE(created_at) BETWEEN %s AND %s
        GROUP BY DATE(created_at)
        ORDER BY d
    """, (merchant["id"], start, end))

    return jsonify({
        "data": {row["d"].strftime('%d %b'): float(row["total"])
                 for row in cur.fetchall()}
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

# =========== Business INsights summary (ystrdy)=================
@app.route("/merchant/summary/yesterday", methods=["POST"])
def merchant_yesterday_summary():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify({"total": 0, "count": 0}), 200

    cur.execute("""
        SELECT IFNULL(SUM(amount),0) AS total, COUNT(*) AS count
        FROM transactions
        WHERE merchant_id=%s
          AND type='CREDIT'
          AND status='SUCCESS'
          AND DATE(created_at)=CURDATE() - INTERVAL 1 DAY
    """, (merchant["id"],))

    return jsonify(cur.fetchone()), 200
#======== Business Insights Summary prev-week =========
@app.route("/merchant/summary/prev-week", methods=["POST"])
def merchant_prev_week_summary():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify({"total": 0, "count": 0}), 200

    cur.execute("""
        SELECT IFNULL(SUM(amount),0) AS total, COUNT(*) AS count
        FROM transactions
        WHERE merchant_id=%s
          AND type='CREDIT'
          AND status='SUCCESS'
          AND YEARWEEK(created_at,1)=YEARWEEK(CURDATE(),1)-1
    """, (merchant["id"],))

    return jsonify(cur.fetchone()), 200
# ================== Business Inights prev month ===========
@app.route("/merchant/summary/prev-month", methods=["POST"])
def merchant_prev_month_summary():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify({"total": 0, "count": 0}), 200

    cur.execute("""
        SELECT IFNULL(SUM(amount),0) AS total, COUNT(*) AS count
        FROM transactions
        WHERE merchant_id=%s
          AND type='CREDIT'
          AND status='SUCCESS'
          AND MONTH(created_at)=MONTH(CURDATE() - INTERVAL 1 MONTH)
          AND YEAR(created_at)=YEAR(CURDATE() - INTERVAL 1 MONTH)
    """, (merchant["id"],))

    return jsonify(cur.fetchone()), 200

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

# ================= MERCHANT MY INFO =================
@app.route("/merchant/my-info", methods=["POST"])
def merchant_my_info():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT
            merchant_name, company_name, business_type, mobile,
            email, email_verified, dob,
            aadhaar, aadhaar_front_path, aadhaar_back_path, aadhaar_verified,
            gst_number, gst_doc_path, gst_verified,
            wallet_status, wallet_created
        FROM merchants WHERE mobile=%s
    """, (mobile,))

    m = cur.fetchone()
    if not m:
        return jsonify({"message": "Merchant not found"}), 404
    return jsonify(m), 200


# ================= UPDATE INFO (EMAIL / DOB) =================

@app.route("/merchant/update-info", methods=["POST"])
def update_merchant_info():
    d = request.json
    mobile = d.get("mobile")
    email = d.get("email")
    dob = d.get("dob")

    if not mobile:
        return jsonify({"message": "Mobile required"}), 400

    db = get_db()
    cur = db.cursor()

    # ---------- EMAIL UPDATE ----------
    if email:
        if not re.match(EMAIL_REGEX, email):
            return jsonify({"message": "Invalid email"}), 400

        cur.execute("""
            UPDATE merchants
            SET email=%s, email_verified=1
            WHERE mobile=%s
        """, (email, mobile))

    # ---------- DOB UPDATE (DATE ONLY) ----------
    if dob:
        try:
            # Enforce strict yyyy-mm-dd
            clean_dob = datetime.strptime(dob, "%Y-%m-%d").date()

            cur.execute("""
                UPDATE merchants
                SET dob=%s
                WHERE mobile=%s AND dob IS NULL
            """, (clean_dob, mobile))

        except ValueError:
            return jsonify(
                {"message": "DOB must be in yyyy-mm-dd format"},
                400
            )

    db.commit()
    return jsonify({"message": "Updated"}), 200


# ================= KYC UPLOADS =================
# ========== Merchant KYC aadhar ==========
@app.route("/merchant/kyc/aadhaar", methods=["POST"])
def upload_aadhaar():
    mobile = request.form.get("mobile")
    aadhaar = request.form.get("aadhaar")
    front = request.files.get("front")
    back = request.files.get("back")

    if not all([mobile, aadhaar, front, back]):
        return jsonify({"message": "Incomplete Aadhaar data"}), 400

    os.makedirs("uploads/aadhaar", exist_ok=True)

    front_path = f"uploads/aadhaar/{mobile}_front_{secure_filename(front.filename)}"
    back_path = f"uploads/aadhaar/{mobile}_back_{secure_filename(back.filename)}"

    front.save(front_path)
    back.save(back_path)

    db = get_db()
    cur = db.cursor()
    cur.execute("""
        UPDATE merchants
        SET aadhaar=%s,
            aadhaar_front_path=%s,
            aadhaar_back_path=%s,
            aadhaar_verified=0,
            aadhaar_submitted_at=NOW()
        WHERE mobile=%s
    """, (aadhaar, front_path, back_path, mobile))
    db.commit()

    return jsonify({"message": "Aadhaar submitted"}), 200

# ========== Merchant KYC GST ============
@app.route("/merchant/kyc/gst", methods=["POST"])
def upload_gst():
    mobile = request.form.get("mobile")
    gst_number = request.form.get("gst_number")
    gst_doc = request.files.get("gst_doc")

    if not all([mobile, gst_number, gst_doc]):
        return jsonify({"message": "Incomplete GST data"}), 400

    os.makedirs("uploads/gst", exist_ok=True)
    gst_path = f"uploads/gst/{mobile}_{secure_filename(gst_doc.filename)}"
    gst_doc.save(gst_path)

    db = get_db()
    cur = db.cursor()
    cur.execute("""
        UPDATE merchants
        SET gst_number=%s,
            gst_doc_path=%s,
            gst_verified=0,
            gst_submitted_at=NOW()
        WHERE mobile=%s
    """, (gst_number, gst_path, mobile))
    db.commit()

    return jsonify({"message": "GST submitted"}), 200


# ================= ADMIN KYC =================

@app.route("/admin/kyc/pending", methods=["GET"])
def admin_pending_kyc():
    if not admin_guard():
        return jsonify({"message": "Unauthorized"}), 401

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("""
        SELECT
            id,
            merchant_name,
            mobile,
            aadhaar_verified,
            gst_verified
        FROM merchants
        WHERE aadhaar_verified = 0
           OR gst_verified = 0
    """)

    merchants = cur.fetchall()
    cur.close()

    return jsonify(merchants), 200


# -------- Wallet auto-activation helper --------
def _activate_wallet_if_ready(cur, merchant_id):
    """
    Activate wallet ONLY if all KYC & email are verified
    """
    cur.execute("""
        UPDATE merchants
        SET wallet_status = 'ACTIVE',
            wallet_created = 1
        WHERE id = %s
          AND email_verified = 1
          AND aadhaar_verified = 1
          AND gst_verified = 1
    """, (merchant_id,))


# -------- Aadhaar Verification --------
@app.route("/admin/verify/aadhaar", methods=["POST"])
def admin_verify_aadhaar():
    if not admin_guard():
        return jsonify({"message": "Unauthorized"}), 401

    data = request.json
    merchant_id = data.get("merchant_id")

    if not merchant_id:
        return jsonify({"message": "merchant_id is required"}), 400

    db = get_db()
    cur = db.cursor()

    # Mark Aadhaar verified
    cur.execute("""
        UPDATE merchants
        SET aadhaar_verified = 1
        WHERE id = %s
    """, (merchant_id,))

    # Try wallet activation
    _activate_wallet_if_ready(cur, merchant_id)

    db.commit()
    cur.close()

    return jsonify({"message": "Aadhaar verified successfully"}), 200


# -------- GST Verification --------
@app.route("/admin/verify/gst", methods=["POST"])
def admin_verify_gst():
    if not admin_guard():
        return jsonify({"message": "Unauthorized"}), 401

    data = request.json
    merchant_id = data.get("merchant_id")

    if not merchant_id:
        return jsonify({"message": "merchant_id is required"}), 400

    db = get_db()
    cur = db.cursor()

    # Mark GST verified
    cur.execute("""
        UPDATE merchants
        SET gst_verified = 1
        WHERE id = %s
    """, (merchant_id,))

    # Try wallet activation
    _activate_wallet_if_ready(cur, merchant_id)

    db.commit()
    cur.close()

    return jsonify({"message": "GST verified successfully"}), 200



# ================= WALLET =================
@app.route("/wallet/balance", methods=["POST"])
def wallet_balance():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("SELECT id, wallet_status FROM merchants WHERE mobile=%s", (mobile,))
    m = cur.fetchone()

    if not m or m["wallet_status"] != "ACTIVE":
        return jsonify({"balance": 0}), 200

    cur.execute("""
        SELECT IFNULL(SUM(
            CASE WHEN type='CREDIT' THEN amount ELSE -amount END
        ),0) AS balance
        FROM transactions WHERE merchant_id=%s AND status='SUCCESS'
    """, (m["id"],))

    return jsonify({"balance": float(cur.fetchone()["balance"])}), 200

# ========== Wallet Check Paymnt ===========
@app.route("/wallet/check-payment", methods=["GET"])
def check_wallet_payment():
    mobile = request.args.get("merchant_mobile")
    created_at = request.args.get("created_at")

    db = get_db()
    cur = db.cursor(dictionary=True)
    cur.execute("""
        SELECT status FROM transactions t
        JOIN merchants m ON m.id=t.merchant_id
        WHERE m.mobile=%s AND t.created_at >= %s
        ORDER BY t.created_at DESC LIMIT 1
    """, (mobile, created_at))

    r = cur.fetchone()
    return jsonify({"status": r["status"] if r else "PENDING"}), 200


# ================= WALLET PAY =================
@app.route("/merchant/wallet/pay", methods=["POST"])
def merchant_wallet_pay():
    d = request.json
    mobile = d.get("mobile")
    amount = float(d.get("amount"))
    pin = d.get("pin")
    receiver = d.get("receiver")

    db = get_db()
    cur = db.cursor(dictionary=True)

    # Fetch merchant
    cur.execute("""
        SELECT id, pin_hash, pin_attempts, wallet_status
        FROM merchants
        WHERE mobile=%s
    """, (mobile,))
    m = cur.fetchone()

    if not m or m["wallet_status"] != "ACTIVE":
        return jsonify({"status": "FAILED", "reason": "Wallet inactive"}), 403

    # PIN lock check
    if m.get("pin_attempts", 0) >= 3:
        return jsonify({"status": "FAILED", "reason": "PIN Locked"}), 403

    # PIN validation
    if not check_password_hash(m["pin_hash"], pin):
        cur.execute("""
            UPDATE merchants
            SET pin_attempts = pin_attempts + 1
            WHERE id = %s
        """, (m["id"],))
        db.commit()

        return jsonify({"status": "FAILED", "reason": "Invalid PIN"}), 403

    # Reset PIN attempts on success
    cur.execute("""
        UPDATE merchants
        SET pin_attempts = 0
        WHERE id = %s
    """, (m["id"],))

    # Check balance
    cur.execute("""
        SELECT IFNULL(SUM(
            CASE WHEN type='CREDIT' THEN amount ELSE -amount END
        ),0) AS balance
        FROM transactions
        WHERE merchant_id=%s AND status='SUCCESS'
    """, (m["id"],))

    if cur.fetchone()["balance"] < amount:
        db.commit()
        return jsonify({"status": "FAILED", "reason": "Insufficient balance"}), 403

    # Debit transaction
    _insert_txn(cur, m["id"], receiver, amount, "DEBIT", "SUCCESS")
    db.commit()

    return jsonify({"status": "SUCCESS"}), 200

# ============ wallet Transfer ===============

@app.route("/wallet/transfer", methods=["POST"])
def wallet_transfer():
    d = request.json
    sender_mobile = d.get("sender_mobile")
    receiver_input = d.get("receiver")
    amount = float(d.get("amount"))
    pin = d.get("pin")

    db = get_db()
    cur = db.cursor(dictionary=True)

    # -------- Fetch sender --------
    cur.execute("""
        SELECT id, pin_hash, pin_attempts, wallet_status
        FROM merchants WHERE mobile=%s
    """, (sender_mobile,))
    sender = cur.fetchone()

    if not sender or sender["wallet_status"] != "ACTIVE":
        return jsonify({"status": "FAILED", "reason": "Wallet inactive"}), 403

    # -------- PIN lock check --------
    if sender["pin_attempts"] >= 3:
        return jsonify({"status": "FAILED", "reason": "PIN Locked"}), 403

    # -------- PIN validation --------
    if not check_password_hash(sender["pin_hash"], pin):
        cur.execute("""
            UPDATE merchants
            SET pin_attempts = pin_attempts + 1
            WHERE id = %s
        """, (sender["id"],))
        db.commit()

        return jsonify({"status": "FAILED", "reason": "Invalid PIN"}), 403

    # Reset attempts on success
    cur.execute("""
        UPDATE merchants SET pin_attempts = 0 WHERE id=%s
    """, (sender["id"],))

    # -------- Resolve receiver --------
    cur.execute("""
        SELECT id, merchant_name
        FROM merchants
        WHERE mobile=%s OR upi_id=%s
    """, (receiver_input, receiver_input))
    receiver = cur.fetchone()

    if not receiver:
        return jsonify({"status": "FAILED", "reason": "Receiver not found"}), 404

    # -------- Check balance --------
    cur.execute("""
        SELECT IFNULL(SUM(
            CASE WHEN type='CREDIT' THEN amount ELSE -amount END
        ),0) AS balance
        FROM transactions
        WHERE merchant_id=%s AND status='SUCCESS'
    """, (sender["id"],))

    if cur.fetchone()["balance"] < amount:
        return jsonify({"status": "FAILED", "reason": "Insufficient balance"}), 403

    # -------- Perform transfer (atomic) --------
    reference = f"TXN_{uuid.uuid4().hex[:8]}"

    _insert_txn(cur, sender["id"], receiver["merchant_name"],
                amount, "DEBIT", "SUCCESS")
    _insert_txn(cur, receiver["id"], sender_mobile,
                amount, "CREDIT", "SUCCESS")

    db.commit()

    return jsonify({
        "status": "SUCCESS",
        "reference": reference
    }), 200



# ================= FILE SERVE =================
@app.route("/uploads/<path:filename>")
def serve_uploaded_file(filename):
    return send_from_directory("uploads", filename)



    
# ============ Merchant rewards =============
@app.route("/merchant/rewards/total", methods=["POST"])
def get_total_rewards():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify({"total_rewards": 0}), 200

    cur.execute("""
        SELECT IFNULL(SUM(amount),0) AS total
        FROM transactions
        WHERE merchant_id=%s
          AND type='CREDIT'
          AND status='SUCCESS'
          AND source='CASHBACK'
    """, (merchant["id"],))

    res = cur.fetchone()

    return jsonify({
        "total_rewards": float(res["total"])
    }), 200

@app.route("/merchant/rewards/history", methods=["POST"])
def rewards_history():
    mobile = request.json.get("mobile")

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id FROM merchants WHERE mobile=%s", (mobile,))
    merchant = cur.fetchone()
    if not merchant:
        return jsonify([]), 200

    cur.execute("""
        SELECT amount, created_at, payer_name
        FROM transactions
        WHERE merchant_id=%s
          AND type='CREDIT'
          AND status='SUCCESS'
          AND source='CASHBACK'
        ORDER BY created_at DESC
    """, (merchant["id"],))

    return jsonify(cur.fetchall()), 200

# ================= ADMIN LOGIN =================
@app.route("/admin/login", methods=["POST"])
def admin_login():
    data = request.json
    mobile = data.get("mobile")
    otp = data.get("otp")

    if not re.match(MOBILE_REGEX, mobile):
        return jsonify({"message": "Invalid mobile"}), 400

    if not verify_otp(mobile, otp):
        return jsonify({"message": "Invalid OTP"}), 401

    db = get_db()
    cur = db.cursor(dictionary=True)

    cur.execute("SELECT id, name FROM admins WHERE mobile=%s", (mobile,))
    admin = cur.fetchone()

    if not admin:
        return jsonify({"message": "Not an admin"}), 403

    # Generate token
    token = str(uuid.uuid4())

    cur.execute("""
        UPDATE admins
        SET token=%s
        WHERE id=%s
    """, (token, admin["id"]))

    db.commit()

    return jsonify({
        "message": "Admin login successful",
        "token": token,
        "admin_name": admin["name"]
    }), 200



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
