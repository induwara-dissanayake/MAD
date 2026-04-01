import 'package:flutter/material.dart';

class AddComplaintScreen extends StatelessWidget {
  const AddComplaintScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Issue")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            TextField(decoration: InputDecoration(labelText: "Issue")),
            TextField(decoration: InputDecoration(labelText: "Location")),
          ],
        ),
      ),
    );
  }
}