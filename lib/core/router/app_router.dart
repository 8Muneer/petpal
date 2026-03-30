import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petpal/core/constants/app_constants.dart';
import 'package:petpal/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:petpal/features/auth/presentation/screens/login_screen.dart';
import 'package:petpal/features/auth/presentation/screens/signup_screen.dart';
import 'package:petpal/features/auth/presentation/widgets/auth_gate.dart';
import 'package:petpal/features/home/presentation/screens/guest_home_screen.dart';
import 'package:petpal/features/home/presentation/screens/user_home_screen.dart';
import 'package:petpal/features/home/presentation/screens/service_provider_home_screen.dart';
import 'package:petpal/features/profile/presentation/screens/profile_screen.dart';
import 'package:petpal/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:petpal/features/profile/presentation/screens/security_screen.dart';
import 'package:petpal/features/profile/presentation/screens/privacy_screen.dart';
import 'package:petpal/features/feed/presentation/screens/feed_screen.dart';
import 'package:petpal/features/feed/presentation/screens/create_post_screen.dart';
import 'package:petpal/features/feed/presentation/screens/post_detail_screen.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_request.dart';
import 'package:petpal/features/sitting/presentation/screens/create_sitting_request_screen.dart';
import 'package:petpal/features/sitting/presentation/screens/sitting_request_detail_screen.dart';
import 'package:petpal/features/walks/domain/entities/walk_request.dart';
import 'package:petpal/features/walks/domain/entities/walk_service.dart';
import 'package:petpal/features/walks/presentation/screens/create_walk_request_screen.dart';
import 'package:petpal/features/walks/presentation/screens/walk_request_detail_screen.dart';
import 'package:petpal/features/walks/presentation/screens/create_walk_service_screen.dart';
import 'package:petpal/features/sitting/domain/entities/sitting_service.dart';
import 'package:petpal/features/sitting/presentation/screens/create_sitting_service_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthGate(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/guest',
        builder: (context, state) => const GuestHomeScreen(),
      ),
      GoRoute(
        path: '/userHome',
        builder: (context, state) => const UserHomeScreen(),
      ),
      GoRoute(
        path: '/serviceProviderHome',
        builder: (context, state) => const ServiceProviderHomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/security',
        builder: (context, state) => const SecurityScreen(),
      ),
      GoRoute(
        path: '/profile/privacy',
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: '/feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/feed/create',
        builder: (context, state) => const CreatePostScreen(),
      ),
      GoRoute(
        path: '/feed/:postId',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          return PostDetailScreen(postId: postId);
        },
      ),
      GoRoute(
        path: '/walks/create',
        builder: (context, state) => const CreateWalkRequestScreen(),
      ),
      GoRoute(
        path: '/walks/edit',
        builder: (context, state) => CreateWalkRequestScreen(
          initialRequest: state.extra as WalkRequest,
        ),
      ),
      GoRoute(
        path: '/walks/detail',
        builder: (context, state) => WalkRequestDetailScreen(
          request: state.extra as WalkRequest,
        ),
      ),
      GoRoute(
        path: '/walks/service/create',
        builder: (context, state) => CreateWalkServiceScreen(
          service: state.extra as WalkService?,
        ),
      ),
      GoRoute(
        path: '/sitting/create',
        builder: (context, state) => const CreateSittingRequestScreen(),
      ),
      GoRoute(
        path: '/sitting/edit',
        builder: (context, state) => CreateSittingRequestScreen(
          initialRequest: state.extra as SittingRequest,
        ),
      ),
      GoRoute(
        path: '/sitting/detail',
        builder: (context, state) => SittingRequestDetailScreen(
          request: state.extra as SittingRequest,
        ),
      ),
      GoRoute(
        path: '/sitting/service/create',
        builder: (context, state) => CreateSittingServiceScreen(
          service: state.extra as SittingService?,
        ),
      ),
    ],
    errorBuilder: (context, state) => const OnboardingScreen(),
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;

      // Public routes that don't need auth
      const publicRoutes = [
        '/onboarding',
        '/login',
        '/signup',
        '/guest',
        '/',
        '/feed',
      ];

      if (publicRoutes.contains(location)) return null;

      // Allow guest access to feed post details
      if (location.startsWith('/feed/') && !location.startsWith('/feed/create')) {
        return null;
      }

      // If not logged in, redirect to onboarding
      if (user == null) return '/onboarding';

      return null;
    },
  );

  /// Fetches the user role from Firestore for role-based routing.
  static Future<String?> fetchUserRole(String uid) async {
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
}
