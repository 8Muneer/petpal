import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:petpal/features/home/presentation/screens/user_home_screen.dart';
import 'package:petpal/features/home/presentation/screens/service_provider_home_screen.dart';
import 'package:petpal/features/admin/presentation/screens/admin_hub_screen.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  // Cached per UID so rebuilds don't re-fire Firestore reads.
  String? _cachedUid;
  Future<String?>? _roleFuture;
  // Tracks UIDs that have already had their FCM token registered this session.
  final Set<String> _tokenRegisteredUids = {};

  // Deliberately doesn't catch here — a Firestore/network failure should
  // propagate to the FutureBuilder below and hit the `hasError` branch, not
  // be swallowed into `null` and silently fall through to the pet-owner
  // default. A user document that legitimately has no role is a different,
  // non-error case (returns null below) from a read that actually failed.
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

  Future<String?> _roleFor(String uid) {
    if (_cachedUid != uid) {
      _cachedUid = uid;
      _roleFuture = _fetchUserRole(uid);
    }
    return _roleFuture!;
  }

  @override
  Widget build(BuildContext context) {
    // Deregister FCM token on sign-out (catches all sign-out paths).
    ref.listen<AsyncValue<User?>>(authStateChangesProvider, (prev, next) {
      final prevUid = prev?.asData?.value?.uid;
      final nextUid = next.asData?.value?.uid;
      if (prevUid != null && nextUid == null) {
        // Clear the registration marker too — otherwise signing back in as
        // the same uid within this app session (this State object stays
        // alive across the sign-out/sign-in) would skip registerToken below,
        // since the uid would still be in this set from before the token was
        // deregistered. No push notifications until the next app restart.
        _tokenRegisteredUids.remove(prevUid);
        ref.read(notificationServiceProvider).deregisterToken(prevUid);
      }
    });

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
            future: _roleFor(user.uid),
            builder: (context, roleSnap) {
              if (roleSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Surface Firestore errors instead of silently defaulting to pet owner.
              if (roleSnap.hasError) {
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Unable to load profile.'),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() {
                            _cachedUid = null;
                            _roleFuture = null;
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final role = (roleSnap.data ?? '').toLowerCase();

              // Register FCM token once per UID (non-blocking).
              if (!_tokenRegisteredUids.contains(user.uid)) {
                _tokenRegisteredUids.add(user.uid);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(notificationServiceProvider).registerToken(user.uid);
                });
              }

              if (role == 'admin') return const AdminHubScreen();

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
