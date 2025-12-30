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
// USED BY MY INFO SCREEN
static Future<bool> verifyOtpNamed({
  required String mobile,
  required String otp,
}) async {
  return verifyOtp(mobile, otp);
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

  // ================= MERCHANT TRANSACTIONS (OLD – KEEP) =================
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

  // ================= MERCHANT TRANSACTIONS (NEW – FILTERED) =================
  static Future<List<dynamic>> getMerchantTransactionsFiltered({
    required String mobile,
    required String filter, // today / week / month / all
    bool creditOnly = false,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/transactions/filter'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'filter': filter,
        'creditOnly': creditOnly,
      }),
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

  // ================= MERCHANT COLLECTION SUMMARY =================
  static Future<Map<String, dynamic>> getMerchantCollectionSummary(
      String mobile, String filter) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/collection-summary'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'filter': filter, // today / week / month
      }),
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

  // ================= PAY QR (CREDIT) =================
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

  // ================= BUSINESS INSIGHTS (TODAY) =================
  static Future<Map<String, dynamic>> getTodayInsights(
      String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/insights/today'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return {'data': {}, 'growth': 0};
  }

  // ================= BUSINESS INSIGHTS (MONTHLY) =================
  static Future<Map<String, dynamic>> getMonthlyInsights(
      String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/insights/monthly'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return {'data': {}, 'growth': 0};
  }
  // ================= MERCHANT MY INFO =================
  static Future<Map<String, dynamic>?> getMerchantMyInfo(
      String mobile) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/my-info'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'mobile': mobile}),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  // ================= SEND OTP =================
static Future<bool> sendOtp({
  required String mobile,
  required String role,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/send-otp'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "mobile": mobile,
      "role": role,
    }),
  );

  return response.statusCode == 200;
}

// merchant info
static Future<bool> updateMerchantInfo({
  required String mobile,
  String? email,
  String? aadhaar,
}) async {
  final res = await http.post(
    Uri.parse("$baseUrl/merchant/update-info"),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "mobile": mobile,
      if (email != null) "email": email,
      if (aadhaar != null) "aadhaar": aadhaar,
    }),
  );

  return res.statusCode == 200;
}
// ================= BANK (NEW DB-DRIVEN LOGIC) =================

  /// Static list of banks
  static Future<List<dynamic>> getBanks() async {
    final res = await http.get(Uri.parse('$baseUrl/banks/list'));
    return jsonDecode(res.body);
  }

  /// Check if merchant mobile is linked with selected bank
  static Future<Map<String, dynamic>> checkBankLinked({
    required String mobile,
    required String bankName,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bank/check-linked'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'bank_name': bankName,
      }),
    );

    return jsonDecode(res.body);
  }

  /// Add merchant bank account (after successful check)
  static Future<bool> addMerchantBank({
    required String mobile,
    required String bankName,
    required String accountNumber,
    required String ifscCode,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/merchant/bank/add'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'bank_name': bankName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
      }),
    );

    return res.statusCode == 200;
  }
  // check any bank linked
static Future<Map<String, dynamic>> checkAnyLinkedBank({
  required String mobile,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/merchant/bank/check-any'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'mobile': mobile}),
  );

  return jsonDecode(res.body);
}

// check balance 
static Future<Map<String, dynamic>> checkMerchantBalance({
  required String mobile,
  required String pin,
  required String bankName,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/merchant/bank/balance'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      "mobile": mobile,
      "pin": pin,
      "bank_name": bankName, 
    }),
  );

  return jsonDecode(res.body);
}

// ================= LIST MERCHANT BANK ACCOUNTS =================
static Future<List<dynamic>> listMerchantBanks({
  required String mobile,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/merchant/bank/list'),
    headers: const {'Content-Type': 'application/json'},
    body: jsonEncode({
      'mobile': mobile,
    }),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body) as List<dynamic>;
  } else {
    return [];
  }
}



}
