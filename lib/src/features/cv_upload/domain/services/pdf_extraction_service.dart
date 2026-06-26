import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/cv_document.dart';

typedef File = XFile;

class PdfExtractionException implements Exception {
  const PdfExtractionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PdfExtractionService {
  const PdfExtractionService();

  Future<CvDocument> extract(File file) async {
    final bytes = await file.readAsBytes();
    final fileSize = await file.length();

    return extractBytes(fileName: file.name, fileSize: fileSize, bytes: bytes);
  }

  Future<CvDocument> extractBytes({
    required String fileName,
    required int? fileSize,
    required Uint8List bytes,
  }) async {
    if (bytes.isEmpty) {
      throw const PdfExtractionException(
        'No readable text was found in this PDF.',
      );
    }

    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;

      if (pageCount == 0) {
        throw const PdfExtractionException(
          'No readable text was found in this PDF.',
        );
      }

      final extractedText = _normalizeText(
        PdfTextExtractor(document).extractText(),
      );

      if (extractedText.isEmpty) {
        throw const PdfExtractionException(
          'This PDF appears to contain scanned images. Please upload a text-based CV.',
        );
      }

      return CvDocument(
        fileName: fileName,
        fileSize: fileSize,
        extractedText: extractedText,
        pageCount: pageCount,
        extractionSucceeded: true,
      );
    } on PdfExtractionException {
      rethrow;
    } catch (error) {
      throw PdfExtractionException(_messageFor(error));
    } finally {
      document?.dispose();
    }
  }

  String _normalizeText(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _messageFor(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('password') ||
        message.contains('encrypted') ||
        message.contains('invalid password')) {
      return 'This PDF appears to be password protected. Please upload an unlocked text-based CV.';
    }

    if (message.contains('format') ||
        message.contains('invalid') ||
        message.contains('corrupt') ||
        message.contains('xref')) {
      return 'This PDF could not be read. Please upload a text-based CV.';
    }

    return 'Please upload a text-based CV.';
  }
}
