import 'package:flutter/material.dart';

import '../database/verification_model.dart';

final RouteObserver<ModalRoute<dynamic>> appRouteObserver =
    RouteObserver<ModalRoute<dynamic>>();

class SharedBottomNavigationBar extends StatelessWidget {
  final bool showPlus;
  final bool homeActive;
  final VoidCallback onHome;
  final VoidCallback onHistory;
  final VoidCallback? onPlus;

  const SharedBottomNavigationBar({
    super.key,
    required this.onHome,
    required this.onHistory,
    this.showPlus = true,
    this.homeActive = true,
    this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF8F9FB);
    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        border: Border(top: BorderSide(color: Color(0xFFEBECF0))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                active: homeActive,
                onTap: onHome,
              ),
            ),
            if (showPlus)
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Transform.translate(
                    offset: const Offset(0, -20),
                    child: GestureDetector(
                      onTap: onPlus ?? () {},
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6133F5),
                          shape: BoxShape.circle,
                          border: Border.all(color: background, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x30000000),
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _NavItem(
                icon: Icons.history,
                label: 'History',
                onTap: onHistory,
              ),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF6133F5) : const Color(0xFF7C8295);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class VerificationHistoryCard extends StatefulWidget {
  final Verification verification;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool showMetadata;

  const VerificationHistoryCard({
    super.key,
    required this.verification,
    required this.onTap,
    this.trailing,
    this.showMetadata = false,
  });

  @override
  State<VerificationHistoryCard> createState() =>
      _VerificationHistoryCardState();
}

class _VerificationHistoryCardState extends State<VerificationHistoryCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final verdict = widget.verification.verdict.toUpperCase();
    final color = switch (verdict) {
      'REAL' => const Color(0xFF18A270),
      'FAKE' => const Color(0xFFFA3C37),
      _ => const Color(0xFFF59E0B),
    };
    final icon = switch (verdict) {
      'REAL' => Icons.verified,
      'FAKE' => Icons.cancel,
      _ => Icons.help,
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.02 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _hovering
                    ? Colors.black.withValues(alpha: 0.14)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: _hovering ? 14 : 6,
                offset: Offset(0, _hovering ? 5 : 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: widget.onTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 26),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.verification.claim,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF161C26),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            verdict,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                          if (widget.showMetadata) ...[
                            const SizedBox(height: 3),
                            Text(
                              '${(widget.verification.confidence * 100).round()}% · ${widget.verification.createdAt.toLocal()}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF7C8295),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      const SizedBox(width: 8),
                      widget.trailing!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
