import 'package:flutter/material.dart';

class VerificationFakeScreen extends StatelessWidget {
  const VerificationFakeScreen({super.key});

  final List<String> keyFindings = const [
    'Contradicted by official sources',
    'Similar claims were debunked before',
    'Source is not credible',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 28, 16, 16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    padding: const EdgeInsets.only(left: 4, right: 20),
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 28,
                      color: Color(0xFF17191C),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Verification Result',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF17191C),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.only(left: 20, right: 4),
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                    icon: const Icon(
                      Icons.info_outline,
                      size: 26,
                      color: Color(0xFF70757A),
                    ),
                  ),
                ],
              ),

              // Main content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 32),

                      // FAKE illustration
                      Container(
                        width: 240,
                        height: 128,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFA3C37),
                          borderRadius: BorderRadius.circular(48),
                        ),
                        child: const Center(
                          child: Text(
                            '×',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 72,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'This news is likely',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFA3C37),
                        ),
                      ),

                      const SizedBox(height: 2),

                      const Text(
                        'FAKE',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFFA3C37),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Confidence Score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF17191C),
                        ),
                      ),

                      const SizedBox(height: 2),

                      const Text(
                        '91%',
                        style: TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17191C),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Confidence bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 12,
                          child: Stack(
                            children: [
                              Container(
                                color: const Color(0xFFE5E7EB),
                              ),
                              FractionallySizedBox(
                                widthFactor: 0.91,
                                child: Container(
                                  color: const Color(0xFFFA3C37),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Explanation
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Why we think so',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF17191C),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'The claim contradicts verified facts and credible '
                          'sources. Matching patterns of disinformation were found.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.35,
                            color: Color(0xFF70757A),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Key findings
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Key Findings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF17191C),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: keyFindings.map(
                            (finding) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: Text(
                                  '× $finding',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF70757A),
                                  ),
                                ),
                              );
                            },
                          ).toList(),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Sources
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Sources we checked',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF17191C),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            _SourceCircle(
                              color: Color(0xFF573BF7),
                            ),
                            SizedBox(width: 16),
                            _SourceCircle(
                              color: Colors.white,
                              bordered: true,
                            ),
                            SizedBox(width: 16),
                            _SourceCircle(
                              color: Color(0xFF15C495),
                            ),
                            SizedBox(width: 16),
                            _SourceCircle(
                              color: Color(0xFF368FFF),
                            ),
                            SizedBox(width: 16),
                            _SourceCircle(
                              color: Color(0xFF573BF7),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Full explanation button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFA3C37),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'View Full Explanation',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SourceCircle extends StatelessWidget {
  final Color color;
  final bool bordered;

  const _SourceCircle({
    required this.color,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: bordered
            ? Border.all(
                color: const Color(0xFFE5E7EB),
              )
            : null,
      ),
    );
  }
}