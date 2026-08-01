import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:healaura/app/data/models/disease_document_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';

class DocumentViewerScreen extends StatefulWidget {
  final DiseaseDocument document;
  final int initialIndex;

  const DocumentViewerScreen({
    super.key,
    required this.document,
    this.initialIndex = 0,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  late final PageController _pageCtrl;
  late int _index;

  late final List<DocumentFile> _files;

  @override
  void initState() {
    super.initState();
    _files = [...widget.document.files]
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    _index = _files.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, _files.length - 1);
    _pageCtrl = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _openExternal(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final files = _files;
    final title = widget.document.displayTitle;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(14, top + 8, 14, 14),
            color: const Color(0xFF0A5C45),
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
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        files.isEmpty
                            ? 'No files'
                            : 'Page ${_index + 1} of ${files.length}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (files.isNotEmpty)
                  Material(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => _openExternal(files[_index].fileUrl),
                      borderRadius: BorderRadius.circular(12),
                      child: const SizedBox(
                        width: 40,
                        height: 40,
                        child: Icon(Icons.open_in_new_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: files.isEmpty
                ? Center(
                    child: Text(
                      'No files attached',
                      style: AppTextStyles.body.copyWith(color: Colors.white70),
                    ),
                  )
                : PageView.builder(
                    controller: _pageCtrl,
                    itemCount: files.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) {
                      final f = files[i];
                      if (f.isPdf) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf_rounded,
                                  color: Colors.white, size: 64),
                              const SizedBox(height: 16),
                              const Text(
                                'PDF document',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () => _openExternal(f.fileUrl),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.tealDark,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Open PDF'),
                              ),
                            ],
                          ),
                        );
                      }
                      final url = f.fileUrl;
                      if (url == null || url.isEmpty) {
                        return const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: Colors.white54, size: 48),
                        );
                      }
                      return InteractiveViewer(
                        minScale: 0.8,
                        maxScale: 4,
                        child: Center(
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            loadingBuilder: (_, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.teal),
                              );
                            },
                            errorBuilder: (_, _, _) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.broken_image_outlined,
                                    color: Colors.white54, size: 48),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: () => _openExternal(url),
                                  child: const Text('Open externally',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
