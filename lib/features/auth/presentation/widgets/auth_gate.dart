import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petpal/core/providers/firebase_providers.dart';
import 'package:petpal/features/auth/domain/enums/user_role.dart';
import 'package:petpal/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:petpal/features/home/presentation/screens/user_home_screen.dart';
import 'package:petpal/features/home/presentation/screens/service_provider_home_screen.dart';
import 'package:petpal/features/profile/presentation/providers/profile_provider.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  static const _loading = Scaffold(
    body: Center(child: CircularProgressIndicator()),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateChangesProvider);

    ref.listen<AsyncValue>(authStateChangesProvider, (previous, next) {
      final uid = next.valueOrNull?.uid;
      final prevUid = previous?.valueOrNull?.uid;
      final notifService = ref.read(notificationServiceProvider);
      if (uid != null && uid != prevUid) {
        notifService.registerToken(uid);
      } else if (uid == null && prevUid != null) {
        notifService.deregisterToken(prevUid);
      }
    });

    return authAsync.when(
      loading: () => _loading,
      error: (_, __) => _loading,
      data: (user) {
        if (user == null) return const OnboardingScreen();

        final profileAsync = ref.watch(currentUserProfileProvider);
        return profileAsync.when(
          loading: () => _loading,
          error: (_, __) => Scaffold(
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
                        ref.invalidate(currentUserProfileProvider),
                    child: const Text('נסה שוב'),
                  ),
                ],
              ),
            ),
          ),
          data: (profile) {
            if (profile?.role == UserRole.serviceProvider) {
              return const ServiceProviderHomeScreen();
            }
            return const UserHomeScreen();
          },
        );
      },
    );
  }
}
