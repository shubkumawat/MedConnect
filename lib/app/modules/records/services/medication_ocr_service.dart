import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// Structured medication fields extracted from OCR text.
class MedicationOcrResult {
  final String? name;
  final String? genericName;
  final String? dosage;
  final String? dosageUnit;
  final String? form;
  final String? frequency;
  final String? timing;
  final String? duration;
  final String? instructions;
  final String rawText;

  const MedicationOcrResult({
    this.name,
    this.genericName,
    this.dosage,
    this.dosageUnit,
    this.form,
    this.frequency,
    this.timing,
    this.duration,
    this.instructions,
    this.rawText = '',
  });

  bool get hasAnyField =>
      (name?.isNotEmpty ?? false) ||
      (genericName?.isNotEmpty ?? false) ||
      (dosage?.isNotEmpty ?? false) ||
      (frequency?.isNotEmpty ?? false) ||
      (timing?.isNotEmpty ?? false) ||
      (duration?.isNotEmpty ?? false) ||
      (instructions?.isNotEmpty ?? false);
}

/// Parses raw OCR text from medicine strips, boxes, or prescriptions.
class MedicationOcrParser {
  static const _noiseWords = {
    'mfg', 'mfr', 'mfd', 'exp', 'expiry', 'batch', 'lot', 'mrp', 'rs', 'inr',
    'gst', 'rx', 'tablet', 'tablets', 'capsule', 'capsules', 'syrup', 'injection',
    'drops', 'strip', 'pack', 'of', 'each', 'composition', 'ingredients',
    'manufactured', 'marketed', 'by', 'ltd', 'pvt', 'limited', 'pharma',
    'pharmaceuticals', 'healthcare', 'india',
  };

  static const _formKeywords = {
    'tablet': 'Tablet', 'tab': 'Tablet', 'tabs': 'Tablet',
    'capsule': 'Capsule', 'cap': 'Capsule', 'caps': 'Capsule',
    'syrup': 'Syrup', 'injection': 'Injection', 'inj': 'Injection',
    'drops': 'Drops', 'drop': 'Drops', 'inhaler': 'Inhaler',
    'cream': 'Topical', 'ointment': 'Topical', 'gel': 'Topical', 'patch': 'Patch',
  };

  static MedicationOcrResult parse(String rawText) {
    if (rawText.trim().isEmpty) return const MedicationOcrResult();

    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final fullText = lines.join('\n');
    final lower = fullText.toLowerCase();

    final dosageMatch = _extractDosage(fullText);
    final form = _extractForm(lower);
    final frequency = _extractFrequency(lower);
    final timing = _extractTiming(lower);
    final duration = _extractDuration(lower);
    final instructions = _extractInstructions(fullText, lines);
    final name = _extractName(lines, dosageMatch?.group(0));
    final genericName = _extractGenericName(lines, name);

    return MedicationOcrResult(
      name: name,
      genericName: genericName,
      dosage: dosageMatch?.group(1),
      dosageUnit: dosageMatch != null ? _normalizeUnit(dosageMatch.group(2) ?? '') : null,
      form: form,
      frequency: frequency,
      timing: timing,
      duration: duration,
      instructions: instructions,
      rawText: rawText,
    );
  }

