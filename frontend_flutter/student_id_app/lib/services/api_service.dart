import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000";

  static Future<bool> sendRegisterOtp(String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-register-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> verifyRegisterOtp(
      String name, String mobile, String otp, String role) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-register-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'mobile': mobile,
        'otp': otp,
        'role': role
      }),
    );
    return res.statusCode == 201;
  }

  static Future<bool> sendLoginOtp(String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/send-login-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );
    return res.statusCode == 200;
  }

  static Future<bool> verifyLoginOtp(String mobile, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verify-login-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile, 'otp': otp}),
    );
    return res.statusCode == 200;
  }
}
