import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:healaura/app/core/Util/AdditionalWidget/AdditionalWidget.dart';
import 'package:healaura/app/core/Util/CustomTextField/CustomTextField.dart';
import 'package:healaura/app/core/Util/image_pick_helper.dart';
import 'package:healaura/app/data/models/disease_document_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/healora_logo.dart';
import '../../../core/theme/app_text_theme.dart';
import '../controllers/records_controller.dart';

class AddDiseaseDocumentScreen extends StatefulWidget {
  final String diseaseUuid;
  final String? initialDocType;
  final String? appointmentUuid;

  const AddDiseaseDocumentScreen({
    super.key,
    required this.diseaseUuid,
    this.initialDocType,
    this.appointmentUuid,
  });

  @override
  State<AddDiseaseDocumentScreen> createState() =>
      _AddDiseaseDocumentScreenState();
}

class _AddDiseaseDocumentScreenState extends State<AddDiseaseDocumentScreen> {
  final RecordsController controller = Get.find<RecordsController>();
  final _titleCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  String? _docType;
  String? _reportTypeCode;
  final List<XFile> _files = [];
  static const int maxFiles = 3;

  @override
  void initState() {
    super.initState();
    _docType = widget.initialDocType ??
        controller.documentTypeFilter.value;
    if (_docType != null && _docType!.isEmpty) _docType = 'prescription';
    _dateCtrl.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (controller.documentTypes.isEmpty || controller.reportTypes.isEmpty) {
      controller.fetchReportTypesMeta();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _summaryCtrl.dispose();
    _notesCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateCtrl.text) ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.tealDark,
            onPrimary: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickFiles() async {
    final remaining = maxFiles - _files.length;
    if (remaining <= 0) {
      Get.snackbar('Limit', 'You can upload maximum $maxFiles files',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.orange,
          colorText: Colors.white);
      return;
    }

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickSourceSheet(),
    );
    if (source == null) return;

    if (source == 'camera') {
      final file = await ImagePickHelper.pick(source: ImageSource.camera);
      if (file != null) {
        setState(() => _files.add(XFile(file.path)));
      }
      return;
    }

    final images = await ImagePickHelper.pickMulti(limit: remaining);
    if (images.isEmpty) return;
    setState(() {
      _files.addAll(images.take(remaining));
    });
  }

