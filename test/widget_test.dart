import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dhwani/core/widgets/brand_mark.dart';

void main() {
  testWidgets('Dhwani brand mark has accessible semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BrandMark(size: 48))),
    );

    expect(find.bySemanticsLabel('Dhwani'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
