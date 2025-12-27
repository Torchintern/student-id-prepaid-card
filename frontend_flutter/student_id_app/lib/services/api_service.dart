import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  // ================= SEND OTP (LOGIN) =================
  static Future<Map<String, dynamic>> sendOtpLogin(
      String mobile, String role) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'role': role,
      }),
    );

    final body = jsonDecode(res.body);

    return {
      'success': res.statusCode == 200,
      'message': body['message'],
    };
  }

  // ================= SEND OTP (REGISTER) =================
  static Future<bool> sendOtpRegister(String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-otp-register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );
    return res.statusCode == 200;
  }

  // ================= VERIFY OTP =================
  static Future<bool> verifyOtp(String mobile, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'otp': otp,
      }),
    );
    return res.statusCode == 200;
  }

  // ================= LOGIN =================
  static Future<bool> login(String mobile, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'otp': otp,
      }),
    );
    return res.statusCode == 200;
  }

  // ================= STUDENT REGISTRATION =================
  static Future<Map<String, dynamic>> registerStudent(
      String name, String email, String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register/student'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'mobile': mobile,
      }),
    );

    final body = jsonDecode(res.body);

    return {
      'success': res.statusCode == 200,
      'message': body['message'],
    };
  }

  // ================= MERCHANT REGISTRATION =================
  static Future<Map<String, dynamic>> registerMerchant(
      String merchantName,
      String companyName,
      String businessType,
      String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register/merchant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'merchant_name': merchantName,
        'company_name': companyName,
        'business_type': businessType,
        'mobile': mobile,
      }),
    );

    final body = jsonDecode(res.body);

    return {
      'success': res.statusCode == 200,
      'message': body['message'],
    };
  }

  // ================= MERCHANT PROFILE =================
  static Future<Map<String, dynamic>?> getMerchantProfile(
      String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ================= CHANGE MERCHANT PIN =================
  static Future<Map<String, dynamic>> changeMerchantPin({
    required String mobile,
    required String otp,
    required String newPin,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/change-pin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'otp': otp,
        'pin': newPin,
      }),
    );

    final body = jsonDecode(res.body);

    return {
      'success': res.statusCode == 200,
      'message': body['message'],
    };
  }

  // ================= MERCHANT PAY (DEBIT WITH PIN) =================
  static Future<Map<String, dynamic>> merchantPay({
    required String mobile,
    required String receiver,
    required double amount,
    required String pin,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/pay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'receiver': receiver,
        'amount': amount,
        'pin': pin,
      }),
    );

    final body = jsonDecode(res.body);

    return {
      'success': res.statusCode == 200,
      'message': body['message'],
    };
  }

  // ================= MERCHANT TRANSACTIONS =================
  static Future<List<dynamic>> getMerchantTransactions(
      String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    return [];
  }

  // ================= MERCHANT DAILY SUMMARY =================
  static Future<Map<String, dynamic>> getMerchantDailySummary(
      String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/daily-summary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return {'total': 0, 'count': 0};
  }

  // ================= CREATE QR =================
  static Future<int?> createQr(String mobile, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/qr/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'amount': amount,
      }),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body)['qr_id'];
    }
    return null;
  }

  // ================= CANCEL QR =================
  static Future<bool> cancelQr(int qrId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/qr/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'qr_id': qrId}),
    );

    return res.statusCode == 200;
  }

  // ================= PAY QR (CUSTOMER → MERCHANT CREDIT) =================
  static Future<Map<String, dynamic>> payQr({
    required int qrId,
    required String payerName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/qr/pay'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'qr_id': qrId,
        'payer_name': payerName,
      }),
    );

    final body = jsonDecode(res.body);

    return {
      'success': res.statusCode == 200,
      'message': body['message'],
    };
  }
}
