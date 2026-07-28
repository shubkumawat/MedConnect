import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';
import '../controllers/family_member_controller.dart';
import 'add_family_member_screen.dart';
import 'family_member_detail_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  final controller = Get.put(FamilyMemberController());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.getFamilyMemberListAPI(context);
    });
  }

  @override
  Widget build(BuildContext context) {
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
        automaticallyImplyLeading: false,
        title: const Text(
          'My Patients',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.familyMemberList.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.teal));
        }

        return RefreshIndicator(
          onRefresh: () => controller.getFamilyMemberListAPI(context),
          color: AppColors.teal,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Family Members',
                          style: AppTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.bold, color: AppColors.black)),
                      Text('${controller.familyMemberList.length} Total',
                          style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (controller.familyMemberList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            Icon(Icons.people_outline_rounded,
                                size: 60, color: AppColors.textMuted.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            const Text("No family members found.",
                                style: TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ),
                    )
                  else
                    ...controller.familyMemberList.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FamilyMemberCard(
                            name: m.fullName ?? '',
                            relation: '${m.relation?.name ?? ''} · ${m.age ?? ''} yrs',
                            avatarColor: _getAvatarColor(m.relation?.name),
                            isActive: false,
                            onTap: () async {
                              controller.getFamilyMemberDetailAPI(context, m.patientId!);
                              await Get.to(() => const FamilyMemberDetailScreen());
                              controller.getFamilyMemberListAPI(context);
                            },
                          ),
                        )),

                  const SizedBox(height: 24),

                  // Add Button with Premium look
                  GestureDetector(
                    onTap: () async {
                      controller.clearFields();
                      await Get.to(() => const AddFamilyMemberScreen());
                      controller.getFamilyMemberListAPI(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.tealDark,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.teal.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'ADD NEW MEMBER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Color _getAvatarColor(String? relation) {
    switch (relation?.toLowerCase()) {
      case 'spouse':
        return AppColors.teal;
      case 'son':
      case 'daughter':
        return AppColors.orange;
      case 'father':
      case 'mother':
        return AppColors.green;
      default:
        return AppColors.teal;
    }
  }
}

class _AccessRow extends StatefulWidget {
  final String name;
  final bool hasAccess;
  const _AccessRow({required this.name, required this.hasAccess});

  @override
  State<_AccessRow> createState() => _AccessRowState();
}

class _AccessRowState extends State<_AccessRow> {
  late bool _access;

  @override
  void initState() {
    super.initState();
    _access = widget.hasAccess;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(widget.name,
              style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600, color: AppColors.teal)),
        ),
        GestureDetector(
          onTap: () => setState(() => _access = !_access),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _access ? AppColors.green.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _access ? AppColors.green : AppColors.border.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_access)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.check_circle_rounded, color: AppColors.green, size: 14),
                  ),
                Text(
                  _access ? 'Active' : 'Private',
                  style: TextStyle(
                    color: _access ? AppColors.green : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
