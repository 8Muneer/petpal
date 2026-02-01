import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/firebase_options.dart';

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

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  Future<String?> _fetchUserRole(String uid) async {
    // Expected structure:
    // users/{uid} -> { role: 'petOwner' | 'serviceProvider' }
    // (We also tolerate: userType)
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;

    final role = (data['role'] ?? data['userType'])?.toString().trim();
    if (role == null || role.isEmpty) return null;
    return role;
  }

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

        // ✅ Logged in → route by role (Firestore)
        if (user != null) {
          return FutureBuilder<String?>(
            future: _fetchUserRole(user.uid),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = (roleSnap.data ?? '').toLowerCase();

              // Accept a few common spellings
              if (role == 'serviceprovider' ||
                  role == 'service_provider' ||
                  role == 'provider') {
                return const ServiceProviderHomeScreen();
              }

              // Default: PetOwner (your current "UserHomeScreen")
              return const UserHomeScreen();
            },
          );
        }

        // ✅ Not logged in → Onboarding
        return const OnboardingScreen();
      },
    );
  }
}
