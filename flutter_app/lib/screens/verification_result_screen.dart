import 'package:flutter/material.dart';

import '../database/source_model.dart';
import '../database/verification_model.dart';

class VerificationResultScreen extends StatelessWidget {
  final Verification verification;
  final List<VerificationSource> sources;

  const VerificationResultScreen({
    super.key,
    required this.verification,
    required this.sources,
  });

  @override
  Widget build(BuildContext context) {
    final isReal = verification.verdict == 'REAL';
    final isFake = verification.verdict == 'FAKE';
    final resultColor = isReal
        ? const Color(0xFF18A270)
        : isFake
        ? const Color(0xFFFA3C37)
        : const Color(0xFFF59E0B);
    final resultIcon = isReal
        ? Icons.check
        : isFake
        ? Icons.close
        : Icons.question_mark;
    final confidence = verification.confidence.clamp(0.0, 1.0).toDouble();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 28),
                  ),
                  const Text(
                    'Verification Result',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.info_outline, size: 26),
                ],
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 192,
                      height: 144,
                      decoration: BoxDecoration(
                        color: resultColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Icon(resultIcon, color: Colors.white, size: 80),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      isFake ? 'This news is likely' : 'This news is',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: resultColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      verification.verdict,
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: resultColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Confidence Score'),
                    const SizedBox(height: 2),
                    Text(
                      '${(confidence * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 8,
                        child: Stack(
                          children: [
                            Container(color: const Color(0xFFE5E9F2)),
                            FractionallySizedBox(
                              widthFactor: confidence,
                              child: Container(color: resultColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Why we think so',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                verification.summary,
                style: const TextStyle(fontSize: 16, height: 1.35),
              ),
              const SizedBox(height: 24),
              const Text(
                'Key Findings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...verification.findings.map(
                (finding) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check, size: 16, color: resultColor),
                      const SizedBox(width: 8),
                      Expanded(child: Text(finding)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Sources we checked',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...sources.map(
                (source) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('${source.name}: ${source.title}'),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: resultColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  child: const Text('View Full Explanation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
