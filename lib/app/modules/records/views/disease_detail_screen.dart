import 'package:flutter/material.dart';
import 'package:digitalhealth/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import 'package:digitalhealth/app/core/Util/CustomButton/CustomButton.dart';
import 'package:digitalhealth/app/core/Util/CustomCardWidgets/CustomCardWidgets.dart';

class DiseaseDetailScreen extends StatefulWidget {
  final String diseaseName;
  final String status;
  final String? heroTag;

  const DiseaseDetailScreen({
    super.key,
    required this.diseaseName,
    required this.status,
    this.heroTag,
  });

  @override
  State<DiseaseDetailScreen> createState() => _DiseaseDetailScreenState();
}

class _DiseaseDetailScreenState extends State<DiseaseDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  Color get _statusColor {
    switch (widget.status.toLowerCase()) {
      case 'active':    return AppColors.statusActive;
      case 'monitoring':return AppColors.statusMonitor;
      case 'resolved':  return AppColors.statusResolved;
      default:          return AppColors.textMuted;
    }
  }

  final _visits = [
    {'date': 'Jan 2023', 'doctor': 'Dr. Sharma', 'hospital': 'Fortis Hospital', 'notes': 'Initial diagnosis, MRI ordered'},
    {'date': 'Apr 2023', 'doctor': 'Dr. Gupta', 'hospital': 'Apollo Clinic', 'notes': 'Follow-up, conservative treatment'},
    {'date': 'Sep 2023', 'doctor': 'Dr. Mehra', 'hospital': 'Max Hospital', 'notes': 'Surgery recommended'},
  ];

  final _meds = [
    {'name': 'Ibuprofen 400mg', 'freq': 'Twice daily · After Food'},
    {'name': 'Pantoprazole 40mg', 'freq': 'Once daily · Empty Stomach'},
  ];

  final _receipts = [
    {'title': 'Consultation — Fortis', 'amount': '₹800', 'date': 'Jan 2023'},
    {'title': 'MRI Scan', 'amount': '₹4,500', 'date': 'Feb 2023'},
    {'title': 'Surgery — Max Hospital', 'amount': '₹65,000', 'date': 'Oct 2023'},
  ];

  Widget _buildAppBarBackground() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                _statusColor,
                _statusColor.withOpacity(0.8),
              ],
            ),
          ),
        ),
        Positioned(
          right: -20,
          top: -20,
          child: Icon(
            Icons.healing_rounded,
            size: 140,
            color: Colors.white.withOpacity(0.15),
          ),
        ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.diseaseName,
              style: AppTextStyles.bodyBold.copyWith(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                widget.status.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          labelStyle: AppTextStyles.captionBold,
          indicatorWeight: 3,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Visits'),
            Tab(text: 'Meds'),
            Tab(text: 'Slips'),
            Tab(text: 'Receipts'),
            Tab(text: 'Timeline'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Overview
          _OverviewTab(statusColor: _statusColor, status: widget.status),

          // Visits
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _visits.length,
            itemBuilder: (_, i) {
              final v = _visits[i];
              return McCard(
                isPremium: true,
                // margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(v['date']!, style: AppTextStyles.captionBold.copyWith(color: AppColors.accentBlue)),
                        ),
                        const Spacer(),
                        Text(v['hospital']!, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.person_pin_rounded, color: AppColors.teal, size: 20),
                        const SizedBox(width: 8),
                        Text(v['doctor']!, style: AppTextStyles.bodyBold),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(v['notes']!, style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    CustomOutlineButton(text: 'View Details', onTap: () {}, height: 36),
                  ],
                ),
              );
            },
          ),

          // Medications
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ..._meds.map((m) => McCard(
                    isPremium: true,
                    // margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.teal.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.medication_rounded, color: AppColors.teal, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['name']!, style: AppTextStyles.bodyBold),
                              const SizedBox(height: 2),
                              Text(m['freq']!, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                      ],
                    ),
                  )),
              const SizedBox(height: 12),
              CustomOutlineButton(text: '+ Add Medication', onTap: () {}),
            ],
          ),

          // Slips
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.document_scanner_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 64),
                const SizedBox(height: 20),
                Text('No prescription slips yet', style: AppTextStyles.body.copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 24),
                CustomPrimaryButton(text: 'Scan Prescription', color: AppColors.teal, onTap: () {}, width: 220),
              ],
            ),
          ),

          // Receipts
          ListView(
            padding: const EdgeInsets.all(20),
            children: _receipts
                .map<Widget>((r) => McCard(
                      isPremium: true,
                      // margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_long_rounded, color: AppColors.orange, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r['title']!, style: AppTextStyles.bodyBold),
                                const SizedBox(height: 2),
                                Text(r['date']!, style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          Text(r['amount']!, style: AppTextStyles.bodyBold.copyWith(color: AppColors.accentTeal)),
                        ],
                      ),
                    ))
                .toList(),
          ),

          // Timeline
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TimelineEventRow(title: 'Diagnosed — Dr. Sharma, Fortis', time: 'Jan 2023', icon: Icons.sick_rounded, iconColor: AppColors.statusActive),
              TimelineEventRow(title: 'Medication added — Ibuprofen', time: 'Jan 2023', icon: Icons.medication_rounded, iconColor: AppColors.teal),
              TimelineEventRow(title: 'Follow-up — Dr. Gupta, Apollo', time: 'Apr 2023', icon: Icons.local_hospital_rounded, iconColor: AppColors.primary),
              TimelineEventRow(title: 'Surgery scheduled — Max Hospital', time: 'Sep 2023', icon: Icons.event_available_rounded, iconColor: AppColors.orange, isLast: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final Color statusColor;
  final String status;
  const _OverviewTab({required this.statusColor, required this.status});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        McCard(
          isPremium: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Condition Details', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              _InfoRow('Category', 'Chronic / Surgical'),
              _InfoRow('Severity', 'Moderate'),
              _InfoRow('Diagnosis Date', 'Jan 12, 2023'),
              _InfoRow('Affected Area', 'Abdomen'),
              _InfoRow('Hereditary', 'No'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        McCard(
          isPremium: true,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Symptoms', style: AppTextStyles.heading3),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ['Persistent Pain', 'Swelling', 'Mild Nausea', 'Fatigue']
                    .map((s) => StatusBadge(label: s, color: AppColors.orange))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}


class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: AppTextStyles.caption)),
          Expanded(child: Text(value, style: AppTextStyles.bodyBold)),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.bgDeepNavy, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(_) => false;
}
