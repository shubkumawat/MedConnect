import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/medication_ocr_parser.dart';

enum MedicationScanSource { camera, gallery }

/// Result of a medication image scan attempt.
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
  MedicationOcrService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;
  TextRecognizer? _recognizer;

  TextRecognizer get _textRecognizer =>
      _recognizer ??= TextRecognizer(script: TextRecognitionScript.latin);

  /// Opens camera or gallery, runs OCR, and returns parsed medication fields.
  Future<MedicationScanOutcome> scan({
    required MedicationScanSource source,
  }) async {
    try {
      final picked = await _picker.pickImage(
        source: source == MedicationScanSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2000,
      );

      if (picked == null) {
        return MedicationScanOutcome.cancelled();
      }

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
      final message = _friendlyError(e);
      return MedicationScanOutcome.failure(message);
    }
  }

  Future<String> _recognizeText(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  String _friendlyError(Object e) {
    final raw = e.toString().toLowerCase();
    if (raw.contains('permission') ||
        raw.contains('denied') ||
        raw.contains('camera_access')) {
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
