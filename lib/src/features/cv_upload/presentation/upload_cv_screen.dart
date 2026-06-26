import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_routes.dart';
import '../../../app/cvmatch_state.dart';
import '../domain/models/cv_document.dart';
import '../domain/services/pdf_extraction_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_page.dart';
import '../../../shared/widgets/status_chip.dart';

class UploadCVScreen extends StatefulWidget {
  const UploadCVScreen({super.key});

  @override
  State<UploadCVScreen> createState() => _UploadCVScreenState();
}

class _UploadCVScreenState extends State<UploadCVScreen> {
  final _pdfExtractionService = const PdfExtractionService();
  String? _errorText;
  bool _isPicking = false;

  bool get _isBusy => _isPicking;

  Future<void> _pickPdf() async {
    setState(() {
      _errorText = null;
      _isPicking = true;
    });

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: true,
      );

      if (!mounted) return;

      final file = result?.files.singleOrNull;
      if (file == null) {
        setState(() {
          _isPicking = false;
        });
        return;
      }

      if (!file.name.toLowerCase().endsWith('.pdf')) {
        setState(() {
          _errorText = 'Please select a PDF file.';
          _isPicking = false;
        });
        return;
      }

      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        setState(() {
          _errorText = 'No readable text was found in this PDF.';
          _isPicking = false;
        });
        return;
      }

      final document = await _pdfExtractionService.extractBytes(
        fileName: file.name,
        fileSize: file.size > 0 ? file.size : null,
        bytes: bytes,
      );

      if (!mounted) return;

      CVMatchScope.of(context, listen: false).setSelectedCv(
        document: document,
        filePath: file.path ?? file.identifier ?? file.name,
      );

      setState(() {
        _isPicking = false;
      });
    } on PdfExtractionException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = error.message;
        _isPicking = false;
      });
    } on PlatformException catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Could not open the file picker. Please try again.';
        _isPicking = false;
      });
    }
  }

  void _continueToJobDescription() {
    final appState = CVMatchScope.of(context, listen: false);

    if (!appState.hasSelectedPdf) {
      setState(() {
        _errorText = 'Select a PDF CV before continuing.';
      });
      return;
    }

    if (!appState.hasValidCv) {
      setState(() {
        _errorText =
            appState.cvValidationWarning ??
            'This file does not appear to be a CV or resume. Please upload a valid CV PDF.';
      });
      return;
    }

    Navigator.pushNamed(context, AppRoutes.jobDescription);
  }

  @override
  Widget build(BuildContext context) {
    final appState = CVMatchScope.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final selectedFileName = appState.selectedCvFileName;
    final selectedFileSize = appState.selectedCvFileSizeBytes;
    final validationWarning = appState.cvValidationWarning;
    final document = appState.cvDocument;

    return AppPage(
      title: 'Upload CV',
      subtitle:
          'Select a local PDF CV. The file stays on device and is only used for this mock flow.',
      children: [
        AppCard(
          color: colorScheme.primary.withValues(alpha: 0.06),
          borderColor: colorScheme.primary.withValues(alpha: 0.14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selectedFileName == null
                    ? Icons.cloud_upload_outlined
                    : Icons.picture_as_pdf_outlined,
                color: colorScheme.primary,
                size: 42,
              ),
              const SizedBox(height: 16),
              Text(
                selectedFileName == null ? 'Select your CV PDF' : 'CV selected',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                selectedFileName ?? 'No PDF selected yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: selectedFileName == null
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  fontWeight: selectedFileName == null
                      ? FontWeight.w500
                      : FontWeight.w800,
                ),
              ),
              if (selectedFileSize != null) ...[
                const SizedBox(height: 6),
                Text(
                  _formatFileSize(selectedFileSize),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (selectedFileName != null) ...[
                const SizedBox(height: 14),
                StatusChip(
                  label: validationWarning ?? 'PDF selected successfully',
                  icon: validationWarning == null
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_outlined,
                  color: validationWarning == null
                      ? colorScheme.primary
                      : colorScheme.error,
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('select_pdf_button'),
                onPressed: _isBusy ? null : _pickPdf,
                icon: Icon(
                  _isPicking
                      ? Icons.hourglass_empty_outlined
                      : Icons.upload_file_outlined,
                ),
                label: Text(_isPicking ? 'Extracting text...' : 'Select PDF'),
              ),
              if (_isPicking) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    color: colorScheme.primary,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (kDebugMode && document != null) ...[
          const SizedBox(height: 16),
          _DebugExtractionCard(document: document),
        ],
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _continueToJobDescription,
          icon: const Icon(Icons.description_outlined),
          label: const Text('Continue to job description'),
        ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    }
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _DebugExtractionCard extends StatelessWidget {
  const _DebugExtractionCard({required this.document});

  final CvDocument document;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final text = document.extractedText;
    final preview = text.length <= 300 ? text : '${text.substring(0, 300)}...';

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: colorScheme.tertiary.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusChip(
            label: 'Debug extraction',
            icon: Icons.bug_report_outlined,
            color: colorScheme.tertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Characters: ${text.length}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Pages: ${document.pageCount}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Text(
            preview,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
