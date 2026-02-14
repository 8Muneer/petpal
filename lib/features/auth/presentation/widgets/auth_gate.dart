import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:petpal/features/home/presentation/screens/user_home_screen.dart';
import 'package:petpal/features/home/presentation/screens/service_provider_home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<String?> _fetchUserRole(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
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

        // Logged in -> route by role (Firestore)
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

              // Default: PetOwner
              return const UserHomeScreen();
            },
          );
        }

        // Not logged in -> Onboarding
        return const OnboardingScreen();
      },
    );
  }
}
