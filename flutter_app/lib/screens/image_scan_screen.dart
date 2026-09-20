import 'package:flutter/material.dart';

class ImageScanScreen extends StatelessWidget {
  const ImageScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 24,
                              color: Color(0xFF23252C),
                            ),
                          ),
                          const Text(
                            'Image Scan',
                            style: TextStyle(
                              fontSize: 22,
                              height: 28 / 22,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF23252C),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {},
                            icon: const Icon(
                              Icons.history,
                              size: 26,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Upload area
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 40,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4EDFF),
                          border: Border.all(
                            color: const Color(0xFF8854FF),
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const _UploadIllustration(),
                            const SizedBox(height: 20),
                            const Text(
                              'Tap to upload or\ndrag and drop image',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                height: 24 / 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF23252C),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Supports JPG, PNG, WebP\nMax size: 10MB',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 20 / 16,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Paste options
                    const SizedBox(height: 36),

                    const Text(
                      'Or paste image from',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 28),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ImageSourceButton(
                          icon: const _GalleryIcon(),
                          label: 'Gallery',
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _ImageSourceButton(
                          icon: const _CameraIcon(),
                          label: 'Camera',
                          onTap: () {},
                        ),
                        const SizedBox(width: 20),
                        _ImageSourceButton(
                          icon: const _ClipboardIcon(),
                          label: 'Clipboard',
                          onTap: () {},
                        ),
                      ],
                    ),

                    // Explanation card
                    const SizedBox(height: 36),

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'We’ll check if this image is\nAI-generated or not.',
                        style: TextStyle(
                          fontSize: 20,
                          height: 24 / 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF23252C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const _ImageScanBottomNav(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Image source buttons
// -----------------------------------------------------------------------------

class _ImageSourceButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 28,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            icon,
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Upload illustration
// -----------------------------------------------------------------------------

class _UploadIllustration extends StatelessWidget {
  const _UploadIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 48,
      child: CustomPaint(
        painter: _UploadIllustrationPainter(),
      ),
    );
  }
}

class _UploadIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shadowPaint = Paint()
      ..color = const Color(0xFFE0E7FF)
      ..style = PaintingStyle.fill;

    final bodyPaint = Paint()
      ..color = const Color(0xFFF3F4F6)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      const Rect.fromLTWH(20, 36, 32, 10),
      shadowPaint,
    );

    final path = Path()
      ..moveTo(52.5, 24.5)
      ..cubicTo(
        51.66,
        16.17,
        41.06,
        10.11,
        36.25,
        10,
      )
      ..cubicTo(
        33.01,
        9.93,
        27.21,
        12.35,
        24.72,
        16.56,
      )
      ..cubicTo(
        21.87,
        21.35,
        22.89,
        25.65,
        22.89,
        25.65,
      )
      ..cubicTo(
        20.05,
        28.62,
        22.17,
        35.11,
        29.15,
        33.48,
      )
      ..cubicTo(
        33.4,
        35.95,
        38.18,
        37.96,
        46.79,
        32.98,
      )
      ..cubicTo(
        54.2,
        37.24,
        58.76,
        32.86,
        56.44,
        28.3,
      )
      ..cubicTo(
        54.13,
        23.75,
        52.5,
        24.5,
        52.5,
        24.5,
      )
      ..close();

    canvas.drawPath(path, bodyPaint);

    canvas.drawOval(
      const Rect.fromLTWH(21, 27, 7, 5),
      shadowPaint,
    );

    canvas.drawOval(
      const Rect.fromLTWH(43, 25, 7, 5),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// -----------------------------------------------------------------------------
// Source icons
// -----------------------------------------------------------------------------

class _GalleryIcon extends StatelessWidget {
  const _GalleryIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.broken_image_outlined,
      size: 32,
      color: Color(0xFF8854FF),
    );
  }
}

class _CameraIcon extends StatelessWidget {
  const _CameraIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.camera_alt_outlined,
      size: 32,
      color: Color(0xFF8854FF),
    );
  }
}

class _ClipboardIcon extends StatelessWidget {
  const _ClipboardIcon();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.content_paste_outlined,
      size: 32,
      color: Color(0xFF8854FF),
    );
  }
}

// -----------------------------------------------------------------------------
// Bottom navigation
// -----------------------------------------------------------------------------

class _ImageScanBottomNav extends StatelessWidget {
  const _ImageScanBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFC),
        border: Border(
          top: BorderSide(
            color: Color(0xFFEAECF0),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const _ImageNavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              active: true,
            ),
            const _ImageNavItem(
              icon: Icons.history,
              label: 'History',
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6236FF),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF9FAFC),
                        width: 4,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A6236FF),
                          blurRadius: 16,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const _ImageNavItem(
              icon: Icons.settings_outlined,
              label: 'Insights',
            ),
            const _ImageNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _ImageNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF6236FF)
        : const Color(0xFF6B7280);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 26,
            color: color,
          ),
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