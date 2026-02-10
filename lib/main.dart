import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/firebase_options.dart';

// ✅ providers
import 'package:petpal/features/auth/providers/auth_provider.dart';
import 'package:petpal/features/auth/domain/models/models.dart';

// ✅ screens
import 'package:petpal/features/auth/presentation/onboarding_screen.dart';
import 'package:petpal/features/auth/presentation/login_screen.dart';
import 'package:petpal/features/auth/presentation/signup_screen.dart';
import 'package:petpal/features/auth/presentation/guest_home_screen.dart';
import 'package:petpal/features/auth/presentation/user_home_screen.dart';
import 'package:petpal/features/auth/presentation/service_provider_home_screen.dart';
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
        '/serviceProviderHome': (_) => const ServiceProviderHomeScreen(),
        '/profile': (_) => const ProfileScreen(),
      },

      // ✅ fallback if any route missing
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current user stream from Riverpod
    final currentUserAsync = ref.watch(currentUserProvider);

    return currentUserAsync.when(
      // Loading state - show spinner
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      // Error state - show onboarding
      error: (error, stack) {
        debugPrint('Auth error: $error');
        return const OnboardingScreen();
      },

      // Data state - route based on user
      data: (UserModel? user) {
        // Not logged in → Onboarding
        if (user == null) {
          return const OnboardingScreen();
        }

        // Logged in → route by role
        final role = user.role.toLowerCase();

        // Accept a few common spellings for service provider
        if (role == 'serviceprovider' ||
            role == 'service_provider' ||
            role == 'provider') {
          return const ServiceProviderHomeScreen();
        }

        // Default: PetOwner
        return const UserHomeScreen();
      },
    );
  }
}
