import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/firebase_options.dart';

// ✅ screens
import 'package:petpal/features/auth/presentation/onboarding_screen.dart';
import 'package:petpal/features/auth/presentation/login_screen.dart';
import 'package:petpal/features/auth/presentation/signup_screen.dart';
import 'package:petpal/features/auth/presentation/guest_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const ProviderScope(
      child: PetPalApp(),
    ),
  );
}

class PetPalApp extends StatelessWidget {
  const PetPalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetPal Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // ✅ Start screen
      initialRoute: '/onboarding',

      // ✅ Named routes (THIS fixes your error)
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/guest': (_) => const GuestHomeScreen(),

        // (optional) after login/signup
        '/home': (_) => const GuestHomeScreen(),
      },

      // ✅ fallback if any route missing
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }
}