  static RegExpMatch? _extractDosage(String text) {
    final patterns = [
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(mg|ml|iu|g|mcg|µg)\b', caseSensitive: false),
      RegExp(r'(\d+(?:[.,]\d+)?)\s*(milligram|millilitre|milliliter)\b', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match;
    }
    return null;
  }

  static String _normalizeUnit(String unit) {
    final u = unit.toLowerCase().trim();
    if (u.startsWith('milli') && u.contains('gram')) return 'mg';
    if (u.startsWith('milli')) return 'ml';
    if (u == 'µg' || u == 'mcg') return 'mg';
    if (u == 'iu') return 'IU';
    return u;
  }

  static String? _extractForm(String lower) {
    for (final entry in _formKeywords.entries) {
      if (RegExp('\\b${RegExp.escape(entry.key)}\\b').hasMatch(lower)) {
        return entry.value;
      }
    }
    return null;
  }

  static String? _extractFrequency(String lower) {
    if (RegExp(r'\b(sos|as\s+needed|prn)\b').hasMatch(lower)) return 'SOS';
    if (RegExp(r'\b(qid|4\s*[x×]\s*(daily|day)|four\s+times?\s+(a\s+)?day|every\s+6\s*h)\b').hasMatch(lower)) {
      return '4x daily';
    }
    if (RegExp(r'\b(tid|tds|3\s*[x×]\s*(daily|day)|thrice\s+(daily|a\s+day)|three\s+times?\s+(a\s+)?day)\b').hasMatch(lower)) {
      return '3x daily';
    }
    if (RegExp(r'\b(bid|bd|twice\s+(daily|a\s+day)|2\s*[x×]\s*(daily|day)|two\s+times?\s+(a\s+)?day)\b').hasMatch(lower)) {
      return 'Twice daily';
    }
    if (RegExp(r'\b(od|qd|once\s+(daily|a\s+day)|1\s*[x×]\s*(daily|day)|one\s+time?\s+(a\s+)?day)\b').hasMatch(lower)) {
      return 'Once daily';
    }
    if (RegExp(r'\bevery\s+8\s*h(ours?)?\b').hasMatch(lower)) return 'Every 8 hours';
    if (RegExp(r'\bevery\s+6\s*h(ours?)?\b').hasMatch(lower)) return 'Every 6 hours';
    return null;
  }

  static String? _extractTiming(String lower) {
    if (RegExp(r'\b(empty\s+stomach|before\s+breakfast)\b').hasMatch(lower)) {
      return 'Empty Stomach';
    }
    if (RegExp(r'\b(before\s+(food|meals?|meal)|ac)\b').hasMatch(lower)) {
      return 'Before Food';
    }
    if (RegExp(r'\b(after\s+(food|meals?|meal)|pc)\b').hasMatch(lower)) {
      return 'After Food';
    }
    if (RegExp(r'\b(with\s+(food|meals?|meal))\b').hasMatch(lower)) {
      return 'With Food';
    }
    if (RegExp(r'\b(anytime|any\s+time)\b').hasMatch(lower)) return 'Anytime';
    if (RegExp(r'\b(bedtime|at\s+night|hs|nightly|night)\b').hasMatch(lower)) {
      return 'Night';
    }
    if (RegExp(r'\b(afternoon|noon)\b').hasMatch(lower)) return 'Afternoon';
    if (RegExp(r'\b(morning|breakfast)\b').hasMatch(lower)) return 'Morning';
    if (RegExp(r'\b(evening)\b').hasMatch(lower)) return 'Evening';
    return null;
  }

  static String? _extractDuration(String lower) {
    final match = RegExp(r'(?:for\s+)?(\d+)\s*(day|days|week|weeks|month|months|yr|year|years)\b').firstMatch(lower);
    if (match == null) return null;
    return '${match.group(1)} ${match.group(2)}';
  }

  static String? _extractInstructions(String fullText, List<String> lines) {
    final instructionPatterns = [
      RegExp(r'(?:take|consume|apply|use|inst(?:ruction)?s?)\s*[:\-]?\s*(.+)', caseSensitive: false),
      RegExp(r'(?:direction[s]?|advice|note[s]?)\s*[:\-]\s*(.+)', caseSensitive: false),
    ];
    for (final pattern in instructionPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        final value = match.group(1)?.trim();
        if (value != null && value.length > 3) {
          return value.length > 200 ? '${value.substring(0, 200)}…' : value;
        }
      }
    }
    for (final line in lines) {
      final l = line.toLowerCase();
      if ((l.contains('take') || l.contains('swallow') || l.contains('apply') || l.contains('do not')) &&
          line.length > 12 &&
          line.length < 200) {
        return line;
      }
    }
    return null;
  }

