class DiseaseDocument {
  final String uuid;
  final String? displayId;
  final String docType;
  final String? title;
  final String? summary;
  final String? notes;
  final String? documentDate;
  final String? createdAt;
  final int pageCount;
  final ReportTypeInfo? reportType;
  final List<DocumentFile> files;

  DiseaseDocument({
    required this.uuid,
    this.displayId,
    required this.docType,
    this.title,
    this.summary,
    this.notes,
    this.documentDate,
    this.createdAt,
    this.pageCount = 0,
    this.reportType,
    this.files = const [],
  });

  factory DiseaseDocument.fromJson(Map<String, dynamic> json) {
    final filesRaw = json['files'];
    final files = <DocumentFile>[];
    if (filesRaw is List) {
      for (final e in filesRaw) {
        if (e is Map) {
          files.add(DocumentFile.fromJson(Map<String, dynamic>.from(e)));
        }
      }
    }

    ReportTypeInfo? reportType;
    final rt = json['report_type'];
    if (rt is Map) {
      reportType = ReportTypeInfo.fromJson(Map<String, dynamic>.from(rt));
    }

    return DiseaseDocument(
      uuid: json['uuid']?.toString() ?? '',
      displayId: json['display_id']?.toString(),
      docType: (json['doc_type'] ?? json['document_type'] ?? '').toString(),
      title: json['title']?.toString() ?? json['name']?.toString(),
      summary: json['summary']?.toString(),
      notes: json['notes']?.toString(),
      documentDate: json['document_date']?.toString(),
      createdAt: json['created_at']?.toString(),
      pageCount: int.tryParse('${json['page_count'] ?? files.length}') ??
          files.length,
      reportType: reportType,
      files: files,
    );
  }

  String get displayTitle {
    if (title != null && title!.trim().isNotEmpty) return title!.trim();
    if (reportType?.name != null && reportType!.name!.isNotEmpty) {
      return reportType!.name!;
    }
    return docType == 'prescription' ? 'Prescription' : 'Report';
  }

  String? get coverUrl {
    if (files.isEmpty) return null;
    final sorted = [...files]
      ..sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
    return sorted.first.fileUrl;
  }

  bool get isPrescription => docType.toLowerCase() == 'prescription';
}

class DocumentFile {
  final String uuid;
  final int pageNumber;
  final String? fileUrl;
  final String? mimeType;
  final int? fileSize;

  DocumentFile({
    required this.uuid,
    this.pageNumber = 1,
    this.fileUrl,
    this.mimeType,
    this.fileSize,
  });

  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    return DocumentFile(
      uuid: json['uuid']?.toString() ?? '',
      pageNumber: int.tryParse('${json['page_number'] ?? 1}') ?? 1,
      fileUrl: json['file_url']?.toString() ?? json['file']?.toString(),
      mimeType: json['mime_type']?.toString(),
      fileSize: int.tryParse('${json['file_size'] ?? ''}'),
    );
  }

  bool get isImage {
    final m = (mimeType ?? '').toLowerCase();
    final url = (fileUrl ?? '').toLowerCase();
    return m.startsWith('image/') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.png') ||
        url.endsWith('.webp') ||
        url.endsWith('.gif');
  }

  bool get isPdf {
    final m = (mimeType ?? '').toLowerCase();
    final url = (fileUrl ?? '').toLowerCase();
    return m.contains('pdf') || url.endsWith('.pdf');
  }
}

class ReportTypeInfo {
  final int? id;
  final String? reportTypeId;
  final String? name;
  final String? code;
  final String? description;

  ReportTypeInfo({
    this.id,
    this.reportTypeId,
    this.name,
    this.code,
    this.description,
  });

  factory ReportTypeInfo.fromJson(Map<String, dynamic> json) {
    return ReportTypeInfo(
      id: int.tryParse('${json['id'] ?? ''}'),
      reportTypeId: json['report_type_id']?.toString(),
      name: json['name']?.toString(),
      code: json['code']?.toString(),
      description: json['description']?.toString(),
    );
  }
}

class DocumentTypeOption {
  final String value;
  final String label;
  const DocumentTypeOption({required this.value, required this.label});

  factory DocumentTypeOption.fromJson(Map<String, dynamic> json) {
    return DocumentTypeOption(
      value: json['value']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
    );
  }
}
