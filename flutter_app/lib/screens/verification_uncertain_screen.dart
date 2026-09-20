import 'package:flutter/material.dart';

class VerificationUncertainScreen extends StatelessWidget {
  const VerificationUncertainScreen({super.key});

  final List<String> keyFindings = const [
    'Limited or conflicting information',
    'Sources are not fully reliable',
    'Further verification recommended',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    padding: const EdgeInsets.only(left: 4, right: 20),
                    constraints: const BoxConstraints(),
                    onPressed: () {},
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 28,
                      color: Color(0xFF15171A),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Verification Result',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15171A),
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
                      size: 27,
                      color: Color(0xFF888D97),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),

                      // UNCERTAIN illustration
                      Container(
                        width: 192,
                        height: 128,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Center(
                          child: Text(
                            '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'This news is',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFF59E0B),
                        ),
                      ),

                      const SizedBox(height: 2),

                      const Text(
                        'UNCERTAIN',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: Color(0xFFF59E0B),
                        ),
                      ),

                      const SizedBox(height: 24),

                      const Text(
                        'Confidence Score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF15171A),
                        ),
                      ),

                      const SizedBox(height: 2),

                      const Text(
                        '45%',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF15171A),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Confidence bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 8,
                          child: Stack(
                            children: [
                              Container(
                                color: const Color(0xFFE4E6ED),
                              ),
                              FractionallySizedBox(
                                widthFactor: 0.45,
                                child: Container(
                                  color: const Color(0xFFF59E0B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Why we think so
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Why we think so',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15171A),
                          ),
                        ),
                      ),

                      const SizedBox(height: 4),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'There isn’t enough reliable information available yet. '
                          'More evidence is needed to verify this claim.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.4,
                            color: Color(0xFF6A6F7B),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Key findings
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Key Findings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF15171A),
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: keyFindings.map((finding) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6A6F7B),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      finding,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF6A6F7B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),

              // Full explanation button
              SizedBox(
                width: double.infinity,
                height: 80,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
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