// lib/models/merchant_model.dart
class Merchant {
  final String id;
  final String name;
  final String phone;  // For OTP verification
  final String gstNumber;
  final String companyName;
  final bool isApproved;

  Merchant({
    required this.id,
    required this.name,
    required this.phone,
    required this.gstNumber,
    required this.companyName,
    this.isApproved = false,
  });

  // Helper method to check if merchant exists (without exposing all data)
  static bool isApprovedMerchant(String phone) {
    final approvedPhones = _getApprovedMerchantPhones();
    return approvedPhones.contains(phone);
  }

  // Get merchant by phone (returns only name and ID for display)
  static Map<String, String>? getMerchantDetails(String phone) {
    final merchants = _getMerchantsFromSecureSource();
    final merchant = merchants.firstWhere(
      (m) => m.phone == phone && m.isApproved,
      orElse: () => Merchant(
        id: '',
        name: '',
        phone: '',
        gstNumber: '',
        companyName: '',
      ),
    );
    
    if (merchant.id.isNotEmpty) {
      return {
        'id': merchant.id,
        'name': merchant.name,
        'company': merchant.companyName,
      };
    }
    return null;
  }

  // PRIVATE method - credentials hidden
  static List<String> _getApprovedMerchantPhones() {
    // In production, this should come from encrypted storage or backend
    return [
      '9014919911', // Campus Canteen
      '9876543211', // Book Store  
      '9876543212', // Stationary Shop
    ];
  }

  // PRIVATE method - credentials hidden
  static List<Merchant> _getMerchantsFromSecureSource() {
    // In production, fetch from encrypted storage or backend API
    return [
      Merchant(
        id: 'M001',
        name: 'Campus Canteen',
        phone: '9876543210',
        gstNumber: '27ABCDE1234F1Z5',
        companyName: 'Campus Food Services',
        isApproved: true,
      ),
      Merchant(
        id: 'M002',
        name: 'Book Store',
        phone: '9876543211',
        gstNumber: '27XYZAB5678G2H9',
        companyName: 'Educational Books Pvt Ltd',
        isApproved: true,
      ),
      Merchant(
        id: 'M003',
        name: 'Stationary Shop',
        phone: '9876543212',
        gstNumber: '27PQRST9012J3K4',
        companyName: 'Write Right Stationary',
        isApproved: true,
      ),
    ];
  }
}