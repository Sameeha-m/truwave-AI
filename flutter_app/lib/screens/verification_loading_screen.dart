import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../database/source_model.dart';
import '../database/verification_model.dart';
import '../services/verification_service.dart';
import 'verification_result_screen.dart';

class VerificationLoadingScreen extends StatefulWidget {
  final String claim;

  const VerificationLoadingScreen({super.key, required this.claim});

  @override
  State<VerificationLoadingScreen> createState() =>
      _VerificationLoadingScreenState();
}

class _VerificationLoadingScreenState extends State<VerificationLoadingScreen>
    with SingleTickerProviderStateMixin {
  final List<VerificationStep> steps = const [
    VerificationStep(
      label: 'Find reliable sources',
      status: VerificationStatus.done,
    ),
    VerificationStep(
      label: 'Compare evidence',
      status: VerificationStatus.active,
    ),
    VerificationStep(
      label: 'Preparing explanation',
      status: VerificationStatus.pending,
    ),
  ];

  late final AnimationController _loadingController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    _verifyClaim();
  }

  Future<void> _verifyClaim() async {
    try {
      final response = await VerificationService().verifyClaim(widget.claim);
      final verification = Verification.fromApiResponse(widget.claim, response);
      final sources = (response['sources'] as List<dynamic>)
          .map(
            (source) =>
                VerificationSource.fromApiMap(source as Map<String, dynamic>),
          )
          .toList();

      await DatabaseHelper.instance.insertVerification(verification, sources);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => VerificationResultScreen(
            verification: verification,
            sources: sources,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Verification failed. Check your connection and retry.',
          ),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  String get claimPreview {
    final words = widget.claim.split(RegExp(r'\s+'));

    if (words.length > 10) {
      return '${words.take(10).join(' ')}...';
    }

    return widget.claim;
  }

  Widget _buildLoadingRing() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        final pulse =
            0.96 + (0.04 * math.sin(_loadingController.value * math.pi * 2));
        final angle = _loadingController.value * math.pi * 2;

        return Transform.scale(
          scale: pulse,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: angle,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6847EE).withOpacity(0.28),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6847EE).withOpacity(0.12),
                        blurRadius: 26,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: -angle * 1.4,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF22C55E).withOpacity(0.42),
                      width: 2,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 24,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6847EE),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x336847EE),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 34,
                bottom: 38,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFD),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                const Text(
                  'TruWave',
                  style: TextStyle(
                    fontSize: 28,
                    height: 1,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6847EE),
                  ),
                ),

                const SizedBox(height: 36),

                // Heading
                const Text(
                  'Verification in progress',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF171922),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'We’re checking the claim against reliable sources.',
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.3,
                    color: Color(0xFF9096A2),
                  ),
                ),

                const SizedBox(height: 32),

                // Claim card
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
                        '“$claimPreview”',
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF171922),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36),

                // Verification illustration
                Center(
                  child: SizedBox(
                    width: 340,
                    height: 210,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [_buildLoadingRing()],
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // Verification steps
                Column(
                  children: List.generate(steps.length, (index) {
                    final step = steps[index];

                    return Column(
                      children: [
                        _VerificationStepRow(step: step),
                        if (index == 0)
                          const Padding(
                            padding: EdgeInsets.only(top: 12, bottom: 18),
                            child: Divider(color: Color(0xFFE6E9F1), height: 1),
                          )
                        else if (index < steps.length - 1)
                          const SizedBox(height: 28),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Privacy message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7FBF6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: Color(0xFF838A90),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your claim stays private while we verify.',
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.2,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF171922),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'We’ll show the evidence behind the result.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF8AB0A0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),

      // Bottom navigation
      bottomNavigationBar: const _LoadingBottomNavigation(),
    );
  }
}

enum VerificationStatus { done, active, pending }

class VerificationStep {
  final String label;
  final VerificationStatus status;

  const VerificationStep({required this.label, required this.status});
}

class _VerificationStepRow extends StatelessWidget {
  final VerificationStep step;

  const _VerificationStepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    Widget indicator;

    switch (step.status) {
      case VerificationStatus.done:
        indicator = const Icon(Icons.check, size: 20, color: Color(0xFF22C55E));
        break;

      case VerificationStatus.active:
        indicator = Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFF6847EE),
            shape: BoxShape.circle,
          ),
        );
        break;

      case VerificationStatus.pending:
        indicator = Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Color(0xFFE6E9F1),
            shape: BoxShape.circle,
          ),
        );
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            step.label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF171922),
            ),
          ),
        ),
        indicator,
      ],
    );
  }
}

class _LoadingBottomNavigation extends StatelessWidget {
  const _LoadingBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 83,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F1F4))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const _LoadingNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: true,
            ),
            const _LoadingNavItem(
              icon: Icons.calendar_today_outlined,
              label: 'History',
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6847EE),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x336847EE),
                          blurRadius: 20,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
            const _LoadingNavItem(icon: Icons.access_time, label: 'Insights'),
            const _LoadingNavItem(icon: Icons.person_outline, label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class _LoadingNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _LoadingNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF6847EE) : const Color(0xFFACAEB7);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
