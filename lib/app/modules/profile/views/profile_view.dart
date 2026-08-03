import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import 'package:healaura/app/core/Util/LogoutWidget.dart';
import 'package:healaura/app/data/services/storage_service.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/profile_controller.dart';
import 'emergency_info_view.dart';
import 'medical_info_view.dart';
import 'personal_info_view.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final controller = Get.put(ProfileController());
  final storage = StorageService();

  final RxBool _medReminders = true.obs;
  final RxBool _vacReminders = true.obs;
  final RxBool _qrAlerts = true.obs;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    controller.getPatientProfileAPI(context);
  }

  Future<void> _loadReminders() async {
    _medReminders.value = await storage.getBool(StorageService.medReminders);
    _vacReminders.value = await storage.getBool(StorageService.vacReminders);
    _qrAlerts.value = await storage.getBool(StorageService.qrAlerts);
  }

  void _toggleMed(bool val) {
    _medReminders.value = val;
    storage.setBool(StorageService.medReminders, val);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().showMedReminders.value = val;
    }
  }

  void _toggleVac(bool val) {
    _vacReminders.value = val;
    storage.setBool(StorageService.vacReminders, val);
    if (Get.isRegistered<HomeController>()) {
      Get.find<HomeController>().showVacReminders.value = val;
    }
  }

  void _toggleQR(bool val) {
    _qrAlerts.value = val;
    storage.setBool(StorageService.qrAlerts, val);
  }

  double _completeness() {
    var score = 0;
    const total = 8;
    if (controller.fullNameCtrl.text.trim().isNotEmpty) score++;
    if (controller.mobileNumber.value.trim().isNotEmpty) score++;
    if (controller.emailCtrl.text.trim().isNotEmpty) score++;
    if (controller.selectedGender.value.isNotEmpty) score++;
    if (controller.age.value > 0 || controller.selectedDob.value != null) {
      score++;
    }
    if (controller.bloodGroup.value.isNotEmpty) score++;
    if (controller.selectedAllergies.isNotEmpty) score++;
    if (controller.emergencyNameCtrl.text.trim().isNotEmpty) score++;
    return score / total;
  }

  String _formatName(String name) {
    return name
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) {
          if (w.length == 1) return w.toUpperCase();
          return w[0].toUpperCase() + w.substring(1);
        })
        .join(' ');
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty || clean == 'Complete your profile') return 'HA';
    final parts = clean.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF5F2),
      body: Obx(() {
        final loading = controller.isLoading.value;
        final allergies = controller.selectedAllergies.length;
        final rawName = controller.profileDisplayName.value.trim().isNotEmpty
            ? controller.profileDisplayName.value.trim()
            : controller.fullNameCtrl.text.trim();
        final name = rawName.isEmpty ? 'Complete your profile' : _formatName(rawName);
        final email = controller.emailCtrl.text.trim();
        final mobile = controller.mobileNumber.value.trim();
        final age = controller.age.value;
        final blood = controller.bloodGroup.value;
        final gender = controller.selectedGender.value;
        final progress = _completeness();
        final pct = (progress * 100).round();
        final firstName = rawName.isEmpty ? '' : _formatName(rawName.split(RegExp(r'\s+')).first);

        return RefreshIndicator(
          color: AppColors.teal,
          displacement: 36,
          onRefresh: () => controller.getPatientProfileAPI(context),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, top + 8, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBar(
                        firstName: firstName,
                        hasName: rawName.isNotEmpty,
                      )
                          .animate()
                          .fadeIn(duration: 320.ms)
                          .slideY(begin: -0.08, end: 0),
                      const SizedBox(height: 18),

                      // Premium member card
                      _MemberCard(
                        name: name,
                        initials: _initials(name),
                        photoUrl: controller.profilePhotoUrl.value,
                        mobile: mobile,
                        email: email,
                        age: age,
                        blood: blood,
                        gender: gender,
                        progress: progress,
                        percent: pct,
                        loading: loading,
                        onEdit: () async {
                          await Get.to(() => const PersonalInfoScreen(null));
                          if (context.mounted) {
                            await controller.getPatientProfileAPI(context);
                          }
                        },
                      )
                          .animate()
                          .fadeIn(delay: 60.ms, duration: 420.ms)
                          .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),

                      const SizedBox(height: 18),

                      // Identity shortcuts
                      _SectionLabel('Health identity'),
                      const SizedBox(height: 10),
                      _IdentityRow(
                        onPersonal: () =>
                            Get.to(() => const PersonalInfoScreen(null)),
                        onMedical: () =>
                            Get.to(() => const MedicalInfoScreen(null)),
                        onEmergency: () =>
                            Get.to(() => const EmergencyInfoScreen(null)),
                        allergyCount: allergies,
                        hasEmergency:
                            controller.emergencyNameCtrl.text.trim().isNotEmpty,
                      )
                          .animate()
                          .fadeIn(delay: 120.ms, duration: 380.ms),

                      const SizedBox(height: 22),
                      _SectionLabel('Care reminders'),
                      const SizedBox(height: 10),
                      _InsetGroup(
                        children: [
                          Obx(() => _SwitchTile(
                                icon: Icons.medication_liquid_rounded,
                                title: 'Medication reminders',
                                value: _medReminders.value,
                                activeColor: AppColors.orange,
                                onChanged: _toggleMed,
                              )),
                          Obx(() => _SwitchTile(
                                icon: Icons.vaccines_rounded,
                                title: 'Vaccination reminders',
                                value: _vacReminders.value,
                                activeColor: AppColors.teal,
                                onChanged: _toggleVac,
                                showDivider: true,
                              )),
                          Obx(() => _SwitchTile(
                                icon: Icons.qr_code_scanner_rounded,
                                title: 'QR scan alerts',
                                value: _qrAlerts.value,
                                activeColor: AppColors.accentBlue,
                                onChanged: _toggleQR,
                                showDivider: true,
                              )),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 160.ms, duration: 380.ms),

                      const SizedBox(height: 22),
                      _SectionLabel('Preferences'),
                      const SizedBox(height: 10),
                      _InsetGroup(
                        children: [
                          _LinkTile(
                            icon: Icons.verified_user_outlined,
                            title: 'Insurance details',
                            onTap: () {},
                          ),
                          _LinkTile(
                            icon: Icons.ios_share_rounded,
                            title: 'Export health records',
                            onTap: () {},
                            showDivider: true,
                          ),
                          _LinkTile(
                            icon: Icons.translate_rounded,
                            title: 'Language',
                            trailing: 'English',
                            onTap: () {},
                            showDivider: true,
                          ),
                          _LinkTile(
                            icon: Icons.lock_outline_rounded,
                            title: 'Privacy & security',
                            onTap: () {},
                            showDivider: true,
                          ),
                          _LinkTile(
                            icon: Icons.support_agent_rounded,
                            title: 'Help & support',
                            onTap: () {},
                            showDivider: true,
                          ),
                          _LinkTile(
                            icon: Icons.gavel_rounded,
                            title: 'Terms & privacy policy',
                            onTap: () {},
                            showDivider: true,
                          ),
                        ],
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 380.ms),

                      const SizedBox(height: 22),
                      _SectionLabel('Account'),
                      const SizedBox(height: 10),
                      _InsetGroup(
                        children: [
                          // _LinkTile(
                          //   icon: Icons.person_off_outlined,
                          //   title: 'Delete account',
                          //   danger: true,
                          //   onTap: () {},
                          // ),
                          _LinkTile(
                            icon: Icons.logout_rounded,
                            title: 'Sign out',
                            accent: AppColors.orange,
                            onTap: () => LogoutDialog.show(context),
                            showDivider: true,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),
                      Center(
                        child: Column(
                          children: [
                            Opacity(
                              opacity: 0.55,
                              child: Image.asset(
                                'assets/logo/ic_logo_icon.png',
                                width: 28,
                                height: 28,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'HealAura  ·  v1.0.0',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textGray.withValues(alpha: 0.8),
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String firstName;
  final bool hasName;
  const _TopBar({required this.firstName, required this.hasName});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ACCOUNT',
                style: TextStyle(
                  color: AppColors.teal.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasName && firstName.isNotEmpty ? 'Hi, $firstName' : 'My Profile',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading1.copyWith(
                  fontSize: 26,
                  color: AppColors.textDark,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Image.asset(
            'assets/logo/ic_logo_icon.png',
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: AppColors.textGray,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

// ─── Brand teal member card (same HealAura theme) ───────────────────────────

class _MemberCard extends StatelessWidget {
  final String name;
  final String initials;
  final String photoUrl;
  final String mobile;
  final String email;
  final int age;
  final String blood;
  final String gender;
  final double progress;
  final int percent;
  final bool loading;
  final VoidCallback onEdit;

  const _MemberCard({
    required this.name,
    required this.initials,
    required this.photoUrl,
    required this.mobile,
    required this.email,
    required this.age,
    required this.blood,
    required this.gender,
    required this.progress,
    required this.percent,
    required this.loading,
    required this.onEdit,
  });

  String get _contactLine {
    final parts = <String>[
      if (mobile.isNotEmpty) mobile,
      if (email.isNotEmpty) email,
    ];
    return parts.isEmpty ? 'Add your phone or email' : parts.join('  ·  ');
  }

  String? get _resolvedPhoto {
    var raw = photoUrl.trim();
    if (raw.isEmpty || raw.toLowerCase() == 'null') return null;
    if (raw.startsWith('//')) raw = 'http:$raw';
    if (raw.startsWith('/')) {
      raw = 'http://medconnect.airainnovations.com$raw';
    }
    return raw;
  }

  Widget _avatarFallback() {
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = _resolvedPhoto;
    final hasPhoto = photo != null && photo.isNotEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A5C45).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.45),
                      width: 2.5,
                    ),
                    image: hasPhoto
                        ? DecorationImage(
                            image: NetworkImage(photo),
                            fit: BoxFit.cover,
                            onError: (_, _) {},
                          )
                        : null,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasPhoto
                      ? Image.network(
                          photo,
                          key: ValueKey(photo),
                          fit: BoxFit.cover,
                          width: 86,
                          height: 86,
                          gaplessPlayback: true,
                          headers: const {'Accept': 'image/*'},
                          loadingBuilder: (_, child, progress) {
                            if (progress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, _, _) => loading
                              ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : _avatarFallback(),
                        )
                      : (loading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : _avatarFallback()),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onEdit();
                      },
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF0A5C45),
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _contactLine,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Profile strength',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '$percent%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress.clamp(0.04, 1.0),
                minHeight: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                valueColor: AlwaysStoppedAnimation(
                  percent >= 80
                      ? const Color(0xFF7DFFB3)
                      : const Color(0xFFFFD54F),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'Age',
                    value: age > 0 ? '$age yrs' : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCell(
                    label: 'Blood',
                    value: blood.isNotEmpty ? blood : '—',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _StatCell(
                    label: 'Gender',
                    value: gender.isNotEmpty
                        ? (gender.capitalizeFirst ?? gender)
                        : '—',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Identity shortcuts ─────────────────────────────────────────────────────

class _IdentityRow extends StatelessWidget {
  final VoidCallback onPersonal;
  final VoidCallback onMedical;
  final VoidCallback onEmergency;
  final int allergyCount;
  final bool hasEmergency;

  const _IdentityRow({
    required this.onPersonal,
    required this.onMedical,
    required this.onEmergency,
    required this.allergyCount,
    required this.hasEmergency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _IdentityCard(
          icon: Icons.person_outline_rounded,
          title: 'Personal information',
          subtitle: 'Name, date of birth, gender, nationality',
          color: AppColors.teal,
          onTap: onPersonal,
        ),
        const SizedBox(height: 8),
        _IdentityCard(
          icon: Icons.health_and_safety_outlined,
          title: 'Medical information',
          subtitle: allergyCount > 0
              ? '$allergyCount allerg${allergyCount == 1 ? 'y' : 'ies'} on file'
              : 'Blood group, allergies, conditions',
          color: AppColors.orange,
          onTap: onMedical,
        ),
        const SizedBox(height: 8),
        _IdentityCard(
          icon: Icons.contact_phone_outlined,
          title: 'Emergency contact',
          subtitle: hasEmergency
              ? 'Emergency contact saved'
              : 'Add someone we can reach in an emergency',
          color: AppColors.statusRed,
          onTap: onEmergency,
        ),
      ],
    );
  }
}

class _IdentityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _IdentityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.bodyBold),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppColors.textGray.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Inset groups ───────────────────────────────────────────────────────────

class _InsetGroup extends StatelessWidget {
  final List<Widget> children;
  const _InsetGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 14,
            color: AppColors.border.withValues(alpha: 0.65),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              Icon(icon, color: activeColor, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: AppTextStyles.bodyBold.copyWith(fontSize: 14)),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool danger;
  final Color? accent;
  final VoidCallback onTap;
  final bool showDivider;

  const _LinkTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.danger = false,
    this.accent,
    required this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.statusRed
        : (accent ?? AppColors.textMuted);

    return Column(
      children: [
        if (showDivider)
          Divider(
            height: 1,
            indent: 56,
            endIndent: 14,
            color: AppColors.border.withValues(alpha: 0.65),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.bodyBold.copyWith(
                        fontSize: 14,
                        color: danger ? AppColors.statusRed : AppColors.textDark,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    Text(
                      trailing!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: AppColors.textGray.withValues(alpha: 0.55),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
