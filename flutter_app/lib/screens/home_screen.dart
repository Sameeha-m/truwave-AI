import 'package:flutter/material.dart';

import '../database/database_helper.dart';
import '../database/verification_model.dart';
import '../widgets/shared_history_widgets.dart';
import 'image_scan_screen.dart';
import 'history_screen.dart';
import 'verify_news_screen.dart';
import 'verification_result_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  late Future<List<Verification>> _recentChecks;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _loadRecentChecks();
  }

  void _loadRecentChecks() {
    _recentChecks = DatabaseHelper.instance.getVerifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      if (_route != null) appRouteObserver.unsubscribe(this);
      _route = route;
      if (route != null) appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    setState(_loadRecentChecks);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

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
                        Text('👋', style: TextStyle(fontSize: 22)),
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
                      style: TextStyle(fontSize: 18, color: Color(0xFF7C8295)),
                    ),

                    const SizedBox(height: 20),

                    // VERIFY NEWS
                    _VerifyCard(
                      title: 'Verify News',
                      description: 'Paste text to verify a news claim',
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
                      description: 'Check if an image is AI-generated or not',
                      backgroundColor: const Color(0xFF077546),
                      icon: const _ImageIcon(),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ImageScanScreen(),
                        ),
                      ),
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
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HistoryScreen(),
                            ),
                          ),
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

                    FutureBuilder<List<Verification>>(
                      future: _recentChecks,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const SizedBox.shrink();
                        }
                        if (snapshot.hasError) {
                          return const Text('Could not load recent checks.');
                        }
                        final recent = (snapshot.data ?? []).take(3).toList();
                        if (recent.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No checks yet',
                              style: TextStyle(color: Color(0xFF7C8295)),
                            ),
                          );
                        }
                        return Column(
                          children: recent
                              .map(
                                (verification) => VerificationHistoryCard(
                                  verification: verification,
                                  onTap: () => _openVerification(verification),
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
          ],
        ),
      ),

      // BOTTOM NAVIGATION
      bottomNavigationBar: SharedBottomNavigationBar(
        onHome: () => Navigator.popUntil(context, (route) => route == _route),
        onHistory: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
        ),
        onPlus: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const VerifyNewsScreen()),
        ),
      ),
    );
  }

  Future<void> _openVerification(Verification verification) async {
    final id = verification.id;
    if (id == null) return;
    final sources = await DatabaseHelper.instance.getSources(id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => VerificationResultScreen(
          verification: verification,
          sources: sources,
        ),
      ),
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
                    style: const TextStyle(fontSize: 16, color: Colors.white),
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
// NEWS ICON
// ============================================================

class _NewsIcon extends StatelessWidget {
  const _NewsIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(32, 32), painter: _NewsIconPainter());
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
    return CustomPaint(size: const Size(32, 32), painter: _ImageIconPainter());
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

    canvas.drawLine(const Offset(7, 25), const Offset(25, 7), paint);

    canvas.drawLine(const Offset(11, 25), const Offset(25, 11), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
