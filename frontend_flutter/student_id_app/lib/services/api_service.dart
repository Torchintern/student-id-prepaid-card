import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';


class ApiService {
  static const String baseUrl = 'http://10.0.2.2:5000';
 static const Map<String, String> headers = {
    "Content-Type": "application/json",
  };
   // ================= INTERNAL POST HELPER =================
  static Future<Map<String, dynamic>> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception('POST $endpoint failed');
    }
  }


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
// check wallet payment
static Future<Map<String, dynamic>> checkWalletPayment({
  required String merchantMobile,
  required String createdAt,
}) async {
  try {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/wallet/check-payment'
        '?merchant_mobile=$merchantMobile'
        '&created_at=$createdAt',
      ),
    );

    if (res.statusCode != 200) {
      return {'status': 'PENDING'};
    }

    final decoded = jsonDecode(res.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {'status': 'PENDING'};
  } catch (e) {
   
    debugPrint('checkWalletPayment error: $e');
    return {'status': 'PENDING'};
  }
}


// ================= MERCHANT PAY (WALLET WITH PIN) =================
static Future<Map<String, dynamic>> merchantPay({
  required String mobile,
  required String receiver,
  required double amount,
  required String pin,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/merchant/wallet/pay'),
    headers: headers,
    body: jsonEncode({
      "mobile": mobile,
      "receiver": receiver,
      "amount": amount,
      "pin": pin,
    }),
  );

  return jsonDecode(res.body);
}


// ================= WALLET BALANCE =================
static Future<double> getWalletBalance(String mobile) async {
  final res = await http.post(
    Uri.parse('$baseUrl/wallet/balance'),
    headers: headers,
    body: jsonEncode({
      "mobile": mobile,
    }),
  );

  final data = jsonDecode(res.body);
  return (data['balance'] as num).toDouble();
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
//============= Business Insights Filter ===============
static Future<Map<String, dynamic>> getCustomInsights({
  required String mobile,
  required DateTime start,
  required DateTime end,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/merchant/insights/custom'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'mobile': mobile,
      'start': start.toIso8601String().substring(0, 10), // yyyy-mm-dd
      'end': end.toIso8601String().substring(0, 10),
    }),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception('Failed to fetch custom insights');
  }
}
// summary insights
static Future<Map<String, dynamic>> getYesterdaySummary(String mobile) =>
    _post('/merchant/summary/yesterday', {'mobile': mobile});

static Future<Map<String, dynamic>> getPrevWeekSummary(String mobile) =>
    _post('/merchant/summary/prev-week', {'mobile': mobile});

static Future<Map<String, dynamic>> getPrevMonthSummary(String mobile) =>
    _post('/merchant/summary/prev-month', {'mobile': mobile});


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

// ============== Merchant Info Update ===============
static Future<bool> updateMerchantInfo({
  required String mobile,
  String? email,
  String? dob,
}) async {
  final body = {
    "mobile": mobile,
  };

  if (email != null) body["email"] = email;

  if (dob != null) {
    // Enforce yyyy-mm-dd only
    body["dob"] = dob.split(' ').first;
  }

  final res = await http.post(
    Uri.parse("$baseUrl/merchant/update-info"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  return res.statusCode == 200;
}


// check qr payment status
static Future<String> checkQrPaymentStatus({
  required String mobile,
  required double amount,
}) async {
  final res = await http.get(
    Uri.parse(
      '$baseUrl/merchant/qr/status?mobile=$mobile&amount=$amount',
    ),
    headers: headers,
  );

  if (res.statusCode == 200) {
    final data = jsonDecode(res.body);
    return data['status']; // PENDING / SUCCESS
  }
  return 'PENDING';
}

// get Total rewards
static Future<double> getTotalRewards(String mobile) async {
  final uri = Uri.parse("$baseUrl/merchant/rewards/total");

  final res = await http.post(
    uri,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "mobile": mobile,
    }),
  );

  if (res.statusCode != 200) {
    throw Exception("Failed to load rewards");
  }

  final data = jsonDecode(res.body);
  return (data['total_rewards'] ?? 0).toDouble();
}

// get rewards history
static Future<List<dynamic>> getRewardsHistory(String mobile) async {
  final res = await http.post(
    Uri.parse('$baseUrl/merchant/rewards/history'),
    headers: headers,
    body: jsonEncode({'mobile': mobile}),
  );

  if (res.statusCode == 200) {
    return jsonDecode(res.body);
  }
  return [];
}
// upload gst
static Future<bool> uploadGst({
  required String mobile,
  required String gst,
  required File file,
}) async {
  try {
    final uri = Uri.parse("$baseUrl/merchant/kyc/gst");

    final request = http.MultipartRequest("POST", uri)
      ..fields["mobile"] = mobile
      ..fields["gst_number"] = gst
      ..files.add(
        await http.MultipartFile.fromPath(
          "gst_doc",
          file.path,
        ),
      );

    final response = await request.send();

    return response.statusCode == 200;
  } catch (e) {
    debugPrint("uploadGst error: $e");
    return false;
  }
}
// upload aadhar
static Future<bool> uploadAadhaar({
  required String mobile,
  required String aadhaar,
  required File front,
  required File back,
}) async {
  try {
    final uri = Uri.parse("$baseUrl/merchant/kyc/aadhaar");

    final request = http.MultipartRequest("POST", uri)
      ..fields["mobile"] = mobile
      ..fields["aadhaar"] = aadhaar
      ..files.add(
        await http.MultipartFile.fromPath(
          "front",
          front.path,
        ),
      )
      ..files.add(
        await http.MultipartFile.fromPath(
          "back",
          back.path,
        ),
      );

    final response = await request.send();

    return response.statusCode == 200;
  } catch (e) {
    debugPrint("uploadAadhaar error: $e");
    return false;
  }
}
// Wallet Transfer
static Future<Map<String, dynamic>> walletTransfer({
  required String senderMobile,
  required String receiver,
  required double amount,
  required String pin,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/wallet/transfer'),
    headers: headers,
    body: jsonEncode({
      "sender_mobile": senderMobile,
      "receiver": receiver,
      "amount": amount,
      "pin": pin,
    }),
  );

  return jsonDecode(res.body);
}



}
