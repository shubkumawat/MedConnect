import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AccessControlScreen extends StatelessWidget {
  const AccessControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Access Control")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Who can view Jane Doe's records?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildAccessItem("John Doe (Me)", true),
          _buildAccessItem("Dr. Samantha Smith", true),
          _buildAccessItem("City General Hospital", false),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentTeal),
            child: const Text("Add Provider Access", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessItem(String name, bool hasAccess) {
    return ListTile(
      title: Text(name),
      trailing: Switch(value: hasAccess, onChanged: (v) {}),
    );
  }
}
