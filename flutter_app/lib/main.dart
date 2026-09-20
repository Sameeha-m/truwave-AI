import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const TruWaveApp());
}

class TruWaveApp extends StatelessWidget {
  const TruWaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TruWave',
      home: const TruWaveOnboarding(),
    );
  }
}