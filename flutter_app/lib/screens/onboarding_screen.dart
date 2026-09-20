import 'package:flutter/material.dart';
import 'home_screen.dart';

class TruWaveOnboarding extends StatelessWidget {
  const TruWaveOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 40, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─────────────────────────
                // HEADER
                // ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TruWave',
                      style: TextStyle(
                        fontSize: 48,
                        height: 56 / 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1.5,
                        color: Color(0xFF623EEE),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 18,
                            height: 28 / 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ─────────────────────────
                // ILLUSTRATION
                // ─────────────────────────
                Center(
                  child: Container(
                    width: 350,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9FBFA),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Center(
                      child: Container(
                        width: 180,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFF623EEE),
                          borderRadius: BorderRadius.circular(80),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.bolt,
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ─────────────────────────
                // TITLE
                // ─────────────────────────
                const Text(
                  'Know before you share.',
                  style: TextStyle(
                    fontSize: 40,
                    height: 44 / 40,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1.2,
                    color: Color(0xFF232D3B),
                  ),
                ),

                const SizedBox(height: 16),

                // ─────────────────────────
                // DESCRIPTION
                // ─────────────────────────
                const Text(
                  'Verify news claims and images, then\n'
                  'understand the evidence in plain language.',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),

                const SizedBox(height: 36),

                // ─────────────────────────
                // FEATURE 1
                // ─────────────────────────
                _FeatureCard(
                  icon: Icons.content_paste_search,
                  text: 'Clear verdict + confidence score',
                ),

                const SizedBox(height: 16),

                // ─────────────────────────
                // FEATURE 2
                // ─────────────────────────
                _FeatureCard(
                  icon: Icons.description_outlined,
                  text: 'Evidence you can understand',
                ),

                const SizedBox(height: 40),

                // ─────────────────────────
                // GET STARTED
                // ─────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                      builder: (context) => const HomeScreen(),
                      ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF623EEE),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 4,
                    ),
                    child: const Text(
                      'Get started',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─────────────────────────
                // FOOTER
                // ─────────────────────────
                const Center(
                  child: Text(
                    'Private by design • No forced verdicts',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────
// FEATURE CARD
// ─────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureCard({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 40,
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232D3B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}