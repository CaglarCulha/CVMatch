class CvAnalysisResult {
  const CvAnalysisResult({
    required this.matchScore,
    required this.atsScore,
    required this.missingKeywords,
    required this.strongPoints,
    required this.weakPoints,
    required this.suggestedImprovements,
    required this.coverLetter,
    required this.interviewQuestions,
  });

  final int matchScore;
  final int atsScore;
  final List<String> missingKeywords;
  final List<String> strongPoints;
  final List<String> weakPoints;
  final List<String> suggestedImprovements;
  final String coverLetter;
  final List<String> interviewQuestions;

  factory CvAnalysisResult.fromJson(Map<String, dynamic> json) {
    return CvAnalysisResult(
      matchScore: _readInt(json, 'matchScore'),
      atsScore: _readInt(json, 'atsScore'),
      missingKeywords: _readStringList(json, 'missingKeywords'),
      strongPoints: _readStringList(json, 'strongPoints'),
      weakPoints: _readStringList(json, 'weakPoints'),
      suggestedImprovements: _readStringList(json, 'suggestedImprovements'),
      coverLetter: _readString(json, 'coverLetter'),
      interviewQuestions: _readStringList(json, 'interviewQuestions'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchScore': matchScore,
      'atsScore': atsScore,
      'missingKeywords': missingKeywords,
      'strongPoints': strongPoints,
      'weakPoints': weakPoints,
      'suggestedImprovements': suggestedImprovements,
      'coverLetter': coverLetter,
      'interviewQuestions': interviewQuestions,
    };
  }

  static int _readInt(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key)) {
      throw FormatException('Missing field: $key');
    }

    final value = json[key];
    if (value is int) {
      return value.clamp(0, 100);
    }
    if (value is num) {
      return value.round().clamp(0, 100);
    }
    if (value is String) {
      final parsed = num.tryParse(value.trim());
      if (parsed != null) {
        return parsed.round().clamp(0, 100);
      }
    }

    throw FormatException('Invalid integer field: $key');
  }

  static String _readString(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key)) {
      throw FormatException('Missing field: $key');
    }

    final value = json[key];
    if (value is String) {
      return value;
    }

    throw FormatException('Invalid string field: $key');
  }

  static List<String> _readStringList(Map<String, dynamic> json, String key) {
    if (!json.containsKey(key)) {
      throw FormatException('Missing field: $key');
    }

    final value = json[key];
    if (value is! List) {
      throw FormatException('Invalid list field: $key');
    }

    return List<String>.unmodifiable(
      value.map((item) {
        if (item is String) {
          return item;
        }
        throw FormatException('Invalid item in list field: $key');
      }),
    );
  }
}
