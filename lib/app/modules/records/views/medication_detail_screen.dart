import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/data/models/medical_record_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/healora_logo.dart';
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
  String? _markingKey;

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
    if (mounted) await _load();
  }

  Future<void> _markTaken(MedicationDoseToday dose) async {
    final med = _med;
    if (med == null || !dose.canMarkTaken) return;

    final reminderUuid = (dose.reminderUuid?.isNotEmpty == true)
        ? dose.reminderUuid!
        : (med.primaryReminder?.id ??
            (med.reminders.isNotEmpty ? med.reminders.first.id : ''));
    if (reminderUuid.isEmpty) return;

    final key = '$reminderUuid|${dose.time}';
    setState(() => _markingKey = key);
    final ok = await controller.markMedicationTaken(
      medicationUuid: med.id,
      reminderUuid: reminderUuid,
      time: dose.time,
    );
    if (!mounted) return;
    setState(() => _markingKey = null);
    if (ok) await _load();
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
                        child: _Body(
                          med: med,
                          markingKey: _markingKey,
                          onMarkTaken: _markTaken,
                        ),
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
          const HealoraLogo.chip(),
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
  final String? markingKey;
  final Future<void> Function(MedicationDoseToday dose) onMarkTaken;

  const _Body({
    required this.med,
    required this.markingKey,
    required this.onMarkTaken,
  });

  String _foodLabel(String? value) {
    if (value == null || value.trim().isEmpty) return '—';
    switch (value.trim().toLowerCase()) {
      case 'before_food':
        return 'Before Food';
      case 'after_food':
        return 'After Food';
      case 'with_food':
        return 'With Food';
      case 'empty_stomach':
        return 'Empty Stomach';
      case 'any':
      case 'anytime':
        return 'Anytime';
      default:
        return value
            .replaceAll('_', ' ')
            .split(' ')
            .map((w) =>
                w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
            .join(' ');
    }
  }

  String _fmtTime(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return raw;
    final h24 = int.tryParse(parts[0]) ?? 0;
    final m = parts[1].padLeft(2, '0');
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:$m $ampm';
  }

  Color _doseColor(String status) {
    switch (status.toLowerCase()) {
      case 'taken':
      case 'completed':
        return AppColors.statusResolved;
      case 'missed':
        return AppColors.statusRed;
      default:
        return AppColors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = med.name.isNotEmpty ? med.name : 'Medication';
    final statusColor =
        med.isActive ? AppColors.statusResolved : AppColors.textGray;
    final reminders = med.reminders.isNotEmpty
        ? med.reminders
        : (med.primaryReminder != null
            ? <MedicationReminder>[med.primaryReminder!]
            : const <MedicationReminder>[]);
    final doses = med.dosesToday;

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
                        if (med.isReminderEnabled)
                          const _Badge(
                            label: 'REMINDER ON',
                            color: AppColors.orange,
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
        if (doses.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: "Today's doses",
            icon: Icons.event_available_outlined,
            child: Column(
              children: [
                for (int i = 0; i < doses.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  _DoseRow(
                    dose: doses[i],
                    timeLabel: _fmtTime(doses[i].time),
                    statusColor: _doseColor(doses[i].status),
                    marking: markingKey ==
                        '${doses[i].reminderUuid ?? med.primaryReminder?.id ?? (med.reminders.isNotEmpty ? med.reminders.first.id : '')}|${doses[i].time}',
                    onTaken: () => onMarkTaken(doses[i]),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (reminders.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Reminders',
            icon: Icons.notifications_active_outlined,
            child: Column(
              children: [
                for (int i = 0; i < reminders.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _ReminderCard(
                    reminder: reminders[i],
                    formatTime: _fmtTime,
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Dosage schedule',
          icon: Icons.schedule_outlined,
          child: _InfoGrid(
            items: [
              _InfoItem('Dosage', _v(med.dosage)),
              _InfoItem(
                'Form',
                med.form != null && med.form!.trim().isNotEmpty
                    ? med.form!
                        .replaceAll('_', ' ')
                        .split(' ')
                        .map((w) => w.isEmpty
                            ? w
                            : '${w[0].toUpperCase()}${w.substring(1)}')
                        .join(' ')
                    : '—',
              ),
              _InfoItem('Frequency', _v(med.frequencyDisplay)),
              _InfoItem(
                'Timing',
                med.timing.isNotEmpty ? med.timing : '—',
              ),
              _InfoItem('With food', _foodLabel(med.withFood)),
            ],
          ),
        ),
        if (med.sideEffects.isNotEmpty || med.allergies.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Reactions & allergies',
            icon: Icons.warning_amber_rounded,
            child: _InfoGrid(
              items: [
                _InfoItem(
                  'Side effects',
                  med.sideEffects.isNotEmpty
                      ? med.sideEffects.join(', ')
                      : '—',
                ),
                _InfoItem(
                  'Allergies',
                  med.allergies.isNotEmpty ? med.allergies.join(', ') : '—',
                ),
              ],
            ),
          ),
        ],
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
      ],
    );
  }

  String _v(String? value) =>
      (value != null && value.trim().isNotEmpty) ? value.trim() : '—';
}

class _DoseRow extends StatelessWidget {
  final MedicationDoseToday dose;
  final String timeLabel;
  final Color statusColor;
  final bool marking;
  final VoidCallback onTaken;

  const _DoseRow({
    required this.dose,
    required this.timeLabel,
    required this.statusColor,
    required this.marking,
    required this.onTaken,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              dose.isTaken
                  ? Icons.check_circle_rounded
                  : Icons.access_time_rounded,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dose.status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (dose.isTaken)
            const _Badge(label: 'TAKEN', color: AppColors.statusResolved)
          else
            TextButton(
              onPressed: marking ? null : onTaken,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.tealDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.tealDark.withValues(alpha: 0.45),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: marking
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Taken',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final MedicationReminder reminder;
  final String Function(String) formatTime;

  const _ReminderCard({
    required this.reminder,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final times = reminder.displayTimes;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F7F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reminder.displayId.isNotEmpty
                      ? reminder.displayId
                      : 'Reminder',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              _Badge(
                label: reminder.isEnabled ? 'ON' : 'OFF',
                color: reminder.isEnabled
                    ? AppColors.statusResolved
                    : AppColors.textGray,
                soft: true,
              ),
            ],
          ),
          if (times.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: times
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.teal.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        formatTime(t),
                        style: const TextStyle(
                          color: AppColors.tealDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (reminder.startDate != null &&
              reminder.startDate!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'From ${reminder.startDate}'
              '${reminder.endDate != null && reminder.endDate!.isNotEmpty ? ' · Until ${reminder.endDate}' : ''}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textGray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
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
