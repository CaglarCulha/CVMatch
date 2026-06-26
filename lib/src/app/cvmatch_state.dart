import 'package:flutter/material.dart';

import '../core/mock/mock_data.dart';
import '../features/analysis/domain/models/cv_analysis_result.dart';
import '../features/cv_upload/domain/models/cv_document.dart';

class CVMatchState extends ChangeNotifier {
  String? _selectedCvFileName;
  String? _selectedCvFilePath;
  int? _selectedCvFileSizeBytes;
  String? _cvValidationWarning;
  CvDocument? _cvDocument;
  String _jobDescription = mockJobDescription.trim();
  CvAnalysisResult? _latestAnalysisResult;

  String? get selectedCvFileName => _selectedCvFileName;
  String? get selectedCvFilePath => _selectedCvFilePath;
  int? get selectedCvFileSizeBytes => _selectedCvFileSizeBytes;
  String? get cvValidationWarning => _cvValidationWarning;
  CvDocument? get cvDocument => _cvDocument;
  String? get cvText => _cvDocument?.extractedText;
  String get jobDescription => _jobDescription;
  CvAnalysisResult? get latestAnalysisResult => _latestAnalysisResult;

  bool get hasSelectedPdf =>
      _selectedCvFileName?.toLowerCase().endsWith('.pdf') ?? false;

  bool get hasValidCv =>
      hasSelectedPdf &&
      _cvValidationWarning == null &&
      (_cvDocument?.extractionSucceeded ?? false) &&
      (_cvDocument?.extractedText.trim().isNotEmpty ?? false);

  bool get hasValidJobDescription => _jobDescription.trim().length >= 100;

  void setSelectedCv({required CvDocument document, required String filePath}) {
    _cvDocument = document;
    _selectedCvFileName = document.fileName;
    _selectedCvFilePath = filePath;
    _selectedCvFileSizeBytes = document.fileSize;
    _cvValidationWarning = _validateCvFileName(document.fileName);
    notifyListeners();
  }

  void setJobDescription(String value) {
    _jobDescription = value;
    notifyListeners();
  }

  void setAnalysisResult(CvAnalysisResult result) {
    _latestAnalysisResult = result;
    notifyListeners();
  }

  String? _validateCvFileName(String fileName) {
    final normalized = fileName.toLowerCase();
    final looksLikeCv = RegExp(
      r'(^|[\s_\-.])(cv|resume|resumé|résumé|curriculum|vitae|profile)([\s_\-.]|$)',
    ).hasMatch(normalized);

    if (looksLikeCv) {
      return null;
    }

    return 'This file does not appear to be a CV or resume. Please upload a valid CV PDF.';
  }
}

class CVMatchScope extends InheritedNotifier<CVMatchState> {
  const CVMatchScope({
    required CVMatchState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static CVMatchState of(BuildContext context, {bool listen = true}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<CVMatchScope>()
        : context
                  .getElementForInheritedWidgetOfExactType<CVMatchScope>()
                  ?.widget
              as CVMatchScope?;

    assert(scope != null, 'CVMatchScope was not found in the widget tree.');
    return scope!.notifier!;
  }
}
