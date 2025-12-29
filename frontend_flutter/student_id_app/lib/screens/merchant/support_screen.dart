import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  SupportScreen({super.key});

  // 📞 Call Support (Open Dialer)
  Future<void> _callSupport() async {
    final Uri uri = Uri.parse('tel:+919876543210');
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not open dialer';
    }
  }

  // 📧 Email Support (Open Mail App)
  Future<void> _emailSupport() async {
    final Uri uri = Uri.parse(
      'mailto:support@studentid.com?subject=Support%20Request',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not open mail app';
    }
  }

  // 🤖 Open Chat Bot
  void _openChatBot(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatBotScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat with Us'),
              subtitle: const Text('Instant help'),
              onTap: () => _openChatBot(context),
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.call),
              title: const Text('Call Support'),
              onTap: _callSupport,
            ),
            const Divider(),

            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Support'),
              onTap: _emailSupport,
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= CHAT BOT WITH FAQ =================
class ChatBotScreen extends StatefulWidget {
  ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<Map<String, String>> _messages = [
    {'bot': 'Hi 👋 How can I help you today?'}
  ];

  final List<String> _faqSuggestions = [
    'How to register?',
    'How to reset PIN?',
    'Payment failed, what to do?',
    'How to contact support?',
  ];

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'user': text});

      if (text.toLowerCase().contains('register')) {
        _messages.add({
          'bot':
              'You can register from the Login screen by selecting your role.'
        });
      } else if (text.toLowerCase().contains('pin')) {
        _messages.add({
          'bot':
              'You can reset your PIN from Profile → Change PIN after OTP verification.'
        });
      } else if (text.toLowerCase().contains('payment')) {
        _messages.add({
          'bot':
              'If payment failed, retry or contact support via Call or Email.'
        });
      } else {
        _messages.add({
          'bot':
              'Thanks for your message. Our support team will assist you shortly.'
        });
      }
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Support')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg.containsKey('user');

                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Colors.blueAccent
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isUser ? msg['user']! : msg['bot']!,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // FAQ Suggestions
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _faqSuggestions.map((q) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ActionChip(
                    label: Text(q),
                    onPressed: () => _sendMessage(q),
                  ),
                );
              }).toList(),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendMessage(_controller.text),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
