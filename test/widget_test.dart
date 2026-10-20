import 'package:flutter_test/flutter_test.dart';
import 'package:medconnect/main.dart';

void main() {
  testWidgets('Med Connect app flow test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MedConnectApp());

    // 1. Verify Splash Screen branding
    expect(find.text('Med Connect'), findsOneWidget);
    expect(find.text('Your Health. Your Family. Your Record.'), findsOneWidget);
    expect(find.text('Presented by AIRA Innovations'), findsOneWidget);

    // 2. Wait for Splash transition (4 seconds delay in code)
    // We use pumpAndSettle with a duration to fast-forward through the delay.
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // 3. Verify Onboarding screen is reached
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('One App for Your Whole Family\'s Health'), findsOneWidget);
    
    // 4. Test "Skip" navigation to Login
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    
    expect(find.text('Welcome to\nMed Connect'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
