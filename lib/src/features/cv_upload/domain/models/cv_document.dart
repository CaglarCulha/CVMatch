class CvDocument {
  const CvDocument({
    required this.fileName,
    required this.fileSize,
    required this.extractedText,
    required this.pageCount,
    required this.extractionSucceeded,
  });

  final String fileName;
  final int? fileSize;
  final String extractedText;
  final int pageCount;
  final bool extractionSucceeded;
}
