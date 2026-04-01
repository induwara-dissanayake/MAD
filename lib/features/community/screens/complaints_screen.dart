import 'package:flutter/material.dart';
import 'add_complaint_screen.dart';

class ComplaintsScreen extends StatefulWidget {
  const ComplaintsScreen({super.key});

  @override
  State<ComplaintsScreen> createState() => _ComplaintsScreenState();
}

class _ComplaintsScreenState extends State<ComplaintsScreen> {
  List<Map<String, dynamic>> complaints = [
    {
      "title": "Garbage Issue",
      "location": "Main Street",
      "votes": 12
    },
    {
      "title": "Broken Road",
      "location": "Temple Road",
      "votes": 8
    }
  ];

  void _vote(int index) {
    setState(() {
      complaints[index]['votes']++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complaints")),
      body: ListView.builder(
        itemCount: complaints.length,
        itemBuilder: (context, index) {
          final item = complaints[index];

          return Card(
            child: ListTile(
              title: Text(item['title']),
              subtitle: Text(item['location']),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item['votes'].toString()),
                  IconButton(
                    icon: const Icon(Icons.thumb_up),
                    onPressed: () => _vote(index),
                  )
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddComplaintScreen()),
          );
        },
      ),
    );
  }
}