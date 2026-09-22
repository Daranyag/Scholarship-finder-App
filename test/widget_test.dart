import 'package:flutter_test/flutter_test.dart';
import 'package:scholarship/main.dart';

void main() {
  testWidgets('Foundation screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle(); // Wait for auth provider to settle
    expect(find.text('Tamil Nadu Scholarship Finder'), findsWidgets);
    expect(find.text('Find scholarships available for you'), findsOneWidget);
  });
}
