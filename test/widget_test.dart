import 'package:cvmatch/src/app/cvmatch_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const filePickerChannel = MethodChannel(
    'miguelruivo.flutter.plugins.filepicker',
    StandardMethodCodec(),
  );
  var pickedFileName = 'Derya_Kaya_CV.pdf';
  var pickedFilePath = '/tmp/Derya_Kaya_CV.pdf';
  var pickedFileSize = 2048;
  late Uint8List pickedBytes;

  setUp(() {
    pickedFileName = 'Derya_Kaya_CV.pdf';
    pickedFilePath = '/tmp/Derya_Kaya_CV.pdf';
    pickedBytes = _sampleCvPdfBytes();
    pickedFileSize = pickedBytes.length;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(filePickerChannel, (methodCall) async {
          if (methodCall.method != 'custom') return null;

          return [
            {
              'path': pickedFilePath,
              'name': pickedFileName,
              'size': pickedFileSize,
              'bytes': pickedBytes,
            },
          ];
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(filePickerChannel, null);
  });

  testWidgets('CVMatch mock flow navigates between MVP screens', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const CVMatchApp());

    expect(find.text('CVMatch'), findsOneWidget);

    await tester.tap(find.byKey(const Key('login_continue_button')));
    await tester.pumpAndSettle();
    expect(find.text('Career readiness dashboard'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Upload CV'));
    await tester.pumpAndSettle();
    expect(find.text('Select your CV PDF'), findsOneWidget);

    final continueButton = find.widgetWithText(
      FilledButton,
      'Continue to job description',
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.text('Select a PDF CV before continuing.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('select_pdf_button')));
    await tester.pumpAndSettle();
    expect(find.text('Derya_Kaya_CV.pdf'), findsOneWidget);
    expect(find.textContaining('KB'), findsWidgets);
    expect(find.text('PDF selected successfully'), findsOneWidget);
    expect(find.text('/tmp/Derya_Kaya_CV.pdf'), findsNothing);

    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
    expect(find.text('Matching focus'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Too short');
    await tester.pumpAndSettle();

    final analyzeButton = find.byKey(const Key('analyze_match_button'));
    await tester.ensureVisible(analyzeButton);
    await tester.tap(analyzeButton);
    await tester.pumpAndSettle();
    expect(
      find.text('Add at least 100 characters to analyze this job description.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byType(TextField),
      'Northstar Labs is hiring a senior AI product manager to lead discovery, '
      'partner with engineering, define measurable workflows, and launch '
      'trusted assistant experiences for enterprise customers.',
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(analyzeButton);
    await tester.tap(analyzeButton);
    await tester.pump();
    expect(find.text('Analyzing...'), findsOneWidget);
    expect(find.text('Analyzing your CV...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();
    expect(find.text('Score breakdown'), findsOneWidget);
    expect(find.text('Derya_Kaya_CV.pdf'), findsOneWidget);
    expect(find.text('Analysis inputs'), findsOneWidget);
    expect(find.text('Cover letter draft'), findsOneWidget);
    expect(find.text('Interview questions'), findsOneWidget);
    expect(
      find.text('Mock analysis - configure a backend API for real AI scoring.'),
      findsOneWidget,
    );

    final unlockButton = find.widgetWithText(
      FilledButton,
      'Unlock full rewrite',
    );
    await tester.ensureVisible(unlockButton);
    await tester.tap(unlockButton);
    await tester.pumpAndSettle();
    expect(find.text('Pro plan'), findsOneWidget);
  });

  testWidgets('blocks PDFs that do not look like a CV or resume', (
    WidgetTester tester,
  ) async {
    pickedFileName = 'invoice.pdf';
    pickedFilePath = '/tmp/invoice.pdf';
    pickedBytes = _sampleCvPdfBytes();
    pickedFileSize = pickedBytes.length;

    await tester.pumpWidget(const CVMatchApp());

    await tester.tap(find.byKey(const Key('login_continue_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Upload CV'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('select_pdf_button')));
    await tester.pumpAndSettle();

    expect(find.text('invoice.pdf'), findsOneWidget);
    expect(find.textContaining('KB'), findsWidgets);
    expect(find.text('/tmp/invoice.pdf'), findsNothing);
    expect(
      find.text(
        'This file does not appear to be a CV or resume. Please upload a valid CV PDF.',
      ),
      findsOneWidget,
    );

    final continueButton = find.widgetWithText(
      FilledButton,
      'Continue to job description',
    );
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    expect(find.text('Job Description'), findsNothing);
  });
}

Uint8List _sampleCvPdfBytes() {
  final document = PdfDocument();
  final page = document.pages.add();
  page.graphics.drawString(
    'Derya Kaya CV resume product discovery roadmap planning AI workflows '
    'prompt testing model evaluation activation metrics stakeholder leadership '
    'launch strategy customer discovery experiments trust automation.',
    PdfStandardFont(PdfFontFamily.helvetica, 12),
  );
  final bytes = Uint8List.fromList(document.saveSync());
  document.dispose();
  return bytes;
}
