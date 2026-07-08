import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:christian_dating_app/core/theme/app_typography.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:christian_dating_app/core/navigation/app_router.dart';
import 'package:christian_dating_app/features/settings/data/push_notification_service.dart';
import 'package:christian_dating_app/core/widgets/app_icon.dart';
import 'package:flutter/services.dart';

/// Light status bar + transparent system nav (fill painted in [MaterialApp.builder]).
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: SystemUiOverlay.values,
  );
  SystemChrome.setSystemUIOverlayStyle(kAppSystemUiOverlayStyle);

  await Firebase.initializeApp();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _pushInitialized = false;

  @override
  void initState() {
    super.initState();
    systemNavigationBarBackground.addListener(_onSystemNavigationBarChanged);
    systemNavigationBarOverlayStyle.addListener(_onSystemNavigationBarChanged);
  }

  @override
  void dispose() {
    systemNavigationBarBackground.removeListener(_onSystemNavigationBarChanged);
    systemNavigationBarOverlayStyle.removeListener(_onSystemNavigationBarChanged);
    super.dispose();
  }

  void _onSystemNavigationBarChanged() {
    if (mounted) setState(() {});
  }

  void _ensurePushInitialized() {
    if (_pushInitialized) return;
    _pushInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(pushNotificationServiceProvider).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    _ensurePushInitialized();
    final router = ref.watch(goRouterProvider);
    final navBarColor = systemNavigationBarBackground.value;
    final overlayStyle = systemNavigationBarOverlayStyle.value;
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kBrandAccent,
        brightness: Brightness.light,
      ).copyWith(
        primary: kBrandAccent,
        surface: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: Colors.white,
        surfaceContainer: Colors.white,
        surfaceContainerHigh: Colors.white,
        surfaceContainerHighest: Colors.white,
      ),
    );

    return MaterialApp.router(
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: AppTypography.manropeTextTheme(base.textTheme),
        primaryTextTheme: AppTypography.manropeTextTheme(base.primaryTextTheme),
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          titleTextStyle: AppTypography.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
          backgroundColor: Colors.white,
          selectedItemColor: kBottomNavActiveColor,
          unselectedItemColor: kBottomNavInactiveColor,
          elevation: 8,
          selectedLabelStyle: AppTypography.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
          unselectedLabelStyle: AppTypography.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w400,
          ),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: kBrandAccent,
          linearTrackColor: Color(0xFFE8E8EA),
        ),
        inputDecorationTheme: AppTypography.inputDecorationTheme(),
      ),
      builder: (context, child) {
        final systemNavInset = MediaQuery.viewPaddingOf(context).bottom;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlayStyle,
          child: DefaultTextStyle(
            style: AppTypography.manrope(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                child ?? const SizedBox.shrink(),
                if (systemNavInset > 0)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: systemNavInset,
                    child: IgnorePointer(
                      child: ColoredBox(color: navBarColor),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
