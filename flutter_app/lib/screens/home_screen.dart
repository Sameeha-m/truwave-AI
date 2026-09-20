import 'package:flutter/material.dart';
import 'verify_news_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TruWave',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6133F5),
                    ),
                  ),
                  const Icon(
                    Icons.settings_outlined,
                    size: 25,
                    color: Color(0xFF7C8295),
                  ),
                ],
              ),
            ),

            // MAIN CONTENT
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // GREETING
                    const Row(
                      children: [
                        Text(
                          'Good morning!',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7C8295),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '👋',
                          style: TextStyle(fontSize: 22),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // TITLE
                    const Text(
                      'What would you like to verify today?',
                      style: TextStyle(
                        fontSize: 30,
                        height: 1.15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF161C26),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // SUBTITLE
                    const Text(
                      'Fast, private and reliable results.',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF7C8295),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // VERIFY NEWS
                    _VerifyCard(
                      title: 'Verify News',
                      description:
                          'Paste text or link to verify any news claim',
                      backgroundColor: const Color(0xFF6133F5),
                      icon: const _NewsIcon(),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VerifyNewsScreen(),
                          ),
                        );
                      },
  
                    ),

                    const SizedBox(height: 16),

                    // VERIFY IMAGE
                    _VerifyCard(
                      title: 'Verify Image',
                      description:
                          'Check if an image is AI-generated or not',
                      backgroundColor: const Color(0xFF077546),
                      icon: const _ImageIcon(),
                      onTap: () {},
                    ),

                    const SizedBox(height: 32),

                    // RECENT CHECKS HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent checks',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF171C23),
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'View all',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6133F5),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // RECENT CHECK
                    const _RecentCheckCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: const _BottomNavigation(),
    );
  }
}

// ============================================================
// VERIFY CARD
// ============================================================

class _VerifyCard extends StatelessWidget {
  final String title;
  final String description;
  final Color backgroundColor;
  final Widget icon;
  final VoidCallback onTap;

  const _VerifyCard({
    required this.title,
    required this.description,
    required this.backgroundColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            icon,
          ],
        ),
      ),
    );
  }
}

// ============================================================
// RECENT CHECK CARD
// ============================================================

class _RecentCheckCard extends StatelessWidget {
  const _RecentCheckCard();

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
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const _RecentCheckIcon(),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GOVERNANCE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Breaking: Govt plans new tax reform in July',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF161C26),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'FAKE',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF35945),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// BOTTOM NAVIGATION
// ============================================================

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        border: Border(
          top: BorderSide(
            color: Color(0xFFEBECF0),
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
              active: true,
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
              onTap: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                 builder: (context) => const HistoryScreen(),
                ),
               );
             },
            ),

            // CENTRAL PLUS BUTTON
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: GestureDetector(
                    onTap: () {Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VerifyNewsScreen(),
                      ),
                    );
                  },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6133F5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFF8F9FB),
                          width: 4,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x30000000),
                            blurRadius: 8,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            _NavItem(
              icon: Icons.bar_chart_outlined,
              label: 'Insights',
              onTap: () {},
            ),

            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NAVIGATION ITEM
// ============================================================

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = active
        ? const Color(0xFF6133F5)
        : const Color(0xFF7C8295);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NEWS ICON
// ============================================================

class _NewsIcon extends StatelessWidget {
  const _NewsIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 32),
      painter: _NewsIconPainter(),
    );
  }
}

class _NewsIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 10, 18, 2),
        const Radius.circular(1),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 15, 18, 2),
        const Radius.circular(1),
      ),
      paint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 20, 12, 2),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// IMAGE ICON
// ============================================================

class _ImageIcon extends StatelessWidget {
  const _ImageIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 32),
      painter: _ImageIconPainter(),
    );
  }
}

class _ImageIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 7, 18, 18),
        const Radius.circular(2),
      ),
      paint,
    );

    canvas.drawLine(
      const Offset(7, 25),
      const Offset(25, 7),
      paint,
    );

    canvas.drawLine(
      const Offset(11, 25),
      const Offset(25, 11),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

// ============================================================
// RECENT CHECK ICON
// ============================================================

class _RecentCheckIcon extends StatelessWidget {
  const _RecentCheckIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(32, 32),
      painter: _RecentCheckIconPainter(),
    );
  }
}

class _RecentCheckIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint darkPaint = Paint()
      ..color = const Color(0xFF2E3A74);

    final Paint redPaint = Paint()
      ..color = const Color(0xFFF35945);

    final Paint blackPaint = Paint()
      ..color = Colors.black;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 16, 24, 10),
        const Radius.circular(2),
      ),
      darkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 10, 16, 6),
        const Radius.circular(2),
      ),
      redPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 6, 8, 4),
        const Radius.circular(2),
      ),
      blackPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}