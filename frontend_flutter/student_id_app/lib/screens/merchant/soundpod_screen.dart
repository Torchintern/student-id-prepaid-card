import 'package:flutter/material.dart';

class SoundPodScreen extends StatelessWidget {
  const SoundPodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SoundPod')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.volume_up, size: 80),
            SizedBox(height: 16),
            Text(
              'Payment sound notifications enabled',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
