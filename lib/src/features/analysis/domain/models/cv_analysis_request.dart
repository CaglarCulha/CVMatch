class CvAnalysisRequest {
  const CvAnalysisRequest({
    required this.cvFileName,
    required this.cvFilePath,
    required this.jobDescription,
    this.cvText,
    this.isCvValid = true,
  });

  final String cvFileName;
  final String cvFilePath;
  final String jobDescription;
  final String? cvText;
  final bool isCvValid;
}
