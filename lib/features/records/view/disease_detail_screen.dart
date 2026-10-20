import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../model/disease_model.dart';
import '../controller/records_controller.dart';

class DiseaseDetailScreen extends StatelessWidget {
  final DiseaseModel? disease;
  const DiseaseDetailScreen({super.key, this.disease});

  @override
  Widget build(BuildContext context) {
    final DiseaseModel selectedDisease = disease ?? Get.arguments;
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppColors.primaryDeepBlue,
          title: Text(selectedDisease.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: AppColors.accentTeal,
            labelColor: AppColors.accentTeal,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "Overview"),
              Tab(text: "Visits & Doctors"),
              Tab(text: "Medications"),
              Tab(text: "Prescriptions"),
              Tab(text: "Receipts"),
              Tab(text: "Timeline"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(disease: selectedDisease),
            _VisitsTab(disease: selectedDisease),
            _MedicationsTab(disease: selectedDisease),
            _DummyPlaceholderTab(title: "Prescriptions"),
            _DummyPlaceholderTab(title: "Receipts"),
            _TimelineTab(disease: selectedDisease),
          ],
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final DiseaseModel disease;
  const _OverviewTab({required this.disease});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard("Basic Info", [
            _buildInfoRow("Type", disease.type),
            _buildInfoRow("Status", disease.status),
            _buildInfoRow("Diagnosed", "${disease.diagnosedDate.day}/${disease.diagnosedDate.month}/${disease.diagnosedDate.year}"),
            _buildInfoRow("Body Part", disease.bodyPart),
          ]),
          const SizedBox(height: 20),
          _buildInfoCard("Details", [
            _buildInfoRow("Severity", "${(disease.severity * 100).toInt()}%"),
            _buildInfoRow("Hereditary", disease.hereditary ? "Yes" : "No"),
            _buildInfoRow("Hospitalization", disease.hospitalizationRequired ? "Required" : "Not Required"),
          ]),
          const SizedBox(height: 20),
          Text("Symptoms", style: AppTextStyles.poppinsMedium16),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: disease.symptoms.map((s) => Chip(
              label: Text(s, style: const TextStyle(color: Colors.white, fontSize: 12)),
              backgroundColor: AppColors.primaryDeepBlue,
              side: const BorderSide(color: AppColors.accentTeal),
            )).toList(),
          ),
          const SizedBox(height: 20),
          Text("Notes", style: AppTextStyles.poppinsMedium16),
          const SizedBox(height: 8),
          Text(disease.notes.isEmpty ? "No notes available." : disease.notes, 
               style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDeepBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.poppinsBold18.copyWith(color: AppColors.accentTeal, fontSize: 16)),
          const Divider(color: Colors.white10, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _VisitsTab extends StatelessWidget {
  final DiseaseModel disease;
  const _VisitsTab({required this.disease});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 2, // Dummy count
      itemBuilder: (context, index) {
        return Card(
          color: AppColors.primaryDeepBlue,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text("Dr. Sarah Smith", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("City Hospital - 12 Jan 2024\nFollow-up consultation", style: const TextStyle(color: Colors.white60)),
            trailing: const Icon(Icons.info_outline, color: AppColors.accentTeal),
          ),
        );
      },
    );
  }
}

class _MedicationsTab extends GetView<RecordsController> {
  final DiseaseModel disease;
  const _MedicationsTab({required this.disease});

  @override
  Widget build(BuildContext context) {
    final meds = controller.getMedicationsForDisease(disease.id);
    if (meds.isEmpty) return const Center(child: Text("No medications linked", style: TextStyle(color: Colors.white60)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meds.length,
      itemBuilder: (context, index) {
        final med = meds[index];
        return Card(
          color: AppColors.primaryDeepBlue,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: AppColors.accentTeal, child: Icon(Icons.medication, color: AppColors.primaryDeepBlue)),
            title: Text(med.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("${med.dosage}${med.unit} - ${med.frequency}", style: const TextStyle(color: Colors.white60)),
            trailing: Text(med.timing, style: const TextStyle(color: AppColors.accentTeal, fontSize: 12)),
          ),
        );
      },
    );
  }
}

class _TimelineTab extends StatelessWidget {
  final DiseaseModel disease;
  const _TimelineTab({required this.disease});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildTimelineItem("Diagnosed", "12 Oct 2023", "Condition confirmed by Dr. Sharma", Icons.check_circle, Colors.green),
        _buildTimelineItem("Medication Added", "15 Oct 2023", "Started Amlodipine 5mg", Icons.add_circle, Colors.blue),
        _buildTimelineItem("Doctor Visit", "20 Dec 2023", "Routine checkup at Apollo Clinic", Icons.local_hospital, Colors.orange),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String date, String desc, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            Container(width: 2, height: 50, color: Colors.white10),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date, style: const TextStyle(color: Colors.white60, fontSize: 12)),
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}

class _DummyPlaceholderTab extends StatelessWidget {
  final String title;
  const _DummyPlaceholderTab({required this.title});
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("No $title found", style: const TextStyle(color: Colors.white60)));
  }
}
