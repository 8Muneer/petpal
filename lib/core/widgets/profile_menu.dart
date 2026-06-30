import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petpal/core/theme/app_theme.dart';
import 'package:petpal/core/widgets/luxury_hero.dart' show ProfileMenuItem;
import 'package:petpal/features/auth/domain/enums/user_role.dart';

/// Single source of truth for the profile side-menu used by the home hero and
/// the shared [AppHeaderBar]. Keeping the items and the logout flow here means
/// every tab opens an identical menu instead of a copy-pasted variant.

/// Drives the provider "My services" advertise overlay in the provider shell.
/// Lives here (rather than as screen-local state) so both the provider hero and
/// the shared header open the same overlay.
final showProviderServicesProvider = StateProvider<bool>((ref) => false);

/// Profile menu items appropriate for the given [role]. Pet owners get "My
/// pets"; service providers get "My services". Falls back to the owner menu
/// when the role is unknown (e.g. profile still loading).
///
/// [onMyServices] lets the provider shell open its in-app advertise overlay;
/// without it the "My services" item routes to the service settings screen.
List<ProfileMenuItem> profileMenuItemsForRole(
  BuildContext context,
  UserRole? role, {
  VoidCallback? onMyServices,
}) {
  return role == UserRole.serviceProvider
      ? _providerMenuItems(context, onMyServices: onMyServices)
      : buildProfileMenuItems(context);
}

/// The pet-owner profile menu.
List<ProfileMenuItem> buildProfileMenuItems(BuildContext context) {
  return [
    _profileItem(context),
    ProfileMenuItem(
      icon: Icons.pets_rounded,
      iconColor: AppColors.sapphire,
      label: 'החיות שלי',
      subtitle: 'ניהול חיות המחמד שלך',
      onTap: () => context.push('/my-pets'),
    ),
    ProfileMenuItem(
      icon: Icons.calendar_today_rounded,
      iconColor: AppColors.primary,
      label: 'הזמנות',
      subtitle: 'ההזמנות שלי',
      onTap: () => context.push('/profile/bookings'),
    ),
    ProfileMenuItem(
      icon: Icons.assignment_rounded,
      iconColor: AppColors.sapphire,
      label: 'בקשות',
      subtitle: 'בקשות הטיול והשמירה שלי',
      onTap: () => context.push('/requests'),
    ),
    _logoutItem(context),
  ];
}

/// The service-provider profile menu.
List<ProfileMenuItem> _providerMenuItems(
  BuildContext context, {
  VoidCallback? onMyServices,
}) {
  return [
    _profileItem(context),
    ProfileMenuItem(
      icon: Icons.campaign_rounded,
      iconColor: AppColors.sapphire,
      label: 'השירותים שלי',
      subtitle: 'ניהול מודעות ושירותים',
      onTap: onMyServices ?? () => context.push('/provider/services'),
    ),
    _logoutItem(context),
  ];
}

ProfileMenuItem _profileItem(BuildContext context) => ProfileMenuItem(
      icon: Icons.person_rounded,
      label: 'הפרופיל שלי',
      subtitle: 'ניהול פרטים אישיים',
      onTap: () => context.push('/profile'),
    );

ProfileMenuItem _logoutItem(BuildContext context) => ProfileMenuItem(
      icon: Icons.logout_rounded,
      iconColor: const Color(0xFFE53E3E),
      label: 'התנתקות',
      subtitle: 'יציאה מהחשבון',
      onTap: () => confirmLogout(context),
    );

/// Shows the logout confirmation dialog and signs the user out on confirm.
void confirmLogout(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text(
          'להתנתק מהחשבון?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('תוכל/י להתחבר שוב בכל זמן.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('התנתקות',
                style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    ),
  );
}

Future<void> _logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  if (!context.mounted) return;
  context.go('/');
}
