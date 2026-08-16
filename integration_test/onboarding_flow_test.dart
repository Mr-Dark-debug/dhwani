import 'package:dhwani/main.dart' as app;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('country to Darbhanga player flow', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    if (find.text('Choose country').evaluate().isNotEmpty) {
      await tester.tap(find.text('Choose country'));
      await tester.pumpAndSettle(const Duration(seconds: 3));
    }
    expect(find.text('Choose Country'), findsOneWidget);
    expect(find.text('India'), findsOneWidget);
    await tester.tap(find.text('India'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Choose State'), findsOneWidget);
    await tester.tap(find.text('Bihar'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.text('Choose City / Region'), findsOneWidget);
    await tester.tap(find.text('Darbhanga'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Akashvani Darbhanga'), findsOneWidget);
    await tester.tap(find.text('Akashvani Darbhanga'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('1296'), findsOneWidget);
    expect(find.text('Play live'), findsOneWidget);
  });
}
