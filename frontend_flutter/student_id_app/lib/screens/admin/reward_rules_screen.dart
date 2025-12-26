import 'package:flutter/material.dart';

class RewardRulesScreen extends StatelessWidget {
  const RewardRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reward Rules')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Card(
              child: ListTile(
                leading: Icon(Icons.card_giftcard),
                title: Text('Cashback Rule'),
                subtitle: Text('5% cashback on canteen purchases'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.star),
                title: Text('Loyalty Points'),
                subtitle: Text('Earn 1 point for every ₹50 spent'),
              ),
            ),
            Card(
              child: ListTile(
                leading: Icon(Icons.school),
                title: Text('Student Bonus'),
                subtitle: Text('₹100 bonus on first transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
