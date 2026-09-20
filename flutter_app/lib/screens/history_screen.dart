import 'package:flutter/material.dart';
import 'verify_news_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  final List<HistoryItem> items = const [
    HistoryItem(
      title: 'Breaking: Govt plans new tax reform in July',
      label: 'FAKE',
      labelColor: Color(0xFFEF4444),
      percent: '91%',
    ),
    HistoryItem(
      title: 'AI image of Taj Mahal sunset view',
      label: 'AI-GENERATED',
      labelColor: Color(0xFF9333EA),
      percent: '92%',
    ),
    HistoryItem(
      title: 'Local train tickets free for all in August?',
      label: 'UNCERTAIN',
      labelColor: Color(0xFFF97316),
      percent: '45%',
    ),
    HistoryItem(
      title: 'New app gives free recharge to users',
      label: 'REAL',
      labelColor: Color(0xFF15803D),
      percent: '79%',
    ),
    HistoryItem(
      title: 'Election result shared online',
      label: 'REAL',
      labelColor: Color(0xFF15803D),
      percent: '86%',
    ),
    HistoryItem(
      title: 'Celebrity quote goes viral',
      label: 'FAKE',
      labelColor: Color(0xFFEF4444),
      percent: '88%',
    ),
  ];

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
                    Icon(
                      Icons.search,
                      size: 20,
                      color: Color(0xFF8C93A3),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Search your verifications...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF8C93A3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // History items
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _HistoryCard(item: item),
                ),
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

class HistoryItem {
  final String title;
  final String label;
  final Color labelColor;
  final String percent;

  const HistoryItem({
    required this.title,
    required this.label,
    required this.labelColor,
    required this.percent,
  });
}

class _HistoryCard extends StatelessWidget {
  final HistoryItem item;

  const _HistoryCard({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 16,
        horizontal: 12,
      ),
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
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF181A20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: item.labelColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Confidence
          Text(
            item.percent,
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
        border: Border(
          top: BorderSide(
            color: Color(0xFFE3E6F0),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                Navigator.popUntil(
                  context,
                  (route) => route.isFirst,
                );
              },
            ),

            _NavItem(
              icon: Icons.history,
              label: 'History',
              active: true,
            ),

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

            _NavItem(
              icon: Icons.access_time,
              label: 'Insights',
            ),

            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
            ),
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
    final color = active
        ? const Color(0xFF633BDF)
        : const Color(0xFF8C93A3);

    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 28,
          color: color,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            height: 1,
            fontWeight:
                active ? FontWeight.w600 : FontWeight.normal,
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