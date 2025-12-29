import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/payment_filter.dart';

class AllPaymentsScreen extends StatefulWidget {
  final String merchantMobile;
  final PaymentFilter filter;
  final bool creditOnly;

  const AllPaymentsScreen({
    super.key,
    required this.merchantMobile,
    this.filter = PaymentFilter.all,
    this.creditOnly = false,
  });

  @override
  State<AllPaymentsScreen> createState() => _AllPaymentsScreenState();
}

class _AllPaymentsScreenState extends State<AllPaymentsScreen> {
  String _searchQuery = '';

  // ================= TITLE =================
  String _titleText() {
    switch (widget.filter) {
      case PaymentFilter.today:
        return 'Today Payments';
      case PaymentFilter.week:
        return 'Weekly Payments';
      case PaymentFilter.month:
        return 'Monthly Payments';
      case PaymentFilter.all:
        return 'All Payments';
    }
  }

  // ================= SEARCH =================
  bool _matchesSearch(Map txn) {
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();

    return (txn['payer_name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(q) ||
        (txn['amount'] ?? '').toString().contains(q) ||
        (txn['type'] ?? '')
            .toString()
            .toLowerCase()
            .contains(q);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titleText()),
      ),
      body: Column(
        children: [
          // ================= SEARCH BAR =================
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name, amount or type',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          // ================= TRANSACTIONS =================
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: ApiService.getMerchantTransactionsFiltered(
                mobile: widget.merchantMobile,
                filter: widget.filter.name, // today / week / month / all
                creditOnly: widget.creditOnly,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text(
                      'No payments found',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                final filteredTxns = snapshot.data!
                    .where((txn) => _matchesSearch(txn))
                    .toList();

                if (filteredTxns.isEmpty) {
                  return const Center(
                    child: Text(
                      'No payments found for this period',
                      style: TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTxns.length,
                  separatorBuilder: (_, __) =>
                      const Divider(),
                  itemBuilder: (context, index) {
                    final txn = filteredTxns[index];

                    final payerName =
                        txn['payer_name'] ?? 'Customer';
                    final amount = txn['amount'] ?? 0;
                    final status = (txn['status'] ?? '')
                        .toString()
                        .toUpperCase();
                    final type = (txn['type'] ?? '')
                        .toString()
                        .toUpperCase();
                    final createdAt =
                        txn['created_at']?.toString() ?? '';

                    final bool success =
                        status == 'SUCCESS';

                    return ListTile(
                      leading: Icon(
                        type == 'CREDIT'
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: success
                            ? (type == 'CREDIT'
                                ? Colors.green
                                : Colors.red)
                            : Colors.grey,
                      ),
                      title: Text(
                        payerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(createdAt),
                      trailing: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.end,
                        children: [
                          Text(
                            type == 'CREDIT'
                                ? '+₹$amount'
                                : '-₹$amount',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: type == 'CREDIT'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            success ? 'SUCCESS' : 'FAILED',
                            style: TextStyle(
                              fontSize: 12,
                              color: success
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
