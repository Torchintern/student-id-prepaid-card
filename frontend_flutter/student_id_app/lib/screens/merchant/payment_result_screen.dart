import 'package:flutter/material.dart';

class PaymentResultScreen extends StatelessWidget {
  final bool success;
  final String title;
  final double amount;
  final String bankName;
  final String reference;
  final String actionLabel;

  const PaymentResultScreen({
    super.key,
    required this.success,
    required this.title,
    required this.amount,
    required this.bankName,
    required this.reference,
    required this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor =
        success ? Colors.greenAccent : Colors.redAccent;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text('Payment Status'),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027),
              Color(0xFF203A43),
              Color(0xFF2C5364),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// STATUS ICON
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.15),
                  ),
                  child: Icon(
                    success ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 90,
                  ),
                ),

                const SizedBox(height: 20),

                /// STATUS TITLE
                Text(
                  success ? 'Payment Successful' : 'Payment Failed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),

                const SizedBox(height: 30),

                /// DETAILS CARD
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      _row('Amount',
                          '₹${amount.toStringAsFixed(2)}'),
                      const Divider(color: Colors.white24),
                      _row('Bank', bankName),
                      const Divider(color: Colors.white24),
                      _row(actionLabel, reference),
                      const Divider(color: Colors.white24),
                      _row(
                        'Status',
                        success ? 'SUCCESS' : 'FAILED',
                        valueColor: statusColor,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// DONE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'DONE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
