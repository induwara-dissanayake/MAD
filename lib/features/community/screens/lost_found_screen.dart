import 'package:flutter/material.dart';

class LostFoundScreen extends StatelessWidget {
  const LostFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> lostFoundItems = [
      {
        'type': 'Lost',
        'title': 'Lost Dog',
        'description': 'Brown dog missing',
        'location': 'Kaduwela',
        'date': 'Feb 20',
        'contact': '0771234567',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Lost & Found")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: lostFoundItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = lostFoundItems[index];

          return ListTile(
            title: Text(item['title']!),
            subtitle: Text(item['description']!),
          );
        },
      ),
    );
  }
}