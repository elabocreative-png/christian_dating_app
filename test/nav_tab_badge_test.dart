import 'package:flutter_test/flutter_test.dart';

import 'package:christian_dating_app/core/navigation/nav_tab_badge.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('NavTabBadge hides badge when count is zero', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NavTabBadge(
            count: 0,
            child: Icon(Icons.favorite),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text('99+'), findsNothing);
  });

  testWidgets('NavTabBadge shows capped count label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NavTabBadge(
            count: 120,
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('99+'), findsOneWidget);
  });
}
