import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:christian_dating_app/features/auth/presentation/auth_providers.dart';
import 'package:christian_dating_app/features/discovery/data/discovery_repository.dart';
import 'package:christian_dating_app/features/discovery/domain/discovery_preferences.dart';
import 'package:christian_dating_app/features/discovery/domain/nearby_user.dart';
import 'package:christian_dating_app/features/discovery/presentation/discovery_deck_providers.dart';
import 'package:christian_dating_app/features/discovery/presentation/discovery_screen.dart';
import 'package:christian_dating_app/features/discovery/presentation/widgets/discovery_radar_loading.dart';
import 'package:christian_dating_app/features/discovery/presentation/widgets/user_profile_discovery_card.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

void main() {
  late MockDiscoveryRepository mockDiscovery;
  const uid = 'user-1';

  setUp(() {
    mockDiscovery = MockDiscoveryRepository();
    when(() => mockDiscovery.fetchDiscoveryMode(uid))
        .thenAnswer((_) async => kDiscoveryModeDating);
    when(() => mockDiscovery.fetchViewerProfile(uid)).thenAnswer(
      (_) async => {'discoveryHintsComplete': true, 'name': 'Alex'},
    );
  });

  Future<void> pumpDiscoveryScreen(
    WidgetTester tester, {
    required AsyncValue<List<NearbyUser>> deckState,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(uid),
          discoveryRepositoryProvider.overrideWithValue(mockDiscovery),
          discoveryDeckProvider(uid).overrideWithValue(deckState),
        ],
        child: const MaterialApp(home: DiscoveryScreen()),
      ),
    );
  }

  const sampleNearbyUser = NearbyUser(
    id: 'other-1',
    profile: {'name': 'Jordan', 'age': 28},
  );

  group('DiscoveryScreen empty state', () {
    testWidgets('shows empty deck copy and filter actions', (tester) async {
      await pumpDiscoveryScreen(tester, deckState: const AsyncData([]));
      await tester.pumpAndSettle();

      expect(find.text("You've seen everyone for now"), findsOneWidget);
      expect(find.text('Change filters'), findsOneWidget);
      expect(find.text('Review skipped profiles'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Review skipped profiles'),
            )
            .onPressed,
        isNull,
      );
    });

    testWidgets('shows radar loading while first deck fetch is pending',
        (tester) async {
      await pumpDiscoveryScreen(tester, deckState: const AsyncLoading());
      await tester.pump();

      expect(find.byType(DiscoveryRadarLoading), findsOneWidget);
      expect(find.text("You've seen everyone for now"), findsNothing);
    });

    testWidgets('shows deck exhausted copy after passing the last profile',
        (tester) async {
      await pumpDiscoveryScreen(
        tester,
        deckState: const AsyncData([sampleNearbyUser]),
      );
      await tester.pumpAndSettle();

      expect(find.byType(UserProfileDiscoveryCard), findsOneWidget);
      expect(find.textContaining('Jordan'), findsWidgets);
      expect(find.text("You've seen everyone for now"), findsNothing);

      await tester.drag(
        find.byType(UserProfileDiscoveryCard),
        const Offset(0, -1200),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final passButton = find.descendant(
        of: find.byType(UserProfileDiscoveryCard),
        matching: find.byWidgetPredicate(
          (widget) => widget is InkWell && widget.onTap != null,
        ),
      );
      await tester.tap(passButton.first);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text("You've seen everyone for now"), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, 'Review skipped profiles'),
            )
            .onPressed,
        isNotNull,
      );
    });
  });
}
