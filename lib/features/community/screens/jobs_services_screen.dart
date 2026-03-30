import 'package:flutter/material.dart';

class JobsServicesScreen extends StatelessWidget {
  const JobsServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> jobItems = [
      {
        'title': 'Part-time Sales Assistant',
        'company': 'Saman Grocery Store',
        'location': 'Kaduwela Town',
        'salary': 'LKR 25,000 - 30,000',
        'date': 'Feb 22',
        'contact': '077-2223344',
      },
      {
        'title': 'Tuk-Tuk Driver',
        'company': 'Nimal Fernando',
        'location': 'Malabe',
        'salary': 'Commission',
        'date': 'Feb 20',
        'contact': '071-5556677',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Jobs & Services")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: jobItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final job = jobItems[index];

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job['title']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(job['company']!),
                  const SizedBox(height: 6),
                  Text("📍 ${job['location']}"),
                  Text("💰 ${job['salary']}"),
                  Text("📅 ${job['date']}"),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text("Call ${job['contact']}"),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}