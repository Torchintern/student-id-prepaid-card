import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AllPaymentsScreen extends StatelessWidget {
  final String merchantMobile;

  const AllPaymentsScreen({
    super.key,
    required this.merchantMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Payments'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: ApiService.getMerchantTransactions(merchantMobile),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No payments found',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final transactions = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: transactions.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final txn = transactions[index];

              // ---------------- EXISTING DATA ----------------
              final String payerName =
                  txn['payer_name'] ?? 'Student';
              final String createdAt =
                  txn['created_at'].toString();
              final dynamic amount = txn['amount'];

              // ---------------- BACKEND DERIVED VALUES ----------------
              final String display =
                  txn['display'] ?? 'FAILED'; // Credited / Debited / FAILED
              final String status =
                  txn['status'] ?? 'FAILED'; // SUCCESS / FAILED / CANCELLED
              final String txnType =
                  txn['type'] ?? 'CREDIT'; // CREDIT / DEBIT

              // ---------------- UI DECISION ----------------
              final bool isSuccess = status == 'SUCCESS';
              final bool isCredit = txnType == 'CREDIT';

              IconData icon;
              Color color;
              String amountText;

              if (!isSuccess) {
                icon = Icons.cancel;
                color = Colors.red;
                amountText = '₹$amount';
              } else if (isCredit) {
                icon = Icons.arrow_downward;
                color = Colors.green;
                amountText = '+₹$amount';
              } else {
                icon = Icons.arrow_upward;
                color = Colors.red;
                amountText = '-₹$amount';
              }

              return ListTile(
                leading: Icon(icon, color: color),
                title: Text(
                  payerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(createdAt),
                    const SizedBox(height: 4),
                    Text(
                      display,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  amountText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
