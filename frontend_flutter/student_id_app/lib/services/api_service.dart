import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  // ================= AUTH =================
  static Future<Map<String, dynamic>> sendOtpLogin(
      String mobile, String role) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'role': role}),
    );

    return {
      'success': res.statusCode == 200,
      'message': jsonDecode(res.body)['message'],
    };
  }

  static Future<bool> sendOtpRegister(String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-otp-register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> verifyOtp(String mobile, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'otp': otp}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> login(String mobile, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'otp': otp}),
    );
    return res.statusCode == 200;
  }

  // ================= REGISTRATION =================
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
    return {
      'success': res.statusCode == 200,
      'message': jsonDecode(res.body)['message'],
    };
  }

  static Future<Map<String, dynamic>> registerMerchant(
      String name,
      String company,
      String businessType,
      String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register/merchant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'merchant_name': name,
        'company_name': company,
        'business_type': businessType,
        'mobile': mobile,
      }),
    );
    return {
      'success': res.statusCode == 200,
      'message': jsonDecode(res.body)['message'],
    };
  }

  // ================= TRANSACTIONS =================
  static Future<List<dynamic>> getMerchantTransactions(
      String mobile) async {
    final res = await http.get(
      Uri.parse('$baseUrl/merchant/transactions/$mobile'),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }
}
