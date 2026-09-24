class VerificationSource {
  final int? id;
  final int verificationId;
  final String name;
  final String title;
  final String url;

  VerificationSource({
    this.id,
    required this.verificationId,
    required this.name,
    required this.title,
    required this.url,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'verification_id': verificationId,
      'name': name,
      'title': title,
      'url': url,
    };
  }

  factory VerificationSource.fromMap(Map<String, Object?> map) {
    return VerificationSource(
      id: map['id'] as int?,
      verificationId: map['verification_id'] as int,
      name: map['name'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
    );
  }

  factory VerificationSource.fromApiMap(Map<String, dynamic> map) {
    return VerificationSource(
      verificationId: 0,
      name: map['name'] as String,
      title: map['title'] as String,
      url: map['url'] as String,
    );
  }
}
