import 'package:dhwani/main.dart' as app;
import 'package:flutter/material.dart';
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

    expect(find.text('Akashvani Darbhanga'), findsWidgets);
    await tester.tap(find.text('Akashvani Darbhanga').first);
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('1296'), findsOneWidget);
    expect(find.text('Play live'), findsOneWidget);

    await tester.tap(find.byTooltip('Filter by source / band'));
    await tester.pumpAndSettle();
    expect(find.text('All Bands'), findsOneWidget);
    expect(find.text('AM Radio'), findsOneWidget);
    expect(find.text('FM Radio'), findsOneWidget);
    expect(find.text('Internet (NET)'), findsOneWidget);
    await tester.tap(find.text('AM Radio'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Save favourite'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('nav-saved')));
    await tester.pumpAndSettle();
    expect(find.text('Akashvani Darbhanga'), findsWidgets);

    await tester.tap(find.byKey(const Key('nav-discover')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Maithili');
    await tester.pump(const Duration(milliseconds: 650));
    expect(find.text('Akashvani Darbhanga'), findsOneWidget);
    await tester.tap(find.text('Akashvani Darbhanga'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('More actions'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Station info'));
    await tester.pumpAndSettle();
    final stationInfoList = find.byType(ListView).last;
    await tester.drag(stationInfoList, const Offset(0, -480));
    await tester.pumpAndSettle();
    expect(find.text('Current URL'), findsOneWidget);
    await tester.drag(stationInfoList, const Offset(0, -360));
    await tester.pumpAndSettle();
    expect(find.text('Retry station'), findsOneWidget);
  });
}
