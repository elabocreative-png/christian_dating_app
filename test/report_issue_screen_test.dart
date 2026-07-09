import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/settings/data/issue_report_repository.dart';
import 'package:christian_dating_app/features/settings/presentation/report_issue_screen.dart';

class MockIssueReportRepository extends Mock implements IssueReportRepository {}

void main() {
  late MockIssueReportRepository mockRepo;

  setUp(() {
    mockRepo = MockIssueReportRepository();
  });

  Future<void> pumpReportIssueScreen(
    WidgetTester tester, {
    String? uid = 'user-1',
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          issueReportRepositoryProvider.overrideWithValue(mockRepo),
          if (uid != null)
            currentUserIdProvider.overrideWithValue(uid)
          else
            currentUserIdProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          home: const ReportIssueScreen(),
        ),
      ),
    );
  }

  group('ReportIssueScreen', () {
    testWidgets('renders form with disabled submit until description entered',
        (tester) async {
      await pumpReportIssueScreen(tester);

      expect(find.text('Report'), findsWidgets);
      expect(find.text('Type your problem'), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField), 'App froze on chat');
      await tester.pump();

      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNotNull,
      );
    });

    testWidgets('shows snackbar when signed out', (tester) async {
      await pumpReportIssueScreen(tester, uid: null);
      await tester.enterText(find.byType(TextField), 'Something broke');
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Report'));
      await tester.pump();

      expect(find.text('Please sign in to send a report'), findsOneWidget);
      verifyNever(
        () => mockRepo.submit(
          uid: any(named: 'uid'),
          description: any(named: 'description'),
          image: any(named: 'image'),
        ),
      );
    });

    testWidgets('submits report when description is provided', (tester) async {
      when(
        () => mockRepo.submit(
          uid: any(named: 'uid'),
          description: any(named: 'description'),
          image: any(named: 'image'),
        ),
      ).thenAnswer((_) async => true);

      final router = GoRouter(
        initialLocation: '/report',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Home'))),
            routes: [
              GoRoute(
                path: 'report',
                builder: (context, state) => const ReportIssueScreen(),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            issueReportRepositoryProvider.overrideWithValue(mockRepo),
            currentUserIdProvider.overrideWithValue('user-1'),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '  Crash on swipe  ');
      await tester.pump();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Report'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepo.submit(
          uid: 'user-1',
          description: 'Crash on swipe',
          image: null,
        ),
      ).called(1);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Thanks — your report was sent'), findsOneWidget);
    });
  });
}
