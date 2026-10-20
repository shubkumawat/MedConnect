import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/menstrual_cycle_model.dart';
import '../../profile/controllers/profile_controller.dart';
import 'package:healora/app/core/Util/app_toast.dart';

class MenstrualCycleScreen extends StatefulWidget {
  final String? patientId;
  final String? patientName;

  const MenstrualCycleScreen({
    super.key,
    this.patientId,
    this.patientName,
  });

  @override
  State<MenstrualCycleScreen> createState() => _MenstrualCycleScreenState();
}

class _MenstrualCycleScreenState extends State<MenstrualCycleScreen> {
  late final ProfileController controller;
  MenstrualCycle? _cycle;
  bool _unavailable = false;
  bool _loading = true;

  DateTime? _lastStart;
  int _cycleLen = 28;
  int _periodLen = 5;
  TimeOfDay _time = const TimeOfDay(hour: 9, minute: 0);
  bool _enabled = true;
  bool _dayBefore = true;
  bool _onStart = true;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cycle = await controller.loadMenstrualCycle(patientId: widget.patientId);
    if (!mounted) return;
    if (cycle == null || cycle.available == false) {
      setState(() {
        _unavailable = true;
        _loading = false;
        _cycle = cycle;
      });
      return;
    }
    _apply(cycle);
    setState(() {
      _unavailable = false;
      _loading = false;
    });
  }

  void _apply(MenstrualCycle cycle) {
    _cycle = cycle;
    _cycleLen = cycle.cycleLengthDays.clamp(21, 45);
    _periodLen = cycle.periodLengthDays.clamp(1, 10);
    _enabled = cycle.isEnabled;
    _dayBefore = cycle.remindDayBefore;
    _onStart = cycle.remindOnStart;
    _lastStart = DateTime.tryParse(cycle.lastPeriodStart ?? '');
    final parts = cycle.reminderTime.split(':');
    if (parts.length >= 2) {
      _time = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
  }

  String get _timeLabel =>
      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastStart ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.tealDark,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _lastStart = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.tealDark,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_lastStart == null) {
      AppToast.showToast(
          msg: 'Last period start is required to save cycle reminders.');
      return;
    }
    if (_cycleLen < 21 || _cycleLen > 45) {
      AppToast.showToast(msg: 'Cycle length must be 21–45 days.');
      return;
    }
    if (_periodLen < 1 || _periodLen > 10) {
      AppToast.showToast(msg: 'Period length must be 1–10 days.');
      return;
    }
    final saved = await controller.saveMenstrualCycle(
      lastPeriodStart: DateFormat('yyyy-MM-dd').format(_lastStart ?? DateTime.now()),
      cycleLengthDays: _cycleLen,
      periodLengthDays: _periodLen,
      reminderTime: _timeLabel,
      isEnabled: _enabled,
      remindDayBefore: _dayBefore,
      remindOnStart: _onStart,
      patientId: widget.patientId,
    );
    if (saved != null && mounted) {
      _apply(saved);
      setState(() {});
    }
  }

  Future<void> _logStart() async {
    final saved = await controller.logPeriodStart(
      startedOn: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      patientId: widget.patientId,
    );
    if (saved != null && mounted) {
      _apply(saved);
      setState(() {});
    }
  }

  String _fmt(String? raw) {
    if (raw == null || raw.isEmpty) return '—';
    try {
      return DateFormat('d MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final name = widget.patientName?.trim();
    return Scaffold(
      backgroundColor: const Color(0xFFEEF5F2),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14, top + 8, 14, 18),
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
                Material(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cycle reminders',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        (name != null && name.isNotEmpty)
                            ? name
                            : 'Period day-before and start alerts',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.teal))
                : _unavailable
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            'Menstrual cycle reminders are available for female patients only.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body
                                .copyWith(color: AppColors.textMuted, height: 1.4),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          if (_cycle?.isConfigured == true) ...[
                            _card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Upcoming',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15.5)),
                                  const SizedBox(height: 10),
                                  _kv('Next period', _fmt(_cycle?.nextPeriodOn)),
                                  _kv('Period ends', _fmt(_cycle?.periodEndOn)),
                                  _kv('Ovulation', _fmt(_cycle?.ovulationOn)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _card(
                            child: Column(
                              children: [
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Enable reminders',
                                      style: AppTextStyles.bodyBold
                                          .copyWith(fontSize: 14)),
                                  subtitle: Text(
                                    'Day before: “Tomorrow is your period”\nDay of: “Period expected today”',
                                    style: AppTextStyles.caption
                                        .copyWith(color: AppColors.textGray),
                                  ),
                                  value: _enabled,
                                  activeThumbColor: AppColors.tealDark,
                                  onChanged: (v) => setState(() => _enabled = v),
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Remind day before',
                                      style: AppTextStyles.bodyBold
                                          .copyWith(fontSize: 14)),
                                  value: _dayBefore,
                                  activeThumbColor: AppColors.tealDark,
                                  onChanged: (v) =>
                                      setState(() => _dayBefore = v),
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Remind on start day',
                                      style: AppTextStyles.bodyBold
                                          .copyWith(fontSize: 14)),
                                  value: _onStart,
                                  activeThumbColor: AppColors.tealDark,
                                  onChanged: (v) =>
                                      setState(() => _onStart = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          _tile(
                            Icons.event_rounded,
                            'Last period start',
                            _lastStart == null
                                ? 'Required to turn reminders on'
                                : DateFormat('yyyy-MM-dd').format(_lastStart!),
                            _pickStart,
                          ),
                          const SizedBox(height: 10),
                          _tile(
                            Icons.schedule_rounded,
                            'Reminder time',
                            _timeLabel,
                            _pickTime,
                          ),
                          const SizedBox(height: 12),
                          _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cycle length ($_cycleLen days)',
                                    style: AppTextStyles.bodyBold
                                        .copyWith(fontSize: 14)),
                                Slider(
                                  min: 21,
                                  max: 45,
                                  divisions: 24,
                                  label: '$_cycleLen',
                                  value: _cycleLen.toDouble(),
                                  activeColor: AppColors.tealDark,
                                  onChanged: (v) =>
                                      setState(() => _cycleLen = v.round()),
                                ),
                                Text('Period length ($_periodLen days)',
                                    style: AppTextStyles.bodyBold
                                        .copyWith(fontSize: 14)),
                                Slider(
                                  min: 1,
                                  max: 10,
                                  divisions: 9,
                                  label: '$_periodLen',
                                  value: _periodLen.toDouble(),
                                  activeColor: AppColors.tealDark,
                                  onChanged: (v) =>
                                      setState(() => _periodLen = v.round()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            height: 52,
                            child: Obx(() => ElevatedButton(
                                  onPressed: controller.menstrualSaving.value
                                      ? null
                                      : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.tealDark,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: controller.menstrualSaving.value
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Save reminders',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w800)),
                                )),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: controller.menstrualSaving.value
                                ? null
                                : _logStart,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.tealDark,
                              minimumSize: const Size.fromHeight(48),
                              side: const BorderSide(color: AppColors.tealDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('Period started today',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
              child: Text(k,
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textGray))),
          Text(v, style: AppTextStyles.bodyBold.copyWith(fontSize: 13.5)),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String label, String value, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE3EBE7)),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.tealDark),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textGray,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(value,
                        style: AppTextStyles.bodyBold.copyWith(fontSize: 15)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textGray),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3EBE7)),
      ),
      child: child,
    );
  }
}
