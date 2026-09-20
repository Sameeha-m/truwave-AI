import 'package:flutter/material.dart';
import 'verification_loading_screen.dart';

class VerifyNewsScreen extends StatefulWidget {
  const VerifyNewsScreen({super.key});

  @override
  State<VerifyNewsScreen> createState() => _VerifyNewsScreenState();
}

class _VerifyNewsScreenState extends State<VerifyNewsScreen> {
  final TextEditingController _textController = TextEditingController();

  bool _pasteTextSelected = true;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFD),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 40, 16, 110),
                child: Column(
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 22,
                            color: Color(0xFF181A20),
                          ),
                        ),
                        const Text(
                          'Verify News',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF181A20),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.info_outline,
                            size: 24,
                            color: Color(0xFFADB3BE),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Tab bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _pasteTextSelected = true;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Paste Text',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: _pasteTextSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: _pasteTextSelected
                                        ? const Color(0xFF5D35EB)
                                        : const Color(0xFF8D96A7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _pasteTextSelected = false;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Text(
                                  'Enter Link',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: !_pasteTextSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: !_pasteTextSelected
                                        ? const Color(0xFF5D35EB)
                                        : const Color(0xFF8D96A7),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Purple tab indicator
                    Align(
                      alignment: _pasteTextSelected
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        width: MediaQuery.of(context).size.width / 2 - 16,
                        height: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: const Color(0xFF5D35EB),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Text input
                    Container(
                      width: double.infinity,
                      height: 140,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              maxLength: 5000,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                counterText: '',
                                hintText: _pasteTextSelected
                                    ? 'Paste your news text here...'
                                    : 'Enter the news link here...',
                                hintStyle: const TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF8D96A7),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                color: Color(0xFF8D96A7),
                              ),
                              onChanged: (_) {
                                setState(() {});
                              },
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_textController.text.length}/5000',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF8D96A7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Verify button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _textController.text.trim().isEmpty
                          ? null
                          : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VerificationLoadingScreen(
                                 claim: _textController.text.trim(),
                                ),
                              )
                            );
                   },
                        icon: const Icon(
                          Icons.auto_awesome,
                          size: 20,
                          color: Color(0xFFFFD600),
                        ),
                        label: const Text(
                          'Verify Now',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D35EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tips
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tips for better results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF181A20),
                            ),
                          ),
                          SizedBox(height: 8),
                          _TipRow(text: 'Include full text or headline'),
                          _TipRow(text: 'Add more context if possible'),
                          _TipRow(text: 'Avoid attachments or links'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom navigation
            _VerifyNewsBottomNav(),
          ],
        ),
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final String text;

  const _TipRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check,
            size: 16,
            color: Color(0xFF757B8A),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF757B8A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifyNewsBottomNav extends StatelessWidget {
  const _VerifyNewsBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFD),
        border: Border(
          top: BorderSide(
            color: Color(0xFFE9EAF0),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _BottomNavItem(
              icon: Icons.fact_check_outlined,
              label: 'Home',
              active: true,
            ),
            _BottomNavItem(
              icon: Icons.calendar_month_outlined,
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
                      color: const Color(0xFF5D35EB),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFF9FAFD),
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
            _BottomNavItem(
              icon: Icons.bolt_outlined,
              label: 'Insights',
            ),
            _BottomNavItem(
              icon: Icons.person_outline,
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? const Color(0xFF5D35EB)
        : const Color(0xFF8D96A7);

    return Expanded(
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
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}