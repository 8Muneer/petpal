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
import 'package:petpal/features/pets/presentation/screens/my_pets_screen.dart';
import 'package:petpal/features/profile/presentation/screens/profile_screen.dart';
import 'package:petpal/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:petpal/features/profile/presentation/screens/security_screen.dart';
import 'package:petpal/features/profile/presentation/screens/privacy_screen.dart';
import 'package:petpal/features/feed/domain/entities/feed_post.dart';
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
import 'package:petpal/features/booking/presentation/screens/my_bookings_screen.dart';
import 'package:petpal/features/home/presentation/widgets/my_requests_tab.dart'
    show MyRequestsTab;
import 'package:petpal/features/home/presentation/widgets/provider_requests_tab.dart'
    show ProviderBookingsScreen;
import 'package:petpal/features/profile/presentation/screens/availability_screen.dart';
import 'package:petpal/features/profile/presentation/screens/service_settings_screen.dart';
import 'package:petpal/features/messaging/presentation/screens/chat_list_screen.dart';
import 'package:petpal/features/messaging/presentation/screens/chat_screen.dart';
import 'package:petpal/features/lost_and_found/domain/entities/lost_found_post.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_feed_screen.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/create_lost_found_post_screen.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_post_detail_screen.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/lost_found_browse_screen.dart';
import 'package:petpal/features/lost_and_found/presentation/screens/ai_compare_screen.dart';
import 'package:petpal/features/booking/presentation/screens/create_booking_screen.dart';
import 'package:petpal/features/booking/presentation/screens/incoming_booking_detail_screen.dart';
import 'package:petpal/features/booking/domain/entities/booking_request.dart';
import 'package:petpal/features/booking/presentation/screens/provider_profile_screen.dart';
import 'package:petpal/features/reviews/presentation/screens/leave_review_screen.dart';
import 'package:petpal/features/explore/presentation/screens/explore_screen.dart';
import 'package:petpal/features/explore/presentation/screens/poi_detail_screen.dart';
import 'package:petpal/features/admin/presentation/screens/admin_hub_screen.dart';
import 'package:petpal/features/admin/presentation/screens/sitter_verification_screen.dart';
import 'package:petpal/features/admin/presentation/screens/poi_management_screen.dart';
import 'package:petpal/features/admin/presentation/screens/moderation_queue_screen.dart';
import 'package:petpal/features/admin/presentation/screens/user_directory_screen.dart';
import 'package:petpal/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:petpal/features/notifications/presentation/widgets/notification_shell.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const NotificationShell(child: AuthGate()),
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
        path: '/feed/edit',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! FeedPost) return const OnboardingScreen();
          return CreatePostScreen(post: extra);
        },
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
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! WalkRequest) return const OnboardingScreen();
          return CreateWalkRequestScreen(initialRequest: extra);
        },
      ),
      GoRoute(
        path: '/walks/detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! WalkRequest) return const OnboardingScreen();
          return WalkRequestDetailScreen(request: extra);
        },
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
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! SittingRequest) return const OnboardingScreen();
          return CreateSittingRequestScreen(initialRequest: extra);
        },
      ),
      GoRoute(
        path: '/sitting/detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! SittingRequest) return const OnboardingScreen();
          return SittingRequestDetailScreen(request: extra);
        },
      ),
      GoRoute(
        path: '/sitting/service/create',
        builder: (context, state) => CreateSittingServiceScreen(
          service: state.extra as SittingService?,
        ),
      ),
      GoRoute(
        path: '/profile/bookings',
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: '/requests',
        builder: (context, state) => const MyRequestsTab(),
      ),
      GoRoute(
        path: '/provider/bookings',
        builder: (context, state) => const ProviderBookingsScreen(),
      ),
      GoRoute(
        path: '/provider/bookings/detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! BookingRequest) return const OnboardingScreen();
          return IncomingBookingDetailScreen(booking: extra);
        },
      ),
      GoRoute(
        path: '/provider/availability',
        builder: (context, state) => const AvailabilityScreen(),
      ),
      GoRoute(
        path: '/provider/services',
        builder: (context, state) => const ServiceSettingsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/chat/:conversationId',
        builder: (context, state) {
          final extra = state.extra;
          final otherName = extra is Map
              ? (extra['otherName'] as String? ?? '')
              : (extra as String? ?? '');
          final otherPhotoUrl =
              extra is Map ? (extra['otherPhotoUrl'] as String?) : null;
          final otherUid = extra is Map ? (extra['otherUid'] as String?) : null;
          return ChatScreen(
            conversationId: state.pathParameters['conversationId']!,
            otherName: otherName,
            otherPhotoUrl: otherPhotoUrl,
            otherUid: otherUid,
          );
        },
      ),
      GoRoute(
        path: '/lost-found',
        builder: (context, state) => const LostFoundFeedScreen(),
      ),
      GoRoute(
        path: '/lost-found/create',
        builder: (context, state) => const CreateLostFoundPostScreen(),
      ),
      GoRoute(
        path: '/lost-found/detail',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! LostFoundPost) return const OnboardingScreen();
          return LostFoundPostDetailScreen(initialPost: extra);
        },
      ),
      GoRoute(
        path: '/lost-found/browse',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! LostFoundPost) return const OnboardingScreen();
          return LostFoundBrowseScreen(anchorPost: extra);
        },
      ),
      GoRoute(
        path: '/lost-found/compare',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, LostFoundPost>) {
            return const OnboardingScreen();
          }
          final post1 = extra['post1'];
          final post2 = extra['post2'];
          if (post1 == null || post2 == null) return const OnboardingScreen();
          return AiCompareScreen(post1: post1, post2: post2);
        },
      ),
      GoRoute(
        path: '/bookings/create',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) return const OnboardingScreen();
          final providerUid = extra['providerUid'] as String?;
          final providerName = extra['providerName'] as String?;
          final serviceId = extra['serviceId'] as String?;
          final serviceType = extra['serviceType'] as String?;
          final priceText = extra['priceText'] as String?;
          if (providerUid == null ||
              providerName == null ||
              serviceId == null ||
              serviceType == null ||
              priceText == null) {
            return const OnboardingScreen();
          }
          return CreateBookingScreen(
            providerUid: providerUid,
            providerName: providerName,
            providerPhotoUrl: extra['providerPhotoUrl'] as String?,
            serviceId: serviceId,
            serviceType: serviceType,
            priceText: priceText,
            priceType: extra['priceType'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/services/provider/walk',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! WalkService) return const OnboardingScreen();
          return ProviderProfileScreen.walk(service: extra);
        },
      ),
      GoRoute(
        path: '/services/provider/sitting',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! SittingService) return const OnboardingScreen();
          return ProviderProfileScreen.sitting(service: extra);
        },
      ),
      GoRoute(
        path: '/my-pets',
        builder: (context, state) => const MyPetsScreen(),
      ),
      GoRoute(
        path: '/reviews/leave',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) return const OnboardingScreen();
          final bookingId = extra['bookingId'] as String?;
          final providerUid = extra['providerUid'] as String?;
          final providerName = extra['providerName'] as String?;
          if (bookingId == null ||
              providerUid == null ||
              providerName == null) {
            return const OnboardingScreen();
          }
          return LeaveReviewScreen(
            bookingId: bookingId,
            providerUid: providerUid,
            providerName: providerName,
            providerPhotoUrl: extra['providerPhotoUrl'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/explore/poi/:poiId',
        builder: (context, state) {
          final poiId = state.pathParameters['poiId']!;
          return POIDetailScreen(poiId: poiId);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminHubScreen(),
      ),
      GoRoute(
        path: '/admin/verification',
        builder: (context, state) => const SitterVerificationScreen(),
      ),
      GoRoute(
        path: '/admin/poi',
        builder: (context, state) => const POIManagementScreen(),
      ),
      GoRoute(
        path: '/admin/moderation',
        builder: (context, state) => const ModerationQueueScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const UserDirectoryScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
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
      if (location.startsWith('/feed/') &&
          !location.startsWith('/feed/create')) {
        return null;
      }

      // If not logged in, redirect to onboarding
      if (user == null) return '/onboarding';

      // Admin routes are also enforced server-side by isAdmin() in
      // firestore.rules for every actual write — this check is the
      // client-side defense-in-depth layer, so a non-admin can't even open
      // the admin shell via a deep link or context.go('/admin').
      if (location.startsWith('/admin')) {
        final role = await fetchUserRole(user.uid);
        if (role?.toLowerCase() != 'admin') return '/';
      }

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
