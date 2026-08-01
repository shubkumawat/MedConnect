import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/data/models/medical_record_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/records_controller.dart';
import 'add_medication_screen.dart';

class MedicationDetailScreen extends StatefulWidget {
  final String medicationUuid;

  const MedicationDetailScreen({super.key, required this.medicationUuid});

  @override
  State<MedicationDetailScreen> createState() =>
      _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  final RecordsController controller = Get.find<RecordsController>();
  Medication? _med;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final med = await controller.fetchMedicationDetail(widget.medicationUuid);
    if (!mounted) return;
    setState(() {
      _med = med ?? controller.selectedMedication.value;
      _loading = false;
    });
  }

  Future<void> _openEdit() async {
    final med = _med;
    if (med == null) return;
    await Get.to(() => AddMedicationScreen(
          medication: med,
          isCurrentMedication: true,
        ));
    // Always refresh after returning from edit/add screen.
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final med = _med;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Column(
        children: [
          _Header(
            topPad: top,
            medName: med?.name,
            onBack: () => Get.back(),
            onEdit: med == null ? null : _openEdit,
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  )
                : med == null
                    ? _EmptyState(onBack: () => Get.back(), onRetry: _load)
                    : RefreshIndicator(
                        color: AppColors.teal,
                        onRefresh: _load,
                        child: _Body(med: med),
                      ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPad;
  final String? medName;
  final VoidCallback onBack;
  final VoidCallback? onEdit;

  const _Header({
    required this.topPad,
    required this.medName,
    required this.onBack,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 14, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0A5C45), Color(0xFF147A68), Color(0xFF1B9E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Row(
        children: [
          _IconBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              'assets/logo/ic_logo_icon.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medication Detail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  (medName != null && medName!.trim().isNotEmpty)
                      ? medName!
                      : 'Medicine information',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 8),
            _IconBtn(icon: Icons.edit_outlined, onTap: onEdit!),
          ],
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Medication med;
  const _Body({required this.med});

  String _foodLabel(String? value) {
    if (value == null || value.trim().isEmpty) return '—';
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final name = med.name.isNotEmpty ? med.name : 'Medication';
    final statusColor =
        med.isActive ? AppColors.statusResolved : AppColors.textGray;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE3EBE7)),
            boxShadow: [
              BoxShadow(
                color: AppColors.tealDark.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: AppColors.tealDark,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppColors.textDark,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (med.strength != null && med.strength!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        med.strength!,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textGray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Badge(
                          label: med.isActive ? 'ACTIVE' : 'INACTIVE',
                          color: statusColor,
                        ),
                        if (med.isOngoing)
                          const _Badge(
                            label: 'ONGOING',
                            color: AppColors.tealDark,
                            soft: true,
                          ),
                        if (med.diseaseName.isNotEmpty)
                          _Badge(
                            label: med.diseaseName.toUpperCase(),
                            color: AppColors.orange,
                            soft: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Dosage schedule',
          icon: Icons.schedule_outlined,
          child: _InfoGrid(
            items: [
              _InfoItem('Dosage', _v(med.dosage)),
              _InfoItem('Frequency', _v(med.frequencyDisplay)),
              _InfoItem(
                'Timing',
                med.timing.isNotEmpty ? med.timing : '—',
              ),
              _InfoItem('With food', _foodLabel(med.withFood)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Duration',
          icon: Icons.event_available_outlined,
          child: _InfoGrid(
            items: [
              _InfoItem('Start date', _v(med.startDate)),
              _InfoItem(
                'End date',
                med.isOngoing
                    ? 'Ongoing'
                    : (med.endDate?.isNotEmpty == true ? med.endDate! : '—'),
              ),
              _InfoItem('Status', med.isActive ? 'Active' : 'Inactive'),
              _InfoItem(
                'Course',
                med.isOngoing ? 'Continuous' : 'Fixed period',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Clinical context',
          icon: Icons.medical_information_outlined,
          child: _InfoGrid(
            items: [
              _InfoItem('Prescribed by', _v(med.prescribedBy)),
              _InfoItem(
                'Linked disease',
                med.diseaseName.isNotEmpty ? med.diseaseName : '—',
              ),
            ],
          ),
        ),
        if (med.instructions != null &&
            med.instructions!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Instructions',
            icon: Icons.notes_outlined,
            child: Text(
              med.instructions!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textMuted,
                height: 1.45,
                fontSize: 14,
              ),
            ),
          ),
        ],
        if (med.subtitle.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.teal.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.teal.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppColors.tealDark, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    med.subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.tealDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _v(String? value) =>
      (value != null && value.trim().isNotEmpty) ? value.trim() : '—';
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EBE7)),
        boxShadow: [
          BoxShadow(
            color: AppColors.tealDark.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EE),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.tealDark, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;
  const _InfoItem(this.label, this.value);
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < items.length ? 10 : 0),
            child: Row(
              children: [
                Expanded(child: _InfoCell(items[i])),
                const SizedBox(width: 10),
                Expanded(
                  child: i + 1 < items.length
                      ? _InfoCell(items[i + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoCell extends StatelessWidget {
  final _InfoItem item;
  const _InfoCell(this.item);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool soft;

  const _Badge({
    required this.label,
    required this.color,
    this.soft = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: soft ? 0.10 : 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onRetry;
  const _EmptyState({required this.onBack, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.medication_outlined,
                  size: 40, color: AppColors.tealDark),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load details',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please retry or go back and open this medication again.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textGray),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.tealDark,
                    side: BorderSide(
                        color: AppColors.teal.withValues(alpha: 0.45)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Go Back',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDark,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Retry',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
