import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RewardsHistoryScreen extends StatefulWidget {
  final String mobile;

  const RewardsHistoryScreen({
    super.key,
    required this.mobile,
  });

  @override
  State<RewardsHistoryScreen> createState() =>
      _RewardsHistoryScreenState();
}

class _RewardsHistoryScreenState extends State<RewardsHistoryScreen> {
  bool _loading = true;
  List rewards = [];

  @override
  void initState() {
    super.initState();
    _loadRewards();
  }

  Future<void> _loadRewards() async {
    try {
      final data = await ApiService.getRewardsHistory(widget.mobile);
      setState(() {
        rewards = data;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        rewards = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Rewards History'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : rewards.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                  onRefresh: _loadRewards,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: rewards.length,
                    itemBuilder: (_, index) {
                      final r = rewards[index];
                      return _rewardCard(r);
                    },
                  ),
                ),
    );
  }

  /// 🎁 SINGLE REWARD CARD
  Widget _rewardCard(Map reward) {
    final amount = reward['amount'] ?? 0;
    final title = reward['payer_name'] ?? 'Cashback Reward';
    final date =
        reward['created_at'].toString().substring(0, 10);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.card_giftcard,
            color: Colors.amber,
            size: 26,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            date,
            style: const TextStyle(color: Colors.grey),
          ),
        ),
        trailing: Text(
          '+ ₹$amount',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  /// 📭 EMPTY STATE
  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.card_giftcard,
              size: 64,
              color: Colors.amber,
            ),
            SizedBox(height: 16),
            Text(
              'No Rewards Yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Earn cashback rewards by making transactions.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
