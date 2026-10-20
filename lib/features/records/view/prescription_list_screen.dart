import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrescriptionListScreen extends StatelessWidget {
  const PrescriptionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Prescriptions")),
      body: ListView.builder(
        itemCount: 2,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.description, color: AppColors.accentTeal),
              title: Text(index == 0 ? "Dr. Smith - 12 Oct 2023" : "Dr. Wilson - 05 Jan 2022"),
              subtitle: const Text("2 Medications • PDF"),
              trailing: IconButton(icon: const Icon(Icons.download, color: AppColors.primaryDeepBlue), onPressed: () {}),
            ),
          );
        },
      ),
    );
  }
}
