import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SettlementStatusScreen extends StatefulWidget {
  final String merchantMobile;

  const SettlementStatusScreen({
    Key? key,
    required this.merchantMobile,
  }) : super(key: key);

  @override
  State<SettlementStatusScreen> createState() =>
      _SettlementStatusScreenState();
}

class _SettlementStatusScreenState extends State<SettlementStatusScreen> {
  bool loading = true;

  double totalCredit = 0;
  double totalDebit = 0;
  double walletBalance = 0;

  List transactions = [];

  String selectedFilter = 'all'; // all | today | week | month

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  double _parseAmount(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _loadData() async {
    setState(() => loading = true);

    try {
      final txns = await ApiService.getMerchantTransactionsFiltered(
        mobile: widget.merchantMobile,
        filter: selectedFilter,
        creditOnly: false,
      );

      double credit = 0;
      double debit = 0;

      for (var t in txns) {
        if (t['status'] == 'SUCCESS') {
          final amount = _parseAmount(t['amount']);
          if (t['type'] == 'CREDIT') {
            credit += amount;
          } else if (t['type'] == 'DEBIT') {
            debit += amount;
          }
        }
      }

      setState(() {
        transactions =
            txns.where((t) => t['status'] == 'SUCCESS').toList();
        totalCredit = credit;
        totalDebit = debit;
        walletBalance = credit - debit;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Wallet Settlement"),
      ),
      body: Column(
        children: [
          _filterTabs(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _summaryCard(),
                        const SizedBox(height: 16),
                        _walletBreakdown(),
                        const SizedBox(height: 16),
                        _transactionList(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// ================= FILTER =================
  Widget _filterTabs() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _filterChip('All', 'all'),
          _filterChip('Today', 'today'),
          _filterChip('Week', 'week'),
          _filterChip('Month', 'month'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedFilter == value,
      onSelected: (_) {
        if (selectedFilter != value) {
          setState(() => selectedFilter = value);
          _loadData();
        }
      },
    );
  }

  /// ================= SUMMARY =================
  Widget _summaryCard() {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet),
        title: const Text("Wallet Balance"),
        subtitle: Text("₹ ${walletBalance.toStringAsFixed(2)}"),
      ),
    );
  }

  Widget _walletBreakdown() {
    return Card(
      child: Column(
        children: [
          ListTile(
            title: const Text("Total Credits"),
            trailing: Text(
              "₹ ${totalCredit.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.green),
            ),
          ),
          ListTile(
            title: const Text("Total Debits"),
            trailing: Text(
              "₹ ${totalDebit.toStringAsFixed(2)}",
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// ================= TRANSACTIONS =================
  Widget _transactionList() {
    return Card(
      child: Column(
        children: [
          const ListTile(title: Text("Transaction History")),
          const Divider(),
          if (transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("No transactions found"),
            ),
          ...transactions.map((t) {
            return ListTile(
              leading: Icon(
                t['type'] == 'CREDIT'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: t['type'] == 'CREDIT'
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text(t['payer_name'] ?? 'N/A'),
              subtitle: Text(t['created_at'] ?? ''),
              trailing: Text(
                "₹ ${_parseAmount(t['amount']).toStringAsFixed(2)}",
                style: TextStyle(
                  color: t['type'] == 'CREDIT'
                      ? Colors.green
                      : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
