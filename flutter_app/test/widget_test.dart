import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('TruWave opens on onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const TruWaveApp());

    expect(find.text('TruWave'), findsOneWidget);
    expect(find.text('Know before you share.'), findsOneWidget);
  });
}
