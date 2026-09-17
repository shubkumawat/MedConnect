import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:healaura/app/data/models/disease_response_model.dart';
import 'package:healaura/app/data/models/medical_record_model.dart';

class PdfGenerator {
  static Future<Uint8List> generateDiseasePdfBytes({
    required DiseaseResult disease,
    required List<Medication> medications,
    required List<TimelineEvent> timeline,
  }) async {
    final pdf = pw.Document();
    
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    final italicFont = await PdfGoogleFonts.robotoItalic();
    final boldItalicFont = await PdfGoogleFonts.robotoBoldItalic();
    
    final theme = pw.ThemeData.withFont(
      base: font,
      bold: boldFont,
      italic: italicFont,
      boldItalic: boldItalicFont,
    );

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Medical Record", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text("ID: ${disease.displayId ?? 'N/A'}", style: pw.TextStyle(fontSize: 12)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Disease Overview
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(disease.name ?? "NA", style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 10),
                _buildInfoRow("Condition Type", disease.conditionType ?? "N/A"),
                _buildInfoRow("Status", disease.status ?? "N/A"),
                _buildInfoRow("Severity", disease.severity ?? "N/A"),
                _buildInfoRow("Diagnosed On", disease.diagnosedOn ?? "N/A"),
                if (disease.recoveredOn != null) _buildInfoRow("Recovered On", disease.recoveredOn!),
                _buildInfoRow("Hereditary", (disease.hereditary ?? "no").toUpperCase()),
                if (disease.notes != null && disease.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 10),
                  pw.Text("Clinical Notes:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(disease.notes!),
                ],
              ],
            ),
            pw.SizedBox(height: 20),

            // Medications
            if (medications.isNotEmpty) ...[
              pw.Text("Prescribed Medications", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey300),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
                data: <List<String>>[
                  <String>['Medication Name', 'Frequency', 'Timing'],
                  ...medications.map((m) => [m.name, m.frequency, m.timing])
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Timeline
            if (timeline.isNotEmpty) ...[
              pw.Text("Medical Timeline", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...timeline.map((event) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 5),
                padding: const pw.EdgeInsets.all(5),
                decoration: pw.BoxDecoration(
                  border: pw.Border(left: pw.BorderSide(color: PdfColors.blue, width: 2))
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.SizedBox(width: 80, child: pw.Text(event.time, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700))),
                    pw.Expanded(child: pw.Text(event.title, style: pw.TextStyle(fontSize: 11))),
                  ],
                ),
              )),
            ],
            
            pw.Footer(
              margin: const pw.EdgeInsets.only(top: 20),
              trailing: pw.Text("Generated via Healora", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
            )
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 120, child: pw.Text("$label: ", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          pw.Text(value),
        ],
      ),
    );
  }
}