  Future<void> _submit() async {
    if (_docType == null || _docType!.isEmpty) {
      Get.snackbar('Required', 'Please select document type',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.orange,
          colorText: Colors.white);
      return;
    }
    if (_docType == 'report' &&
        (_reportTypeCode == null || _reportTypeCode!.isEmpty)) {
      Get.snackbar('Required', 'Please select report type',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.orange,
          colorText: Colors.white);
      return;
    }
    if (_titleCtrl.text.trim().isEmpty) {
      Get.snackbar('Required', 'Please enter a title',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.orange,
          colorText: Colors.white);
      return;
    }
    if (_files.isEmpty) {
      Get.snackbar('Required', 'Please add at least 1 file (max $maxFiles)',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.orange,
          colorText: Colors.white);
      return;
    }

    final ok = await controller.uploadDiseaseDocumentFull(
      diseaseUuid: widget.diseaseUuid,
      title: _titleCtrl.text.trim(),
      summary: _summaryCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      docType: _docType!,
      reportTypeCode: _reportTypeCode,
      documentDate: _dateCtrl.text.trim(),
      filePaths: _files.map((e) => e.path).toList(),
      appointmentUuid: widget.appointmentUuid,
    );

    if (!mounted) return;
    if (ok) {
      Get.back(result: true);
      Get.snackbar('Success', 'Document uploaded successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.teal,
          colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Failed to upload document',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.statusRed,
          colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final bottom = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6F4),
      body: Column(
        children: [
          _Header(topPad: top, onBack: () => Get.back()),
          Expanded(
            child: Obx(() {
              final docTypes = controller.documentTypes.isEmpty
                  ? const [
                      DocumentTypeOption(
                          value: 'prescription', label: 'Prescription'),
                      DocumentTypeOption(value: 'report', label: 'Report'),
                    ]
                  : controller.documentTypes.toList();
              final reports = controller.reportTypes.toList();

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  children: [
                    _SectionCard(
                      step: '01',
                      title: 'What are you uploading?',
                      caption: 'Choose prescription or medical report',
                      icon: Icons.category_outlined,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: docTypes.map((t) {
                            final selected = _docType == t.value;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _docType = t.value;
                                if (_docType != 'report') {
                                  _reportTypeCode = null;
                                }
                              }),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 160),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.tealDark
                                      : const Color(0xFFF3F7F5),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: selected
                                        ? AppColors.tealDark
                                        : const Color(0xFFE3EBE7),
                                  ),
                                ),
                                child: Text(
                                  t.label,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textMuted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (_docType == 'report') ...[
                          const SizedBox(height: 14),
                          Builder(builder: (_) {
                            final matched = reports
                                .where((e) => e.code == _reportTypeCode)
                                .toList();
                            return McDropdown<ReportTypeInfo>(
                              hint: 'Report type *',
                              value:
                                  matched.isEmpty ? null : matched.first,
                              items: reports,
                              itemLabel: (e) => e.name ?? e.code ?? '',
                              onChanged: (v) =>
                                  setState(() => _reportTypeCode = v?.code),
                            );
                          }),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      step: '02',
                      title: 'Document details',
                      caption: 'Title, date and short summary',
                      icon: Icons.edit_note_rounded,
                      children: [
                        CustomTextField(
                          hint: 'Title *',
                          controller: _titleCtrl,
                          prefixIcon: Icons.title_rounded,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          hint: 'Document date',
                          controller: _dateCtrl,
                          prefixIcon: Icons.calendar_today_outlined,
                          readOnly: true,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          hint: 'Summary (optional)',
                          controller: _summaryCtrl,
                          prefixIcon: Icons.notes_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          hint: 'Notes (optional)',
                          controller: _notesCtrl,
                          prefixIcon: Icons.sticky_note_2_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      step: '03',
                      title: 'Attach files',
                      caption: 'Images or scans · max $maxFiles files',
                      icon: Icons.attach_file_rounded,
                      children: [
                        if (_files.isNotEmpty) ...[
                          SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _files.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 10),
                              itemBuilder: (_, i) {
                                final f = _files[i];
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(f.path),
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _files.removeAt(i)),
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: const BoxDecoration(
                                            color: Colors.black54,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.close,
                                              size: 14, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        OutlinedButton.icon(
                          onPressed:
                              _files.length >= maxFiles ? null : _pickFiles,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: Text(
                            _files.isEmpty
                                ? 'Add files (max $maxFiles)'
                                : 'Add more (${_files.length}/$maxFiles)',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.tealDark,
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(
                                color: AppColors.teal.withValues(alpha: 0.45)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                  top: BorderSide(color: Color(0xFFE3EBE7))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Obx(() {
              final loading = controller.isDocumentUploading.value;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tealDark,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.tealDark.withValues(alpha: 0.55),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Upload Document',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15.5),
                        ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPad;
  final VoidCallback onBack;
  const _Header({required this.topPad, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, topPad + 8, 16, 16),
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
              onTap: onBack,
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
          const HealoraLogo.chip(),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload Document',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Prescription or medical report',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String step;
  final String title;
  final String caption;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.step,
    required this.title,
    required this.caption,
    required this.icon,
    required this.children,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F2EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.tealDark, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                            color: AppColors.textDark)),
                    Text(caption,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textGray)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F7F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(step,
                    style: const TextStyle(
                        color: AppColors.tealDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _PickSourceSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Add files',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18,color: Colors.black)),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined,
                color: AppColors.tealDark),
            title: const Text('Take photo',
                style: TextStyle(fontWeight: FontWeight.w700,color: Colors.black)),
            onTap: () => Navigator.pop(context, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined,
                color: AppColors.orange),
            title: const Text('Choose from gallery',
                style: TextStyle(fontWeight: FontWeight.w700,color: Colors.black)),
            onTap: () => Navigator.pop(context, 'gallery'),
          ),
        ],
      ),
    );
  }
}
