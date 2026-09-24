class Verification {
  final int? id;
  final String claim;
  final String verdict;
  final double confidence;
  final String summary;
  final List<String> findings;
  final DateTime createdAt;

  Verification({
    this.id,
    required this.claim,
    required this.verdict,
    required this.confidence,
    required this.summary,
    required this.findings,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'claim': claim,
      'verdict': verdict,
      'confidence': confidence,
      'summary': summary,
      'findings': findings,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Verification.fromMap(Map<String, dynamic> map) {
    return Verification(
      id: map['id'] as int?,
      claim: map['claim'] as String,
      verdict: map['verdict'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      summary: map['summary'] as String,
      findings: List<String>.from(map['findings'] as List<dynamic>),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Verification.fromApiResponse(String claim, Map<String, dynamic> map) {
    return Verification(
      claim: claim,
      verdict: map['verdict'] as String,
      confidence: (map['confidence'] as num).toDouble(),
      summary: map['summary'] as String,
      findings: List<String>.from(map['findings'] as List<dynamic>),
      createdAt: DateTime.now(),
    );
  }
}
