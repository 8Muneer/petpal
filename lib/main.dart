import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/firebase_options.dart';

// ✅ screens
import 'package:petpal/features/auth/presentation/onboarding_screen.dart';
import 'package:petpal/features/auth/presentation/login_screen.dart';
import 'package:petpal/features/auth/presentation/signup_screen.dart';
import 'package:petpal/features/auth/presentation/guest_home_screen.dart';
import 'package:petpal/features/auth/presentation/user_home_screen.dart';
import 'package:petpal/features/auth/presentation/profile_screen.dart';

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

      // ✅ Auth-aware start screen
      home: const _AuthGate(),

      // ✅ Named routes (NO "/" HERE)
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/login': (_) => const LoginScreen(),
        '/signup': (_) => const SignupScreen(),
        '/guest': (_) => const GuestHomeScreen(),
        '/userHome': (_) => const UserHomeScreen(),
        '/profile': (_) => const ProfileScreen(),
      },

      // ✅ fallback if any route missing
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While FirebaseAuth is initializing
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // ✅ Logged in → UserHome
        if (user != null) {
          return const UserHomeScreen();
        }

        // ✅ Not logged in → Onboarding
        return const OnboardingScreen();
      },
    );
  }
}
