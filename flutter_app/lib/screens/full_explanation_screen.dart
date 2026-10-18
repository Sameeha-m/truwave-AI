import 'package:flutter/material.dart';

import '../database/source_model.dart';
import '../database/verification_model.dart';

class FullExplanationScreen extends StatelessWidget {
  final Verification verification;
  final List<VerificationSource> sources;

  const FullExplanationScreen({
    super.key,
    required this.verification,
    required this.sources,
  });

  Color _verdictColor(String verdict) {
    switch (verdict) {
      case 'REAL':
        return const Color(0xFF18A270);
      case 'FAKE':
        return const Color(0xFFFA3C37);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  bool _summaryExplainsUncertainty(String summary) {
    final text = summary.toLowerCase();
    return const [
      'uncertain',
      'uncertainty',
      'not enough',
      'insufficient',
      'couldn’t',
      "couldn't",
      'could not',
      'cannot',
      "can't",
      'conflict',
      'disagree',
      'less certain',
      'no matching',
      'no fact-check',
      'no fact check',
      'not a clear verdict',
      'clear verdict',
    ].any(text.contains);
  }

  @override
  Widget build(BuildContext context) {
    final verdict = verification.verdict.trim().toUpperCase();
    final verdictColor = _verdictColor(verdict);
    final confidence = verification.confidence;
    final validConfidence =
        confidence.isFinite && confidence >= 0 && confidence <= 1;
    final summary = verification.summary.trim();
    final explainUncertainty =
        verdict == 'UNCERTAIN' && !_summaryExplainsUncertainty(summary);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    key: const Key('full-explanation-back'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Full Explanation',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF171922),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE6E9F1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR CLAIM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6847EE),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      verification.claim.trim().isEmpty
                          ? 'Claim unavailable'
                          : verification.claim,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF171922),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: verdictColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        verdict.isEmpty ? 'UNCERTAIN' : verdict,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: verdictColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Confidence in this classification',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF171922),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      validConfidence
                          ? '${(confidence * 100).round()}%'
                          : 'Not available',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: verdictColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'This is TruWave’s confidence in its classification, not '
                      'the probability that the claim is true.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: Color(0xFF777E8B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle('Summary'),
              const SizedBox(height: 8),
              Text(
                summary.isEmpty ? 'No summary was provided.' : summary,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.45,
                  color: Color(0xFF343945),
                ),
              ),
              if (explainUncertainty) ...[
                const SizedBox(height: 12),
                _informationNote(
                  'The available evidence did not support a clear REAL or '
                  'FAKE verdict.',
                ),
              ],
              const SizedBox(height: 24),
              _sectionTitle('Key Findings'),
              const SizedBox(height: 8),
              if (verification.findings.isEmpty)
                const Text(
                  'No findings were provided.',
                  style: TextStyle(fontSize: 15, color: Color(0xFF777E8B)),
                )
              else
                ...verification.findings.map(
                  (finding) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: verdictColor,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            finding,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Color(0xFF343945),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              _sectionTitle('Sources we checked'),
              const SizedBox(height: 8),
              if (sources.isEmpty)
                const Text(
                  'No fact-checks found',
                  key: Key('no-fact-checks-found'),
                  style: TextStyle(fontSize: 15, color: Color(0xFF777E8B)),
                )
              else
                ...sources.indexed.map(
                  (entry) => _sourceCard(entry.$1, entry.$2),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Color(0xFF171922),
    ),
  );

  Widget _informationNote(String text) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7E6),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.4,
        color: Color(0xFF76520B),
      ),
    ),
  );

  Widget _sourceCard(int index, VerificationSource source) {
    final name = source.name.trim();
    final title = source.title.trim();
    final url = source.url.trim();

    return Container(
      key: ValueKey('explanation-source-$index'),
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6E9F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF171922),
              ),
            ),
          if (title.isNotEmpty) ...[
            if (name.isNotEmpty) const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF555C68),
              ),
            ),
          ],
          if (url.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              url,
              key: ValueKey('explanation-source-url-$index'),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6847EE),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
          if (name.isEmpty && title.isEmpty && url.isEmpty)
            const Text(
              'Source details unavailable.',
              style: TextStyle(fontSize: 14, color: Color(0xFF777E8B)),
            ),
        ],
      ),
    );
  }
}
