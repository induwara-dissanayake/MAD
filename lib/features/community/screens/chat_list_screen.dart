import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  final List<Map<String, String>> chats = const [
    {'name': 'Village Group', 'lastMsg': 'General village discussion'},
    {'name': 'Water Issue Team', 'lastMsg': 'Coordinate water supply updates'},
    {'name': 'Garbage Team', 'lastMsg': 'Collection and cleanup updates'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community Chat')),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group)),
            title: Text(chat['name']!),
            subtitle: Text(chat['lastMsg']!),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push(
              '/community/chat',
              extra: <String, dynamic>{'name': chat['name']!},
            ),
          );
        },
      ),
    );
  }
}
