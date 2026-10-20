import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';

class AddFamilyMemberScreen extends StatelessWidget {
  const AddFamilyMemberScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Family Member")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Center(
              child: Stack(
                children: [
                  CircleAvatar(radius: 50, backgroundColor: Colors.grey),
                  Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: AppColors.accentTeal, child: Icon(Icons.add, size: 20, color: Colors.white))),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const TextField(decoration: InputDecoration(labelText: "Full Name")),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Relationship"),
              items: ["Spouse", "Child", "Parent", "Sibling"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (val) {},
            ),
            const SizedBox(height: 20),
            const TextField(decoration: InputDecoration(labelText: "Mobile Number"), keyboardType: TextInputType.phone),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
                child: const Text("Add Member", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
