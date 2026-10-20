import 'package:flutter/material.dart';

class ReminderSettingsScreen extends StatelessWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reminder Settings")),
      body: ListView(
        children: [
          const ListTile(title: Text("Medication Reminders", style: TextStyle(fontWeight: FontWeight.bold))),
          SwitchListTile(title: const Text("Daily Dosage Alert"), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text("Refill Notifications"), value: true, onChanged: (v) {}),
          const Divider(),
          const ListTile(title: Text("Appointment Reminders", style: TextStyle(fontWeight: FontWeight.bold))),
          SwitchListTile(title: const Text("24 Hour Advance Alert"), value: true, onChanged: (v) {}),
          SwitchListTile(title: const Text("1 Hour Before Alert"), value: true, onChanged: (v) {}),
        ],
      ),
    );
  }
}
