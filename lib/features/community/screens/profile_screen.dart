import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 40),
            SizedBox(height: 10),
            Text("Name: Chathumi"),
            Text("Village: Kaduwela"),
            Text("Role: Member"),
          ],
        ),
      ),
    );
  }
}