import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/core/theme/app_colors.dart';
import 'package:healaura/app/core/theme/app_text_theme.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomButton/CustomButton.dart';
import 'package:healaura/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import 'package:healaura/app/data/services/storage_service.dart';
import '../controllers/family_member_controller.dart';
import 'add_family_member_screen.dart';

class FamilyMemberDetailScreen extends StatelessWidget {
  const FamilyMemberDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FamilyMemberController>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.tealDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
            onPressed: () async {
              if (controller.familyMemberDetail.value != null) {
                /* final storage = StorageService();
                String accessType = await storage.getString(StorageService.accessType);
                if (accessType == "2") {
                  Get.snackbar(
                    "Access Restricted",
                    "You don't have permission to edit patient details.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                } */
                
                controller.isUpdateMode.value = true;
                controller.currentPatientId = controller.familyMemberDetail.value!.patientId;
                await Get.to(() => const AddFamilyMemberScreen());
                if (controller.currentPatientId != null) {
                  controller.getFamilyMemberDetailAPI(context, controller.currentPatientId!);
                  controller.getFamilyMemberListAPI(context);
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.redAccent, size: 26),
            onPressed: () async {
              if (controller.familyMemberDetail.value != null) {
                final storage = StorageService();
                String accessType = await storage.getString(StorageService.accessType);
                if (accessType == "2") {
                  Get.snackbar(
                    "Access Restricted",
                    "You don't have permission to delete patient details.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                  return;
                }
                _showDeleteConfirmation(context, controller);
              }
            },
          ),
          const SizedBox(width: 8),
        ],
        title: const Text(
          'Patient Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }

        final member = controller.familyMemberDetail.value;
        if (member == null) {
          return const Center(child: Text("No details available.", style: TextStyle(color: Colors.white)));
        }

        return RefreshIndicator(
          onRefresh: () async {
            await controller.getFamilyMemberDetailAPI(context, member.patientId!);
            await controller.getFamilyMemberListAPI(context);
          },
          color: AppColors.teal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  // Profile Header
                  McCard(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.teal.withOpacity(0.3), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.teal.withOpacity(0.1),
                            backgroundImage: (member.profilePhoto != null && member.profilePhoto!.isNotEmpty)
                                ? NetworkImage(member.profilePhoto!)
                                : null,
                            child: (member.profilePhoto == null || member.profilePhoto!.isEmpty)
                                ? const Icon(Icons.person, size: 40, color: AppColors.teal)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.fullName ?? '', 
                                style: AppTextStyles.heading2.copyWith(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.tealDark)),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Text(
                                  member.relation?.name ?? 'Family Member',
                                  style: AppTextStyles.tealLabel.copyWith(fontSize: 12),
                                ),
                              ),
                              if (member.mobileNumber != null && member.mobileNumber!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.phone_android_rounded, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 6),
                                    Text(
                                      member.mobileNumber!,
                                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Highlight Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMetricCard(Icons.cake_rounded, '${member.age ?? 'N/A'}', 'Age'),
                      _buildMetricCard(Icons.bloodtype_rounded, member.bloodGroup ?? 'N/A', 'Blood'),
                      _buildMetricCard(member.gender?.toLowerCase() == 'female' ? Icons.female_rounded : Icons.male_rounded, member.gender ?? 'N/A', 'Gender'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Information Sections
                  _buildInfoSection(
                    title: 'Basic Details',
                    icon: Icons.person_search_rounded,
                    children: [
                      _buildDetailItem(Icons.event_note_rounded, 'Date of Birth', member.dateOfBirth ?? 'N/A'),
                      _buildDetailItem(Icons.phone_android_rounded, 'Mobile Number',
                          (member.mobileNumber != null && member.mobileNumber!.isNotEmpty)
                              ? member.mobileNumber!
                              : 'N/A'),
                      _buildDetailItem(Icons.height_rounded, 'Height', '${member.height ?? 'N/A'} cm'),
                      _buildDetailItem(Icons.scale_rounded, 'Weight', '${member.weight ?? 'N/A'} kg'),
                      _buildDetailItem(Icons.language_rounded, 'Nationality', member.nationality?.name ?? 'N/A'),
                      _buildDetailItem(Icons.favorite_rounded, 'Marital Status', member.maritalStatus ?? 'N/A'),
                      _buildDetailItem(Icons.business_center_rounded, 'Occupation', member.occupation?.name ?? 'N/A'),
                      _buildDetailItem(Icons.location_on_rounded, 'Home Address', member.homeAddress ?? 'N/A'),
                    ],
                  ),

                  _buildInfoSection(
                    title: 'Medical Status',
                    icon: Icons.health_and_safety_rounded,
                    children: [
                      _buildDetailItem(Icons.coronavirus_rounded, 'Chronic Disease', member.medical?.chronicDisease == true ? 'Yes' : 'No'),
                      _buildDetailItem(Icons.accessible_forward_rounded, 'Handicapped', member.medical?.physicallyHandicapped == true ? 'Yes' : 'No'),
                      if (member.medical?.physicallyHandicapped == true)
                        _buildDetailItem(Icons.info_outline_rounded, 'Disability', member.medical?.disabilityType ?? 'N/A'),
                      _buildDetailItem(Icons.favorite_border_rounded, 'Organ Donor', member.medical?.organDonor == true ? 'Yes' : 'No'),
                      
                      const SizedBox(height: 20),
                      _buildTagsSection('Known Allergies', member.medical?.allergies?.map((e) => e.allergyName ?? '').toList() ?? [], AppColors.orange),
                      const SizedBox(height: 20),
                      _buildTagsSection('Current Medications', member.medical?.currentMedications ?? [], AppColors.teal),
                    ],
                  ),

                  _buildInfoSection(
                    title: 'Emergency Contact',
                    icon: Icons.emergency_share_rounded,
                    children: [
                      _buildDetailItem(Icons.person_pin_rounded, 'Name', member.emergencyContact?.contactName ?? 'N/A'),
                      _buildDetailItem(Icons.group_rounded, 'Relation', member.emergencyContact?.relation ?? 'N/A'),
                      _buildDetailItem(Icons.phone_iphone_rounded, 'Phone Number', member.emergencyContact?.phoneNumber ?? 'N/A'),
                    ],
                  ),

                  _buildInfoSection(
                    title: 'Insurance',
                    icon: Icons.shield_rounded,
                    children: [
                      _buildDetailItem(Icons.apartment_rounded, 'Provider', member.insurance?.provider ?? 'N/A'),
                      _buildDetailItem(Icons.receipt_long_rounded, 'Policy No.', member.insurance?.policyNumber ?? 'N/A'),
                      _buildDetailItem(Icons.date_range_rounded, 'Expiry', member.insurance?.expiryDate ?? 'N/A'),
                    ],
                  ),

                  const SizedBox(height: 12),
                  // Access Management Card
                  _buildAccessManagementCard(controller, member.fullName ?? 'Patient'),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAccessManagementCard(FamilyMemberController controller, String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border(
          left: BorderSide(color: AppColors.accentTeal, width: 4),
          top: BorderSide(color: AppColors.accentTeal, width: 4),
        ),
        boxShadow: [
          BoxShadow(color: AppColors.accentTeal.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.security_rounded, color: AppColors.accentTeal, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Access Management', style: AppTextStyles.heading3.copyWith(fontSize: 18, color: AppColors.tealDark)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Grant or revoke access for $name\'s medical records.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          Obx(() => _AccessToggleRow(
            label: 'Full Records Access',
            value: controller.fullAccess.value,
            onChanged: (v) => controller.updateAccessControl(Get.context!, true, v),
          )),
          const SizedBox(height: 12),
          Obx(() => _AccessToggleRow(
            label: 'Emergency Data Only',
            value: controller.emergencyOnly.value,
            onChanged: (v) => controller.updateAccessControl(Get.context!, false, v),
          )),
          const SizedBox(height: 24),
          CustomPrimaryButton(
            text: 'Give Full Access',
            onTap: () {
              if (controller.familyMemberDetail.value?.patientId != null) {
                controller.giveAccessAPI(Get.context!, controller.familyMemberDetail.value!.patientId!);
              }
            },
            color: AppColors.primary,
            height: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String value, String label) {
    return Container(
      width: (Get.width - 60) / 3,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border(
          left: BorderSide(color: AppColors.teal, width: 4),
          top: BorderSide(color: AppColors.teal, width: 4),
        ),
        boxShadow: [
          BoxShadow(color: AppColors.teal.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.teal.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.teal, size: 22),
          ),
          const SizedBox(height: 10),
          Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 16, color: AppColors.tealDark)),
          Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildInfoSection({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border(
          left: BorderSide(color: AppColors.teal, width: 4),
          top: BorderSide(color: AppColors.teal, width: 4),
        ),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 15)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.teal, size: 24),
              const SizedBox(width: 12),
              Text(title, style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.tealDark)),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.bgNavy),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted.withOpacity(0.5), size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.caption.copyWith(fontSize: 12, fontWeight: FontWeight.w500)),
                Text(value, style: AppTextStyles.bodyBold.copyWith(fontSize: 14, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection(String title, List<String> tags, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: themeColor)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.isEmpty
              ? [Text('None', style: AppTextStyles.caption)]
              : tags.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: themeColor.withOpacity(0.2)),
                    ),
                    child: Text(t, style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  )).toList(),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, FamilyMemberController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Patient?', style: AppTextStyles.heading3.copyWith(color: AppColors.tealDark)),
        content: Text(
          'Are you sure you want to remove this family member? This action cannot be undone.',
          style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () {
              Get.back();
              controller.deleteFamilyMember(
                context,
                controller.familyMemberDetail.value!.patientId!,
                () {
                  Get.back(); // Return to list screen
                },
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _AccessToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AccessToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.bodyBold.copyWith(fontSize: 14, color: AppColors.tealDark)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.teal,
          activeTrackColor: AppColors.teal.withOpacity(0.3),
        ),
      ],
    );
  }
}
