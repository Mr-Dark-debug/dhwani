import 'package:dhwani/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('custom station can be created and reopened', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboardingComplete', true);
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));

    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Add custom station'));
    await tester.pumpAndSettle();

    expect(find.text('Add Station'), findsOneWidget);
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Dadaji Radio');
    await tester.enterText(fields.at(1), 'India');
    await tester.enterText(fields.at(2), 'Bihar');
    await tester.enterText(fields.at(3), 'Darbhanga');
    await tester.enterText(fields.at(4), 'Maithili, Hindi');
    await tester.tap(find.text('AM'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(5), '1296');
    await tester.drag(find.byType(ListView), const Offset(0, -900));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save station'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Dadaji Radio'), findsOneWidget);

    await tester.tap(find.text('Discover').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Saved').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
    expect(find.text('Dadaji Radio'), findsOneWidget);
  });
}
