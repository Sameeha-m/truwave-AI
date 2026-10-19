import 'package:flutter/material.dart';
import '../widgets/shared_history_widgets.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'verification_loading_screen.dart';

class VerifyNewsScreen extends StatefulWidget {
  const VerifyNewsScreen({super.key});

  @override
  State<VerifyNewsScreen> createState() => _VerifyNewsScreenState();
}

class _VerifyNewsScreenState extends State<VerifyNewsScreen> {
  final TextEditingController _textController = TextEditingController();

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

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: const Text(
                        'Paste Text',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5D35EB),
                        ),
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
                                hintText: 'Paste your news claim here...',
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
                                    builder: (context) =>
                                        VerificationLoadingScreen(
                                          claim: _textController.text.trim(),
                                        ),
                                  ),
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
            SharedBottomNavigationBar(
              showPlus: false,
              homeActive: false,
              onHome: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement<void, void>(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
                  );
                }
              },
              onHistory: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
              ),
            ),
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
          const Icon(Icons.check, size: 16, color: Color(0xFF757B8A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16, color: Color(0xFF757B8A)),
            ),
          ),
        ],
      ),
    );
  }
}
