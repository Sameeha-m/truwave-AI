import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/verification_model.dart';
import 'verify_news_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<Verification>> _history;

  @override
  void initState() {
    super.initState();
    _history = DatabaseHelper.instance.getVerifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'History',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181A20),
                ),
              ),

              const SizedBox(height: 24),

              // Search bar
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    SizedBox(width: 16),
                    Icon(Icons.search, size: 20, color: Color(0xFF8C93A3)),
                    SizedBox(width: 10),
                    Text(
                      'Search your verifications...',
                      style: TextStyle(fontSize: 16, color: Color(0xFF8C93A3)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              FutureBuilder<List<Verification>>(
                future: _history,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final verifications = snapshot.data ?? [];
                  if (verifications.isEmpty) {
                    return const Text('No saved verifications yet.');
                  }
                  return Column(
                    children: verifications
                        .map(
                          (verification) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _HistoryCard(verification: verification),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: const _HistoryBottomNavigation(),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final Verification verification;

  const _HistoryCard({required this.verification});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Thumbnail placeholder
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE3E6F0),
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          const SizedBox(width: 16),

          // Title + verdict
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  verification.claim,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181A20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  verification.verdict,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: verification.verdict == 'REAL'
                        ? const Color(0xFF15803D)
                        : verification.verdict == 'FAKE'
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFF97316),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Confidence
          Text(
            '${(verification.confidence * 100).round()}%',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8C93A3),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBottomNavigation extends StatelessWidget {
  const _HistoryBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      decoration: const BoxDecoration(
        color: Color(0xFFFAFBFD),
        border: Border(top: BorderSide(color: Color(0xFFE3E6F0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
            ),

            _NavItem(icon: Icons.history, label: 'History', active: true),

            // Central +
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: const Offset(0, -28),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const VerifyNewsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF633BDF),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFFAFBFD),
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x25000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            _NavItem(icon: Icons.access_time, label: 'Insights'),

            _NavItem(icon: Icons.person_outline, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF633BDF) : const Color(0xFF8C93A3);

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 28, color: color),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            height: 1,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );

    return Expanded(
      child: onTap == null
          ? content
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: content,
            ),
    );
  }
}
