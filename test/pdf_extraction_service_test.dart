import 'dart:typed_data';

import 'package:cvmatch/src/features/cv_upload/domain/services/pdf_extraction_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  const service = PdfExtractionService();

  test('extracts readable text from a text-based PDF', () async {
    final document = await service.extractBytes(
      fileName: 'Derya_Kaya_CV.pdf',
      fileSize: null,
      bytes: _pdfWithText('Derya Kaya CV product discovery roadmap ownership'),
    );

    expect(document.extractionSucceeded, isTrue);
    expect(document.pageCount, 1);
    expect(document.extractedText, contains('Derya Kaya CV'));
  });

  test('returns friendly error for empty PDF bytes', () async {
    await expectLater(
      service.extractBytes(
        fileName: 'empty_cv.pdf',
        fileSize: 0,
        bytes: Uint8List(0),
      ),
      throwsA(
        isA<PdfExtractionException>().having(
          (error) => error.message,
          'message',
          'No readable text was found in this PDF.',
        ),
      ),
    );
  });

  test('returns friendly error for image-only PDF', () async {
    await expectLater(
      service.extractBytes(
        fileName: 'scanned_cv.pdf',
        fileSize: null,
        bytes: _blankPdf(),
      ),
      throwsA(
        isA<PdfExtractionException>().having(
          (error) => error.message,
          'message',
          'This PDF appears to contain scanned images. Please upload a text-based CV.',
        ),
      ),
    );
  });
}

Uint8List _pdfWithText(String text) {
  final document = PdfDocument();
  final page = document.pages.add();
  page.graphics.drawString(text, PdfStandardFont(PdfFontFamily.helvetica, 12));
  final bytes = Uint8List.fromList(document.saveSync());
  document.dispose();
  return bytes;
}

Uint8List _blankPdf() {
  final document = PdfDocument();
  document.pages.add();
  final bytes = Uint8List.fromList(document.saveSync());
  document.dispose();
  return bytes;
}
