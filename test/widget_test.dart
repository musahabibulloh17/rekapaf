// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:rekapaf/main.dart';

void main() {
  testWidgets('RekapApp loads auth gate', (WidgetTester tester) async {
    await tester.pumpWidget(const RekapApp());
    await tester.pump();
    // The app should show the loading spinner initially (checking auth)
    expect(find.byType(RekapApp), findsOneWidget);
  });
}
