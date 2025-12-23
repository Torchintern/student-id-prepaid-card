import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  // 🔐 Login OTP (checks registration)
  static Future<Map<String, dynamic>> sendOtpLogin(
      String mobile, String role) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'role': role}),
    );

    return {
      'success': res.statusCode == 200,
      'body': jsonDecode(res.body),
    };
  }

  // 📝 Registration OTP (NO registration check)
  static Future<Map<String, dynamic>> sendOtpRegister(String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-otp-register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    return {
      'success': res.statusCode == 200,
      'body': jsonDecode(res.body),
    };
  }

  static Future<bool> verifyOtp(String mobile, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'otp': otp}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> registerStudent(
      String name, String? collegeId, String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register/student'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'college_id': collegeId,
        'mobile': mobile,
      }),
    );
    return res.statusCode == 200;
  }

  static Future<bool> registerMerchant(
      String merchant, String company, String tax, String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/register/merchant'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'merchant_name': merchant,
        'company_name': company,
        'tax_id': tax,
        'mobile': mobile,
      }),
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
}
