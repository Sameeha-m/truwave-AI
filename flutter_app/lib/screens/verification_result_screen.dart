import 'package:flutter/material.dart';

class VerificationResultScreen extends StatelessWidget {
  const VerificationResultScreen({super.key});

  final List<String> findings = const [
    'Confirmed by 4+ credible sources',
    'Matched with official statements',
    'No evidence found against this claim',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 28,
                      color: Color(0xFF191C21),
                    ),
                  ),
                  const Text(
                    'Verification Result',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF191C21),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                    icon: const Icon(
                      Icons.info_outline,
                      size: 26,
                      color: Color(0xFF6E7582),
                    ),
                  ),
                ],
              ),

              // Result section
              const SizedBox(height: 28),

              Center(
                child: Column(
                  children: [
                    // Green result illustration
                    Container(
                      width: 192,
                      height: 144,
                      decoration: BoxDecoration(
                        color: const Color(0xFF18A270),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      'This news is likely',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF18A270),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'REAL',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: Color(0xFF18A270),
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'Confidence Score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF23252A),
                      ),
                    ),

                    const SizedBox(height: 2),

                    const Text(
                      '82%',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                        color: Color(0xFF191C21),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Confidence bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: double.infinity,
                        height: 8,
                        child: Stack(
                          children: [
                            Container(
                              color: const Color(0xFFE5E9F2),
                            ),
                            FractionallySizedBox(
                              widthFactor: 0.82,
                              child: Container(
                                color: const Color(0xFF18A270),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Why we think so
              const Text(
                'Why we think so',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C21),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Multiple credible sources report similar information. '
                'The claim aligns with verified facts and trusted news outlets.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.35,
                  color: Color(0xFF6E7582),
                ),
              ),

              const SizedBox(height: 24),

              // Key findings
              const Text(
                'Key Findings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C21),
                ),
              ),

              const SizedBox(height: 8),

              ...findings.map(
                (finding) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.check,
                          size: 16,
                          color: Color(0xFF18A270),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          finding,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF23252A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sources
              const Text(
                'Sources we checked',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191C21),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  _SourceCircle(
                    color: const Color(0xFF6346E9),
                  ),
                  const SizedBox(width: 16),
                  _SourceCircle(
                    color: Colors.white,
                    border: true,
                  ),
                  const SizedBox(width: 16),
                  _SourceCircle(
                    color: const Color(0xFF18A270),
                  ),
                  const SizedBox(width: 16),
                  _SourceCircle(
                    color: const Color(0xFF37A2EB),
                  ),
                  const SizedBox(width: 16),
                  _SourceCircle(
                    color: const Color(0xFF6346E9),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Explanation button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF087949),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
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
  final bool border;

  const _SourceCircle({
    required this.color,
    this.border = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: border
            ? Border.all(
                color: const Color(0xFFD1D5DB),
              )
            : null,
      ),
    );
  }
}