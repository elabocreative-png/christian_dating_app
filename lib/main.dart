import 'package:flutter/material.dart';
import 'app_typography.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:christian_dating_app/features/auth/data/auth_errors.dart';
import 'package:christian_dating_app/features/auth/data/auth_service.dart';
import 'app_navigator.dart';
import 'package:christian_dating_app/features/auth/domain/pending_signup.dart';
import 'package:christian_dating_app/features/onboarding/presentation/profile_setup_screen.dart';
import 'main_navigation.dart';
import 'push_notification_service.dart';
import 'widgets/app_icon.dart';
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
  await PushNotificationService.initialize(
    navigatorKey: rootNavigatorKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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

  @override
  Widget build(BuildContext context) {
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

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      navigatorObservers: [matchPopupNavigatorObserver],
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
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    PendingSignup.instance.addListener(_onPendingSignupChanged);
  }

  @override
  void dispose() {
    PendingSignup.instance.removeListener(_onPendingSignupChanged);
    super.dispose();
  }

  void _onPendingSignupChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (PendingSignup.instance.isActive) {
      return const ProfileSetupScreen();
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // 🔄 Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        // ✅ Logged in → LIVE CHECK PROFILE COMPLETION
        final uid = snapshot.data!.uid;
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.connectionState == ConnectionState.waiting ||
                !profileSnapshot.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data =
                profileSnapshot.data!.data() as Map<String, dynamic>?;
            final isComplete = data?['profileComplete'] ?? false;

            if (!isComplete) {
              return const ProfileSetupScreen();
            }

            return MainNavigation(key: mainNavigationKey);
          },
        );
      },
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const Color _accent = kBrandAccent;

  final AuthService _auth = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLogin = true;
  bool _submitting = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password')),
      );
      return;
    }

    if (!isLogin) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept the Terms and Privacy Policy')),
        );
        return;
      }
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password must be at least 6 characters')),
        );
        return;
      }
      if (password != confirmPasswordController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    try {
      if (isLogin) {
        PendingSignup.instance.clear();
        await _auth.login(email, password);
      } else {
        PendingSignup.instance.start(email, password);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(messageForAuthException(e))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Text(
                'ChristMeets',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Sign in to continue'
                    : 'Create your account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 36),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                style: AppTypography.authFieldInput(),
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: AppTypography.authFieldInput(),
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              if (!isLogin) ...[
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: AppTypography.authFieldInput(),
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'I agree to the Terms of Service and Privacy Policy',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _submitting ? null : submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isLogin ? 'Sign in' : 'Create account',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              TextButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() {
                          isLogin = !isLogin;
                          confirmPasswordController.clear();
                        }),
                child: Text(
                  isLogin
                      ? 'Create an account'
                      : 'Already have an account? Sign in',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}