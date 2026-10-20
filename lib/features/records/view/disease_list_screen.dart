import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controller/records_controller.dart';
import 'disease_detail_screen.dart';
import 'add_disease_screen.dart';

class DiseaseListScreen extends GetView<RecordsController> {
  const DiseaseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text("Medical Records", style: AppTextStyles.poppinsBold24),
      ),
      body: Obx(() => ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.diseases.length,
            itemBuilder: (context, index) {
              final disease = controller.diseases[index];
              return Card(
                color: AppColors.primaryDeepBlue,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(
                    disease.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildBadge(disease.type, Colors.blue),
                          const SizedBox(width: 8),
                          _buildBadge(disease.status, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Diagnosed: ${disease.diagnosedDate.day} ${_getMonth(disease.diagnosedDate.month)} ${disease.diagnosedDate.year}",
                        style: const TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.accentTeal, size: 16),
                  onTap: () => Get.to(() => DiseaseDetailScreen(disease: disease)),
                ),
              );
            },
          )),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accentTeal,
        onPressed: () => Get.to(() => const AddDiseaseScreen()),
        child: const Icon(Icons.add, color: AppColors.primaryDeepBlue),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
