import 'package:flutter/material.dart';

class ImageScanScreen extends StatelessWidget {
  const ImageScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: const Text('Image verification'),
        backgroundColor: const Color(0xFFF9FAFC),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Coming soon (future scope)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
