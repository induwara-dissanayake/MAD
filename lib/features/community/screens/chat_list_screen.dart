import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  final List<Map<String, String>> chats = const [
  {"name": "Village Group", "lastMsg": "Meeting at 5PM"},
  {"name": "Water Issue Team", "lastMsg": "Problem fixed"},
  {"name": "Garbage Team", "lastMsg": "Truck coming tomorrow"},
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chats")),
      body: ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, index) {
          final chat = chats[index];

          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.group)),
            title: Text(chat['name']!),
            subtitle: Text(chat['lastMsg']!),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(name: chat['name']!),
                ),
              );
            },
          );
        },
      ),
    );
  }
}