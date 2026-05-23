import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:petpal/features/home/presentation/screens/user_home_screen.dart';
import 'package:petpal/features/home/presentation/screens/service_provider_home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  int _retryCount = 0;

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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user != null) {
          return FutureBuilder<String?>(
            key: ValueKey(_retryCount),
            future: _fetchUserRole(user.uid),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (roleSnap.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded,
                            size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('לא ניתן לטעון את הפרופיל',
                            style: TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () =>
                              setState(() => _retryCount++),
                          child: const Text('נסה שוב'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final role = (roleSnap.data ?? '').toLowerCase();

              if (role == 'serviceprovider' ||
                  role == 'service_provider' ||
                  role == 'provider') {
                return const ServiceProviderHomeScreen();
              }

              return const UserHomeScreen();
            },
          );
        }

        return const OnboardingScreen();
      },
    );
  }
}