  static String? _extractName(List<String> lines, String? dosageSnippet) {
    for (final line in lines) {
      var candidate = line.trim();
      if (candidate.length < 2 || candidate.length > 60) continue;
      if (RegExp(r'^[\d\s./\-₹$rsMRPBatchExp]+$', caseSensitive: false).hasMatch(candidate)) continue;
      if (RegExp(r'^(mrp|batch|exp|mfg|lot|gst|net)\b', caseSensitive: false).hasMatch(candidate)) continue;

      if (dosageSnippet != null) {
        candidate = candidate.replaceAll(RegExp(RegExp.escape(dosageSnippet), caseSensitive: false), '');
      }
      candidate = candidate
          .replaceAll(RegExp(r'\b\d+(?:[.,]\d+)?\s*(mg|ml|iu|g|mcg)\b', caseSensitive: false), '')
          .replaceAll(RegExp(r'[|•·]+'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      for (final form in _formKeywords.keys) {
        candidate = candidate.replaceAll(RegExp('\\b$form\\b', caseSensitive: false), '').trim();
      }

      final words = candidate
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .where((w) => !_noiseWords.contains(w.toLowerCase()))
          .toList();
      if (words.isEmpty) continue;

      final joined = words.take(4).join(' ');
      if (RegExp(r'^[A-Za-z][A-Za-z0-9\-\s]{1,40}$').hasMatch(joined)) {
        return _titleCase(joined);
      }
    }
    return null;
  }

  static String? _extractGenericName(List<String> lines, String? brandName) {
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('composition') ||
          lower.contains('contains') ||
          lower.contains('generic') ||
          RegExp(r'\([a-z].{3,}\)').hasMatch(lower)) {
        var candidate = line
            .replaceAll(RegExp(r'^(composition|contains|generic)\s*[:\-]?\s*', caseSensitive: false), '')
            .replaceAll(RegExp(r'[()]'), '')
            .replaceAll(RegExp(r'\b\d+(?:[.,]\d+)?\s*(mg|ml|iu|g|mcg)\b', caseSensitive: false), '')
            .trim();
        if (brandName != null && candidate.toLowerCase() == brandName.toLowerCase()) continue;
        if (candidate.length >= 3 && candidate.length <= 50) {
          return _titleCase(candidate.split(RegExp(r'\s+')).take(5).join(' '));
        }
      }
    }
    return null;
  }

  static String _titleCase(String input) {
    return input.split(RegExp(r'\s+')).map((w) {
      if (w.isEmpty) return w;
      if (w == w.toUpperCase() && w.length <= 4) return w;
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }
}

enum MedicationScanSource { camera, gallery }

class MedicationScanOutcome {
  final MedicationOcrResult? result;
  final String? errorMessage;
  final bool cancelled;

  const MedicationScanOutcome._({
    this.result,
    this.errorMessage,
    this.cancelled = false,
  });

  factory MedicationScanOutcome.success(MedicationOcrResult result) =>
      MedicationScanOutcome._(result: result);

  factory MedicationScanOutcome.cancelled() =>
      const MedicationScanOutcome._(cancelled: true);

  factory MedicationScanOutcome.failure(String message) =>
      MedicationScanOutcome._(errorMessage: message);

  bool get isSuccess => result != null && errorMessage == null && !cancelled;
}

/// Captures / picks a medication image and runs on-device OCR via ML Kit.
class MedicationOcrService {
  MedicationOcrService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  TextRecognizer? _recognizer;

  TextRecognizer get _textRecognizer =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  Future<MedicationScanOutcome> scan({required MedicationScanSource source}) async {
    try {
      final picked = await _picker.pickImage(
        source: source == MedicationScanSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2000,
      );

      if (picked == null) return MedicationScanOutcome.cancelled();

      final file = File(picked.path);
      if (!await file.exists()) {
        return MedicationScanOutcome.failure(
          'Could not access the selected image. Please try again.',
        );
      }

      final recognized = await _recognizeText(picked.path);
      final text = recognized.trim();
      if (text.isEmpty) {
        return MedicationScanOutcome.failure(
          'No text detected. Try a clearer photo of the medicine strip or box.',
        );
      }

      final parsed = MedicationOcrParser.parse(text);
      if (!parsed.hasAnyField) {
        return MedicationScanOutcome.failure(
          'Text was found but medication details could not be identified. Please enter details manually.',
        );
      }
      return MedicationScanOutcome.success(parsed);
    } on Exception catch (e, st) {
      debugPrint('Medication OCR error: $e\n$st');
      return MedicationScanOutcome.failure(_friendlyError(e));
    }
  }

  Future<String> _recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  String _friendlyError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('permission') || raw.contains('denied') || raw.contains('camera_access')) {
      return 'Camera permission is required to scan medications. Please enable it in Settings.';
    }
    if (raw.contains('camera')) {
      return 'Unable to open the camera. Please check permissions and try again.';
    }
    return 'Failed to scan medication. Please try again or enter details manually.';
  }

  Future<void> dispose() async {
    await _recognizer?.close();
    _recognizer = null;
  }
}
