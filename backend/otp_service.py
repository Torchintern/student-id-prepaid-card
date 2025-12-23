# In-memory OTP store (for prototype only)
otp_store = {}

def send_otp(mobile):
    otp = "123456"  # mock OTP
    otp_store[mobile] = otp
    print(f"[OTP] Mobile: {mobile}, OTP: {otp}")

def verify_otp(mobile, otp):
    return otp_store.get(mobile) == otp
